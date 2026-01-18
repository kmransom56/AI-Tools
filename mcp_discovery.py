"""
MCP (Model Context Protocol) Discovery Module
Provides dynamic discovery, registration, and invocation of MCP servers and tools.

This module acts as a client to the mcp-discovery service (https://github.com/kmransom56/mcp-discovery)
and provides fallback local discovery when the service is unavailable.
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from enum import Enum
import httpx
import asyncio
import os
import json
import logging
import yaml
from datetime import datetime, timedelta
from pathlib import Path

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/mcp", tags=["mcp"])

# MCP Discovery Service configuration
MCP_DISCOVERY_URL = os.getenv("MCP_DISCOVERY_URL", "http://localhost:5000")
MCP_DISCOVERY_TIMEOUT = float(os.getenv("MCP_DISCOVERY_TIMEOUT", "10.0"))


# =============================================================================
# Data Models (aligned with mcp-discovery service)
# =============================================================================


class ServiceStatus(str, Enum):
    """Service health status."""

    HEALTHY = "healthy"
    UNHEALTHY = "unhealthy"
    STARTING = "starting"
    STOPPED = "stopped"
    UNKNOWN = "unknown"


class MCPService(BaseModel):
    """MCP Service definition (matches mcp-discovery service model)."""

    name: str = Field(..., description="Service name")
    service_type: str = Field(
        default="unknown", description="Service type (filesystem, playwright, etc.)"
    )
    version: str = Field(default="unknown", description="Service version")
    endpoint: Optional[str] = Field(
        None, description="Service endpoint URL or socket path"
    )
    capabilities: List[str] = Field(
        default_factory=list, description="Service capabilities"
    )
    port: Optional[int] = Field(None, description="Service port number")
    container_id: Optional[str] = Field(None, description="Docker container ID")
    status: ServiceStatus = Field(
        default=ServiceStatus.UNKNOWN, description="Service health status"
    )
    labels: Dict[str, str] = Field(default_factory=dict, description="Container labels")
    discovered_at: datetime = Field(
        default_factory=datetime.utcnow, description="Discovery timestamp"
    )

    # Additional fields for local registry
    auth_type: Optional[str] = None  # bearer, api_key, none
    auth_token_env: Optional[str] = None  # Environment variable name for token
    tools: List[Dict[str, Any]] = Field(default_factory=list, description="Tool list")


class MCPServer(BaseModel):
    """Represents a registered MCP server (legacy compatibility)"""

    name: str
    url: str
    description: Optional[str] = ""
    auth_type: Optional[str] = None
    auth_token_env: Optional[str] = None
    enabled: bool = True
    last_seen: Optional[datetime] = None
    tools: List[Dict[str, Any]] = []


class MCPServerRegister(BaseModel):
    """Request model for registering an MCP server"""

    name: str
    url: str
    description: Optional[str] = ""
    auth_type: Optional[str] = None
    auth_token_env: Optional[str] = None


class MCPToolInvoke(BaseModel):
    """Request model for invoking an MCP tool"""

    server: str  # Server name
    tool: str  # Tool name
    method: Optional[str] = None  # Method name (if tool has multiple methods)
    parameters: Dict[str, Any] = Field(default_factory=dict)


class MCPDiscoverRequest(BaseModel):
    """Request model for discovering MCP servers"""

    scan_docker: bool = True
    scan_ports: List[int] = Field(default_factory=lambda: [11003, 8000, 3000, 5000])
    scan_localhost: bool = True
    use_discovery_service: bool = True  # Use mcp-discovery service if available
    sources: List[str] = Field(
        default_factory=lambda: ["docker", "env"], description="Discovery sources"
    )


class DiscoveryResult(BaseModel):
    """Discovery operation result (matches mcp-discovery service)."""

    services: List[MCPService] = Field(description="List of discovered services")
    total: int = Field(description="Total number of services")
    timestamp: datetime = Field(
        default_factory=datetime.utcnow, description="Discovery timestamp"
    )
    source: str = Field(
        default="combined",
        description="Discovery source (docker, env, cache, combined, local)",
    )


# =============================================================================
# MCP Registry (In-Memory with File Persistence)
# =============================================================================


class MCPRegistry:
    """
    Registry for MCP servers with caching and persistence.
    Stores server configurations and discovered tools.
    """

    def __init__(self, registry_file: str = None):
        self.servers: Dict[str, MCPServer] = {}
        self.tool_cache: Dict[str, List[Dict[str, Any]]] = {}
        self.cache_ttl = timedelta(minutes=5)
        self.last_cache_refresh: Dict[str, datetime] = {}

        # Determine registry file path
        if registry_file:
            self.registry_file = Path(registry_file)
        else:
            # Default to workspace directory
            workspace = Path(__file__).parent
            self.registry_file = workspace / "config" / "mcp-registry.json"

        self._load_registry()
        self._register_defaults()

    def _load_registry(self):
        """Load server registry from file"""
        if self.registry_file.exists():
            try:
                with open(self.registry_file, "r") as f:
                    data = json.load(f)
                    for name, server_data in data.get("servers", {}).items():
                        self.servers[name] = MCPServer(**server_data)
                logger.info(f"Loaded {len(self.servers)} MCP servers from registry")
            except Exception as e:
                logger.warning(f"Failed to load MCP registry: {e}")

    def _save_registry(self):
        """Persist server registry to file"""
        try:
            self.registry_file.parent.mkdir(parents=True, exist_ok=True)
            data = {
                "servers": {
                    name: server.model_dump(mode="json")
                    for name, server in self.servers.items()
                },
                "updated_at": datetime.now().isoformat(),
            }
            with open(self.registry_file, "w") as f:
                json.dump(data, f, indent=2, default=str)
            logger.info(f"Saved MCP registry to {self.registry_file}")
        except Exception as e:
            logger.error(f"Failed to save MCP registry: {e}")

    def _register_defaults(self):
        """Register default MCP servers from environment and docker-compose"""
        # GitHub MCP Server (from docker-compose)
        if "github-mcp" not in self.servers:
            self.servers["github-mcp"] = MCPServer(
                name="github-mcp",
                url="http://localhost:11003",
                description="GitHub MCP Server for repository operations",
                auth_type="bearer",
                auth_token_env="GITHUB_TOKEN",
                enabled=True,
            )

        # Load from tool_catalog.yaml if exists
        tool_catalog = Path(__file__).parent / "cagent_examples" / "tool_catalog.yaml"
        if tool_catalog.exists():
            try:
                with open(tool_catalog, "r") as f:
                    catalog = yaml.safe_load(f)
                    for tool in catalog.get("toolsets", []):
                        if tool.get("type") == "mcp" and "ref" in tool:
                            ref = tool["ref"]
                            if ref not in self.servers:
                                self.servers[ref] = MCPServer(
                                    name=ref,
                                    url=f"http://localhost:11003/tools/{ref}",
                                    description=tool.get("description", ""),
                                    enabled=False,  # Disabled until discovered
                                )
            except Exception as e:
                logger.warning(f"Failed to load tool catalog: {e}")

    def register(self, server: MCPServer) -> MCPServer:
        """Register or update an MCP server"""
        server.last_seen = datetime.now()
        self.servers[server.name] = server
        self._save_registry()
        logger.info(f"Registered MCP server: {server.name} at {server.url}")
        return server

    def unregister(self, name: str) -> bool:
        """Unregister an MCP server"""
        if name in self.servers:
            del self.servers[name]
            if name in self.tool_cache:
                del self.tool_cache[name]
            self._save_registry()
            logger.info(f"Unregistered MCP server: {name}")
            return True
        return False

    def get(self, name: str) -> Optional[MCPServer]:
        """Get a registered server by name"""
        return self.servers.get(name)

    def list_all(self) -> List[MCPServer]:
        """List all registered servers"""
        return list(self.servers.values())

    def get_tools(self, server_name: str) -> List[Dict[str, Any]]:
        """Get cached tools for a server"""
        return self.tool_cache.get(server_name, [])

    def update_tools(self, server_name: str, tools: List[Dict[str, Any]]):
        """Update tool cache for a server"""
        self.tool_cache[server_name] = tools
        self.last_cache_refresh[server_name] = datetime.now()
        if server_name in self.servers:
            self.servers[server_name].tools = tools
            self.servers[server_name].last_seen = datetime.now()

    def is_cache_valid(self, server_name: str) -> bool:
        """Check if tool cache is still valid"""
        if server_name not in self.last_cache_refresh:
            return False
        return datetime.now() - self.last_cache_refresh[server_name] < self.cache_ttl


# Global registry instance
mcp_registry = MCPRegistry()


# =============================================================================
# MCP Discovery Service Client
# =============================================================================


class MCPDiscoveryClient:
    """
    Client for the mcp-discovery service (https://github.com/kmransom56/mcp-discovery).
    Falls back to local discovery when the service is unavailable.
    """

    def __init__(self, base_url: str = None):
        self.base_url = base_url or MCP_DISCOVERY_URL
        self.timeout = MCP_DISCOVERY_TIMEOUT
        self._service_available: Optional[bool] = None
        self._last_check: Optional[datetime] = None
        self._check_interval = timedelta(seconds=30)

    async def is_available(self, force_check: bool = False) -> bool:
        """Check if the mcp-discovery service is available."""
        now = datetime.now()
        if (
            not force_check
            and self._service_available is not None
            and self._last_check
            and (now - self._last_check) < self._check_interval
        ):
            return self._service_available

        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                response = await client.get(f"{self.base_url}/health")
                self._service_available = response.status_code == 200
        except Exception:
            self._service_available = False

        self._last_check = now
        return self._service_available

    async def get_services(
        self, use_cache: bool = True, service_type: str = None, status: str = None
    ) -> DiscoveryResult:
        """
        Get discovered MCP services from the discovery service.

        Args:
            use_cache: Whether to use cached results
            service_type: Filter by service type
            status: Filter by health status

        Returns:
            DiscoveryResult with list of services
        """
        params = {"use_cache": str(use_cache).lower()}
        if service_type:
            params["service_type"] = service_type
        if status:
            params["status"] = status

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(f"{self.base_url}/services", params=params)

                if response.status_code == 200:
                    data = response.json()
                    services = [MCPService(**s) for s in data.get("services", [])]
                    return DiscoveryResult(
                        services=services,
                        total=data.get("total", len(services)),
                        source=data.get("source", "discovery-service"),
                    )
        except Exception as e:
            logger.warning(f"Failed to get services from discovery service: {e}")

        return DiscoveryResult(services=[], total=0, source="error")

    async def get_service(self, name: str) -> Optional[MCPService]:
        """Get a specific service by name."""
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(f"{self.base_url}/services/{name}")

                if response.status_code == 200:
                    return MCPService(**response.json())
        except Exception as e:
            logger.warning(f"Failed to get service {name}: {e}")

        return None

    async def refresh_services(
        self, force: bool = False, sources: List[str] = None
    ) -> DiscoveryResult:
        """Trigger service discovery refresh."""
        payload = {"force": force}
        if sources:
            payload["sources"] = sources

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.base_url}/services/refresh", json=payload
                )

                if response.status_code == 200:
                    data = response.json()
                    services = [MCPService(**s) for s in data.get("services", [])]
                    return DiscoveryResult(
                        services=services,
                        total=data.get("total", len(services)),
                        source=data.get("source", "refresh"),
                    )
        except Exception as e:
            logger.warning(f"Failed to refresh services: {e}")

        return DiscoveryResult(services=[], total=0, source="error")

    async def get_health(self) -> Dict[str, Any]:
        """Get discovery service health status."""
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                response = await client.get(f"{self.base_url}/health")

                if response.status_code == 200:
                    return response.json()
        except Exception as e:
            logger.warning(f"Failed to get health: {e}")

        return {
            "status": "unavailable",
            "services_discovered": 0,
            "docker_available": False,
            "redis_available": False,
        }

    async def get_services_by_type(self, service_type: str) -> DiscoveryResult:
        """Get services filtered by type."""
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(
                    f"{self.base_url}/services/type/{service_type}"
                )

                if response.status_code == 200:
                    data = response.json()
                    services = [MCPService(**s) for s in data.get("services", [])]
                    return DiscoveryResult(
                        services=services,
                        total=data.get("total", len(services)),
                        source=data.get("source", "filter"),
                    )
        except Exception as e:
            logger.warning(f"Failed to get services by type: {e}")

        return DiscoveryResult(services=[], total=0, source="error")


# Global discovery client instance
discovery_client = MCPDiscoveryClient()


# =============================================================================
# MCP Client Functions
# =============================================================================


async def probe_mcp_server(url: str, timeout: float = 5.0) -> Dict[str, Any]:
    """
    Probe an MCP server to check if it's alive and get basic info.
    Tries multiple common MCP endpoints.
    """
    endpoints_to_try = [
        "/health",
        "/api/health",
        "/healthz",
        "/",
        "/api/tools",
        "/tools",
    ]

    async with httpx.AsyncClient(timeout=timeout) as client:
        for endpoint in endpoints_to_try:
            try:
                response = await client.get(f"{url.rstrip('/')}{endpoint}")
                if response.status_code == 200:
                    try:
                        data = response.json()
                    except Exception:
                        data = {"raw": response.text[:500]}

                    return {
                        "alive": True,
                        "endpoint": endpoint,
                        "status_code": response.status_code,
                        "data": data,
                    }
            except Exception:
                continue

    return {"alive": False, "endpoint": None, "status_code": None, "data": None}


async def fetch_mcp_tools(
    server: MCPServer, force_refresh: bool = False
) -> List[Dict[str, Any]]:
    """
    Fetch available tools from an MCP server.
    Uses cache unless force_refresh is True.
    """
    # Check cache first
    if not force_refresh and mcp_registry.is_cache_valid(server.name):
        return mcp_registry.get_tools(server.name)

    tools = []
    headers = {}

    # Add authentication if configured
    if server.auth_type == "bearer" and server.auth_token_env:
        token = os.getenv(server.auth_token_env)
        if token:
            headers["Authorization"] = f"Bearer {token}"
    elif server.auth_type == "api_key" and server.auth_token_env:
        token = os.getenv(server.auth_token_env)
        if token:
            headers["X-API-Key"] = token

    # Try multiple tool discovery endpoints
    tool_endpoints = [
        "/api/tools",
        "/tools",
        "/api/v1/tools",
        "/mcp/tools",
        "/.well-known/mcp.json",
    ]

    async with httpx.AsyncClient(timeout=10.0) as client:
        for endpoint in tool_endpoints:
            try:
                url = f"{server.url.rstrip('/')}{endpoint}"
                response = await client.get(url, headers=headers)

                if response.status_code == 200:
                    data = response.json()

                    # Handle different response formats
                    if isinstance(data, list):
                        tools = data
                    elif isinstance(data, dict):
                        tools = data.get("tools", data.get("data", []))

                    if tools:
                        logger.info(f"Discovered {len(tools)} tools from {server.name}")
                        break

            except Exception as e:
                logger.debug(f"Failed to fetch tools from {server.url}{endpoint}: {e}")
                continue

    # Update cache
    mcp_registry.update_tools(server.name, tools)
    return tools


async def invoke_mcp_tool(
    server: MCPServer,
    tool_name: str,
    method: Optional[str],
    parameters: Dict[str, Any],
) -> Dict[str, Any]:
    """
    Invoke a tool on an MCP server.
    """
    headers = {"Content-Type": "application/json"}

    # Add authentication
    if server.auth_type == "bearer" and server.auth_token_env:
        token = os.getenv(server.auth_token_env)
        if token:
            headers["Authorization"] = f"Bearer {token}"
    elif server.auth_type == "api_key" and server.auth_token_env:
        token = os.getenv(server.auth_token_env)
        if token:
            headers["X-API-Key"] = token

    # Build request payload
    payload = {
        "tool": tool_name,
        "parameters": parameters,
    }
    if method:
        payload["method"] = method

    # Try multiple invocation endpoints
    invoke_endpoints = [
        f"/api/tools/{tool_name}/invoke",
        f"/tools/{tool_name}/invoke",
        f"/api/tools/{tool_name}",
        "/api/invoke",
        "/invoke",
    ]

    async with httpx.AsyncClient(timeout=60.0) as client:
        for endpoint in invoke_endpoints:
            try:
                url = f"{server.url.rstrip('/')}{endpoint}"
                response = await client.post(url, json=payload, headers=headers)

                if response.status_code in [200, 201]:
                    return {
                        "success": True,
                        "result": response.json(),
                        "server": server.name,
                        "tool": tool_name,
                    }
                elif response.status_code == 404:
                    continue  # Try next endpoint
                else:
                    return {
                        "success": False,
                        "error": f"HTTP {response.status_code}: {response.text[:500]}",
                        "server": server.name,
                        "tool": tool_name,
                    }

            except Exception as e:
                logger.debug(f"Failed to invoke {tool_name} via {endpoint}: {e}")
                continue

    return {
        "success": False,
        "error": f"Could not invoke tool {tool_name} on server {server.name}",
        "server": server.name,
        "tool": tool_name,
    }


# =============================================================================
# API Endpoints
# =============================================================================


@router.get("/servers")
async def list_servers(source: str = "all"):
    """
    List all MCP servers from discovery service and/or local registry.

    Args:
        source: "all" (default), "discovery" (mcp-discovery service only),
                or "local" (local registry only)

    Returns server info including enabled status and last seen time.
    """
    all_servers = []

    # Get from mcp-discovery service
    if source in ["all", "discovery"]:
        if await discovery_client.is_available():
            result = await discovery_client.get_services()
            for svc in result.services:
                all_servers.append(
                    {
                        "name": svc.name,
                        "url": svc.endpoint,
                        "service_type": svc.service_type,
                        "capabilities": svc.capabilities,
                        "status": svc.status.value,
                        "source": "mcp-discovery-service",
                    }
                )

    # Get from local registry
    if source in ["all", "local"]:
        local_servers = mcp_registry.list_all()
        for s in local_servers:
            # Avoid duplicates
            if not any(srv["name"] == s.name for srv in all_servers):
                all_servers.append(
                    {
                        **s.model_dump(mode="json"),
                        "source": "local-registry",
                    }
                )

    return {
        "servers": all_servers,
        "count": len(all_servers),
        "discovery_service_available": await discovery_client.is_available(),
    }


@router.get("/services")
async def list_services(
    service_type: str = None, status: str = None, use_cache: bool = True
):
    """
    List all discovered MCP services (proxies to mcp-discovery service).

    This endpoint provides direct access to the mcp-discovery service API.
    Falls back to local registry if service is unavailable.
    """
    if await discovery_client.is_available():
        result = await discovery_client.get_services(
            use_cache=use_cache, service_type=service_type, status=status
        )
        return {
            "services": [s.model_dump(mode="json") for s in result.services],
            "total": result.total,
            "source": result.source,
            "from_discovery_service": True,
        }
    else:
        # Fallback to local registry
        servers = mcp_registry.list_all()
        return {
            "services": [s.model_dump(mode="json") for s in servers],
            "total": len(servers),
            "source": "local-fallback",
            "from_discovery_service": False,
        }


@router.post("/servers/register")
async def register_server(request: MCPServerRegister):
    """
    Register a new MCP server or update existing one.
    """
    server = MCPServer(
        name=request.name,
        url=request.url,
        description=request.description,
        auth_type=request.auth_type,
        auth_token_env=request.auth_token_env,
        enabled=True,
    )

    # Probe server to verify it's alive
    probe_result = await probe_mcp_server(request.url)
    if not probe_result["alive"]:
        return {
            "success": False,
            "error": f"Server at {request.url} is not responding",
            "probe_result": probe_result,
        }

    registered = mcp_registry.register(server)
    return {
        "success": True,
        "server": registered.model_dump(mode="json"),
        "message": f"Server {request.name} registered successfully",
    }


@router.delete("/servers/{name}")
async def unregister_server(name: str):
    """
    Unregister an MCP server by name.
    """
    if mcp_registry.unregister(name):
        return {"success": True, "message": f"Server {name} unregistered"}
    else:
        return {"success": False, "error": f"Server {name} not found"}


@router.post("/discover")
async def discover_servers(request: MCPDiscoverRequest = None):
    """
    Discover MCP servers using the mcp-discovery service or local scanning.

    Priority:
    1. Use mcp-discovery service if available (recommended)
    2. Fall back to local Docker/port scanning

    The mcp-discovery service (https://github.com/kmransom56/mcp-discovery)
    provides more robust discovery with Redis caching and multi-source support.
    """
    if request is None:
        request = MCPDiscoverRequest()

    discovered = []
    source = "local"

    # Try mcp-discovery service first
    if request.use_discovery_service:
        if await discovery_client.is_available():
            logger.info("Using mcp-discovery service for discovery")
            result = await discovery_client.refresh_services(
                force=True, sources=request.sources
            )
            if result.total > 0:
                # Convert MCPService to discovery format
                for svc in result.services:
                    discovered.append(
                        {
                            "name": svc.name,
                            "url": svc.endpoint or f"http://localhost:{svc.port}",
                            "source": "mcp-discovery-service",
                            "service_type": svc.service_type,
                            "capabilities": svc.capabilities,
                            "status": svc.status.value,
                            "container_id": svc.container_id,
                        }
                    )
                source = result.source
                logger.info(
                    f"Discovered {len(discovered)} services via mcp-discovery service"
                )

    # Fall back to local discovery if mcp-discovery service unavailable or no results
    if not discovered:
        logger.info("Using local discovery (mcp-discovery service unavailable)")

        # Scan Docker containers
        if request.scan_docker:
            try:
                import docker

                client = docker.from_env()
                containers = client.containers.list()

                for container in containers:
                    # Look for MCP-related containers
                    name = container.name.lower()
                    labels = container.labels
                    is_mcp = any(x in name for x in ["mcp", "tool", "agent"]) or any(
                        k.startswith("mcp.") for k in labels.keys()
                    )

                    if is_mcp:
                        # Get exposed ports
                        ports = container.attrs.get("NetworkSettings", {}).get(
                            "Ports", {}
                        )
                        for port_info in ports.values():
                            if port_info:
                                host_port = port_info[0].get("HostPort")
                                if host_port:
                                    url = f"http://localhost:{host_port}"
                                    probe = await probe_mcp_server(url)
                                    if probe["alive"]:
                                        discovered.append(
                                            {
                                                "name": container.name,
                                                "url": url,
                                                "source": "docker",
                                                "service_type": labels.get(
                                                    "mcp.type", "unknown"
                                                ),
                                                "capabilities": labels.get(
                                                    "mcp.capabilities", ""
                                                ).split(","),
                                                "status": "healthy",
                                                "container_id": container.short_id,
                                                "probe": probe,
                                            }
                                        )
            except Exception as e:
                logger.warning(f"Docker discovery failed: {e}")

        # Scan localhost ports
        if request.scan_localhost:
            for port in request.scan_ports:
                url = f"http://localhost:{port}"
                probe = await probe_mcp_server(url, timeout=2.0)
                if probe["alive"]:
                    discovered.append(
                        {
                            "name": f"localhost-{port}",
                            "url": url,
                            "source": "port_scan",
                            "service_type": "unknown",
                            "capabilities": [],
                            "status": "healthy",
                            "probe": probe,
                        }
                    )
        source = "local"

    # Auto-register discovered servers in local registry
    for server_info in discovered:
        existing = mcp_registry.get(server_info["name"])
        if not existing:
            server = MCPServer(
                name=server_info["name"],
                url=server_info["url"],
                description=f"Auto-discovered from {server_info['source']}",
                enabled=True,
            )
            mcp_registry.register(server)

    return {
        "discovered": discovered,
        "count": len(discovered),
        "source": source,
        "discovery_service_available": await discovery_client.is_available(),
        "registered_total": len(mcp_registry.list_all()),
    }


@router.get("/tools")
async def list_all_tools(refresh: bool = False):
    """
    List all available tools from all enabled MCP servers.
    Set refresh=true to force cache refresh.
    """
    all_tools = []
    servers = mcp_registry.list_all()

    # Fetch tools from all enabled servers concurrently
    async def fetch_server_tools(server: MCPServer):
        if not server.enabled:
            return []
        try:
            tools = await fetch_mcp_tools(server, force_refresh=refresh)
            return [
                {
                    **tool,
                    "server": server.name,
                    "server_url": server.url,
                }
                for tool in tools
            ]
        except Exception as e:
            logger.warning(f"Failed to fetch tools from {server.name}: {e}")
            return []

    results = await asyncio.gather(
        *[fetch_server_tools(s) for s in servers], return_exceptions=True
    )

    for result in results:
        if isinstance(result, list):
            all_tools.extend(result)

    # Group by category
    categorized = {}
    for tool in all_tools:
        category = tool.get("category", "general")
        if category not in categorized:
            categorized[category] = []
        categorized[category].append(tool)

    return {
        "tools": all_tools,
        "count": len(all_tools),
        "categorized": categorized,
        "servers_queried": len([s for s in servers if s.enabled]),
    }


@router.get("/tools/{server_name}")
async def list_server_tools(server_name: str, refresh: bool = False):
    """
    List tools from a specific MCP server.
    """
    server = mcp_registry.get(server_name)
    if not server:
        raise HTTPException(status_code=404, detail=f"Server {server_name} not found")

    tools = await fetch_mcp_tools(server, force_refresh=refresh)
    return {
        "server": server_name,
        "url": server.url,
        "tools": tools,
        "count": len(tools),
    }


@router.post("/invoke")
async def invoke_tool(request: MCPToolInvoke):
    """
    Invoke a tool on an MCP server.
    """
    server = mcp_registry.get(request.server)
    if not server:
        return {
            "success": False,
            "error": f"Server {request.server} not found",
        }

    if not server.enabled:
        return {
            "success": False,
            "error": f"Server {request.server} is disabled",
        }

    result = await invoke_mcp_tool(
        server=server,
        tool_name=request.tool,
        method=request.method,
        parameters=request.parameters,
    )

    return result


@router.get("/health")
async def mcp_health():
    """
    Health check for MCP discovery system.
    Checks mcp-discovery service and probes all registered servers.
    """
    # Check mcp-discovery service
    discovery_service_available = await discovery_client.is_available()
    discovery_service_health = None

    if discovery_service_available:
        discovery_service_health = await discovery_client.get_health()

    # Check local registry servers
    servers = mcp_registry.list_all()
    health_results = {}

    async def check_server(server: MCPServer):
        probe = await probe_mcp_server(server.url, timeout=3.0)
        return server.name, {
            "alive": probe["alive"],
            "enabled": server.enabled,
            "url": server.url,
            "last_seen": server.last_seen.isoformat() if server.last_seen else None,
            "tool_count": len(mcp_registry.get_tools(server.name)),
        }

    results = await asyncio.gather(
        *[check_server(s) for s in servers], return_exceptions=True
    )

    for result in results:
        if isinstance(result, tuple):
            name, status = result
            health_results[name] = status

    alive_count = sum(1 for r in health_results.values() if r.get("alive"))

    return {
        "healthy": alive_count > 0 or discovery_service_available,
        "discovery_service": {
            "available": discovery_service_available,
            "url": MCP_DISCOVERY_URL,
            "health": discovery_service_health,
        },
        "local_registry": {
            "servers": health_results,
            "alive_count": alive_count,
            "total_count": len(servers),
            "registry_file": str(mcp_registry.registry_file),
        },
    }


# =============================================================================
# Context Provider for Chat Integration
# =============================================================================


async def get_mcp_tools_context() -> str:
    """
    Generate a context string describing available MCP tools for injection
    into chat/LLM prompts. This enables models to know what tools they can use.
    """
    tools_response = await list_all_tools(refresh=False)
    tools = tools_response.get("tools", [])

    if not tools:
        return ""

    context_lines = [
        "## Available MCP Tools",
        "You have access to the following tools via the MCP protocol:",
        "",
    ]

    for tool in tools[:20]:  # Limit to 20 tools to avoid context overflow
        name = tool.get("name", tool.get("ref", "unknown"))
        description = tool.get("description", "No description")
        server = tool.get("server", "unknown")

        context_lines.append(f"- **{name}** ({server}): {description}")

        # Add parameters if available
        params = tool.get("parameters", [])
        if params:
            for param in params[:5]:
                param_name = param.get("name", "?")
                param_type = param.get("type", "any")
                required = "required" if param.get("required") else "optional"
                context_lines.append(f"  - `{param_name}` ({param_type}, {required})")

    context_lines.append("")
    context_lines.append(
        "To use a tool, ask me to invoke it with the required parameters."
    )

    return "\n".join(context_lines)


def get_mcp_tools_for_openai() -> List[Dict[str, Any]]:
    """
    Get MCP tools formatted for OpenAI function calling.
    This is a synchronous wrapper for use in chat endpoints.
    """
    # Get tools from cache (sync access)
    all_tools = []
    for server in mcp_registry.list_all():
        if server.enabled:
            tools = mcp_registry.get_tools(server.name)
            all_tools.extend(tools)

    openai_tools = []
    for tool in all_tools[:10]:  # Limit for token efficiency
        name = tool.get("name", tool.get("ref", ""))
        if not name:
            continue

        # Build OpenAI function spec
        func_spec = {
            "type": "function",
            "function": {
                "name": f"mcp_{name}",
                "description": tool.get("description", f"MCP tool: {name}"),
                "parameters": {
                    "type": "object",
                    "properties": {},
                    "required": [],
                },
            },
        }

        # Add parameters
        for param in tool.get("parameters", []):
            param_name = param.get("name")
            if param_name:
                func_spec["function"]["parameters"]["properties"][param_name] = {
                    "type": param.get("type", "string"),
                    "description": param.get("description", ""),
                }
                if param.get("required"):
                    func_spec["function"]["parameters"]["required"].append(param_name)

        openai_tools.append(func_spec)

    return openai_tools
