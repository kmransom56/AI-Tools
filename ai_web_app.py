"""
AI Toolkit Web Frontend
FastAPI application for interacting with AI tools through a web interface
"""

from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import (
    HTMLResponse,
    JSONResponse,
    FileResponse,
    StreamingResponse,
)
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel
import os
import subprocess
import openai
import anthropic
import google.genai as genai  # type: ignore
import yaml
import docker
import logging
import httpx
import shlex

from contextlib import asynccontextmanager

# Import cagent integration
from cagent_integration import router as cagent_router

# Import MCP discovery
from mcp_discovery import router as mcp_router, mcp_registry, get_mcp_tools_context

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifecycle events for model warmup and cleanup"""
    logger.info("=" * 60)
    logger.info("AI Toolkit Web Interface Starting")
    logger.info(f"Template Directory: {template_dir}")
    logger.info(f"Working Directory: {os.getcwd()}")
    logger.info(
        f"API Clients: OpenAI={bool(openai_client)}, Anthropic={bool(anthropic_client)}, Gemini={bool(gemini_client)}"
    )
    logger.info(f"Docker Client: {docker_client is not None}")

    # GPU Warmup
    try:
        import torch

        if torch.cuda.is_available():
            # Warm up CUDA kernels
            _ = torch.zeros(1).cuda()
            logger.info(f"GPU Warmup complete. Device: {torch.cuda.get_device_name(0)}")
        else:
            logger.info("CUDA not available, skipping GPU warmup")
    except Exception as e:
        logger.warning(f"GPU Warmup failed or torch not installed: {e}")

    # MCP Discovery initialization
    try:
        logger.info(f"MCP Registry: {len(mcp_registry.list_all())} servers registered")
    except Exception as e:
        logger.warning(f"MCP Registry initialization: {e}")

    logger.info("=" * 60)
    yield
    logger.info("AI Toolkit Web Interface Shutting Down")


app = FastAPI(title="AI Toolkit Web Interface", lifespan=lifespan)

# Register cagent integration router
app.include_router(cagent_router)

# Register MCP discovery router
app.include_router(mcp_router)


# Configure templates - support both Docker (/app/templates) and local (./templates) paths
template_dirs = [
    "/app/templates",
    os.path.join(os.path.dirname(__file__), "templates"),
    "./templates",
]
template_dir = next((d for d in template_dirs if os.path.isdir(d)), None)
if not template_dir:
    logger.warning(f"No templates directory found. Searched: {template_dirs}")
    template_dir = template_dirs[0]  # Fall back to first option

templates = Jinja2Templates(directory=template_dir)
logger.info(f"Templates loaded from: {template_dir}")

# Configure AI clients with validation
openai_key = os.getenv("OPENAI_API_KEY")
anthropic_key = os.getenv("ANTHROPIC_API_KEY")
gemini_key = os.getenv("GEMINI_API_KEY")
gemini_model_name = "gemini-pro"
powerinfer_host = os.getenv("POWERINFER_HOST")  # e.g., http://localhost:11434
powerinfer_model = os.getenv("POWERINFER_MODEL")
powerinfer_cli = os.getenv(
    "POWERINFER_CLI"
)  # e.g., "powerinfer --model \"C:\\models\\llama3.gguf\" --prompt '{prompt}'"
turbosparse_host = os.getenv("TURBOSPARSE_HOST")  # e.g., http://localhost:11435
turbosparse_model = os.getenv("TURBOSPARSE_MODEL")
turbosparse_cli = os.getenv(
    "TURBOSPARSE_CLI"
)  # e.g., "turbosparse --model /models/llama3.gguf --prompt '{prompt}'"

# Initialize clients - handle missing keys gracefully
openai_client = None
anthropic_client = None
gemini_client = None

if openai_key:
    try:
        openai_client = openai.OpenAI(api_key=openai_key)
        logger.info("OpenAI client initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize OpenAI client: {e}")
else:
    logger.warning("OPENAI_API_KEY not set")

if anthropic_key:
    try:
        anthropic_client = anthropic.Anthropic(api_key=anthropic_key)
        logger.info("Anthropic client initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize Anthropic client: {e}")
else:
    logger.warning("ANTHROPIC_API_KEY not set")

if gemini_key:
    try:
        gemini_client = genai.Client(api_key=gemini_key)
        logger.info("Google Gemini client configured successfully")
    except Exception as e:
        logger.error(f"Failed to configure Gemini client: {e}")
else:
    logger.warning("GEMINI_API_KEY not set")

# Docker client (may not be available in all environments)
try:
    docker_client = docker.from_env()
except Exception:
    docker_client = None


class ChatRequest(BaseModel):
    message: str
    model: str = (
        "gpt-4"  # gpt-4, claude-3-5-sonnet-20241022, gemini-pro, sgpt, cagent, or mcp
    )
    include_mcp_tools: bool = False  # Include MCP tools in system prompt


class CodeRequest(BaseModel):
    code: str
    language: str = "python"


class CagentRunRequest(BaseModel):
    example_path: str
    # Optional overrides (not trusted from UI in most cases)
    overrides: dict = {}


def find_cagent_examples():
    """Search for YAML files under common repo locations and return metadata."""
    candidates = []
    roots = ["/workspace", "/app/workspace", "/app", "./"]
    seen = set()
    for root in roots:
        if not os.path.exists(root):
            continue
        for dirpath, dirs, files in os.walk(root):
            # only consider files under a path containing 'cagent' and 'examples'
            if not ("cagent" in dirpath and "examples" in dirpath):
                continue
            for f in files:
                if f.endswith(".yaml") or f.endswith(".yml"):
                    full = os.path.join(dirpath, f)
                    absfull = os.path.abspath(full)
                    if absfull in seen:
                        continue
                    seen.add(absfull)
                    meta = {
                        "path": absfull,
                        "relpath": os.path.relpath(absfull, start=root),
                        "name": f,
                        "tag": None,
                        "dry_run": None,
                        "max_iterations": None,
                    }
                    # try to parse basic fields
                    try:
                        with open(full, "r", encoding="utf-8") as fh:
                            docs = list(yaml.safe_load_all(fh))
                            # Find first dict that contains keys of interest
                            for doc in docs:
                                if isinstance(doc, dict):
                                    if not meta["tag"] and "tag" in doc:
                                        meta["tag"] = doc.get("tag")
                                    if meta["dry_run"] is None and "dry_run" in doc:
                                        meta["dry_run"] = bool(doc.get("dry_run"))
                                    if (
                                        meta["max_iterations"] is None
                                        and "max_iterations" in doc
                                    ):
                                        try:
                                            meta["max_iterations"] = int(
                                                doc.get("max_iterations")
                                            )
                                        except Exception:
                                            meta["max_iterations"] = None
                    except Exception:
                        # Could not parse YAML; ignore and still include
                        pass
                    candidates.append(meta)
    # sort
    candidates.sort(key=lambda x: (x.get("tag") or "", x["name"]))
    return candidates


def get_specialized_agents_path():
    """Return absolute path to the specialized agents markdown file."""
    candidates = [
        os.path.join(os.getcwd(), ".github", "SPECIALIZED AGENTS.md"),
        os.path.join(os.path.dirname(__file__), ".github", "SPECIALIZED AGENTS.md"),
    ]
    for path in candidates:
        if os.path.isfile(path):
            return path
    return None


# Structured agent definitions (for frontend consumption)
AGENTS = [
    {
        "name": "Python Developer Agent",
        "role": "python-dev",
        "purpose": "Handle Python code development, FastAPI endpoints, and application logic.",
        "activation_triggers": [
            "Python file modifications requested",
            "New FastAPI endpoint creation",
            "Python package management",
            "Code quality improvements",
            "Bug fixes in Python code",
        ],
        "responsibilities": [
            "Write clean, well-tested Python code",
            "Implement FastAPI endpoints with proper validation",
            "Handle async/await patterns correctly",
            "Follow uv package management conventions",
            "Maintain black/flake8 compliance",
            "Write comprehensive docstrings and type hints",
        ],
        "skills": [
            "FastAPI development",
            "Python code quality (black, flake8)",
            "Async/await patterns",
            "pytest unit testing",
            "Package management with uv",
        ],
    },
    {
        "name": "DevOps & Deployment Agent",
        "role": "devops",
        "purpose": "Manage infrastructure, Docker, containerization, and deployment workflows.",
        "activation_triggers": [
            "Docker/container changes requested",
            "Deployment configuration needed",
            "Environment setup required",
            "Port allocation needed",
            "Container orchestration tasks",
        ],
        "responsibilities": [
            "Create and optimize Dockerfiles",
            "Manage docker-compose configurations",
            "Port allocation via port-registry",
            "Environment variable management",
            "Health check implementation",
            "Monitoring and alerting configuration",
        ],
        "skills": [
            "Docker and docker-compose",
            "Port registry management",
            "Environment configuration",
            "Deployment automation",
            "Health checks and monitoring",
        ],
    },
    {
        "name": "Network Infrastructure Agent",
        "role": "network",
        "purpose": "Handle Fortinet, Meraki, DNS, and network topology management.",
        "activation_triggers": [
            "FortiGate/FortiManager configuration",
            "Meraki Dashboard API calls",
            "DNS (Technitium) management",
            "Network topology visualization",
            "Device discovery and inventory",
            "Multi-site network management",
        ],
        "responsibilities": [
            "Parse and generate FortiOS configurations",
            "Execute Meraki Dashboard API operations",
            "Manage Technitium DNS records",
            "Create network topology visualizations",
            "Discover and catalog network devices",
            "Manage multi-site deployments (3,500+ locations)",
        ],
        "skills": [
            "Fortinet ecosystem (FortiGate, FortiManager, FortiAP, FortiSwitch)",
            "Cisco Meraki Dashboard API",
            "Technitium DNS management",
            "Network topology visualization (3D force-graph)",
            "Device discovery and inventory",
            "BGP and routing configuration",
            "RADIUS and certificate management",
        ],
    },
    {
        "name": "Database & Data Agent",
        "role": "data",
        "purpose": "Manage databases, migrations, data processing, and analytics.",
        "activation_triggers": [
            "Database schema changes",
            "Migration creation needed",
            "Data import/export operations",
            "Query optimization required",
            "Data validation/cleaning",
        ],
        "responsibilities": [
            "Create database migrations",
            "Write and optimize SQL queries",
            "Implement data transformations",
            "Handle data import/export",
            "Perform data validation",
            "Manage database backups",
            "Create analytics reports",
        ],
        "skills": [
            "SQL query writing and optimization",
            "Database migrations (Alembic)",
            "Data processing (Pandas)",
            "Backup and restore procedures",
            "Analytics and reporting",
        ],
    },
    {
        "name": "Testing & QA Agent",
        "role": "qa",
        "purpose": "Create tests, validate quality, and ensure reliability.",
        "activation_triggers": [
            "New test creation requested",
            "Code quality checks needed",
            "E2E testing required",
            "Regression testing",
            "Coverage analysis",
        ],
        "responsibilities": [
            "Write unit tests (pytest)",
            "Create integration tests",
            "Generate E2E tests (Playwright)",
            "Calculate code coverage",
            "Perform regression testing",
            "Create test fixtures and mocks",
        ],
        "skills": [
            "pytest framework",
            "Playwright E2E testing",
            "Coverage analysis",
            "Test fixtures and mocking",
            "Performance testing",
            "Regression testing",
        ],
    },
    {
        "name": "Documentation Agent",
        "role": "docs",
        "purpose": "Create and maintain all documentation.",
        "activation_triggers": [
            "Documentation updates needed",
            "API documentation generation",
            "User guide creation",
            "Architecture decision documentation",
            "Troubleshooting guide updates",
        ],
        "responsibilities": [
            "Generate API documentation (OpenAPI/Swagger)",
            "Write user guides and tutorials",
            "Create architecture documentation",
            "Document architectural decisions (ADRs)",
            "Update README and setup guides",
            "Write troubleshooting guides",
        ],
        "skills": [
            "Markdown documentation",
            "OpenAPI/Swagger generation",
            "Architecture diagramming",
            "User guide writing",
            "ADR (Architecture Decision Record) creation",
        ],
    },
]


async def call_local_chat(host: str, model: str, message: str, timeout: float = 30.0):
    """Call a local LLM endpoint that speaks an OpenAI-compatible chat/completions API."""
    # Normalize host to include the chat completion path
    if host.endswith("/"):
        host = host[:-1]
    if host.endswith("/chat/completions"):
        url = host
    elif host.endswith("/v1"):
        url = f"{host}/chat/completions"
    elif host.endswith("/v1/"):
        url = f"{host}chat/completions"
    else:
        url = f"{host}/v1/chat/completions"

    payload = {
        "model": model,
        "messages": [{"role": "user", "content": message}],
        "stream": False,
        "temperature": 0.7,
    }

    async with httpx.AsyncClient(timeout=timeout) as client:
        resp = await client.post(url, json=payload)
        if resp.status_code >= 400:
            raise HTTPException(status_code=resp.status_code, detail=resp.text)
        data = resp.json()
        # Support both OpenAI-compatible and minimal responses
        if "choices" in data and data["choices"]:
            return data["choices"][0].get("message", {}).get("content") or data[
                "choices"
            ][0].get("text")
        # Fallback: try top-level 'text'
        if "text" in data:
            return data["text"]
        raise HTTPException(
            status_code=500, detail="Unexpected local backend response format"
        )


def run_cli_chat(cmd_template: str, message: str, timeout: float = 60.0):
    """Run a local CLI command for LLM inference. Expects a {prompt} placeholder in the template."""
    if "{prompt}" not in cmd_template:
        raise HTTPException(
            status_code=400, detail="CLI template must include {prompt} placeholder"
        )
    command_str = cmd_template.replace("{prompt}", message.replace('"', '\\"'))
    # Use shlex.split to safely tokenize
    try:
        cmd = shlex.split(command_str)
    except Exception:
        cmd = command_str

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            shell=isinstance(cmd, str),
        )
        if result.returncode != 0:
            raise HTTPException(
                status_code=500, detail=result.stderr or "CLI inference failed"
            )
        return result.stdout.strip()
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=504, detail="CLI inference timeout")


async def route_to_cagent(message: str, include_mcp_context: bool = True) -> dict:
    """
    Intelligent routing to cagent based on message content.
    Detects intent and routes to appropriate cagent agent.
    Optionally includes MCP tools context for tool-aware responses.
    """
    message_lower = message.lower()

    # Inject MCP tools context if requested
    mcp_context = ""
    if include_mcp_context:
        try:
            mcp_context = await get_mcp_tools_context()
            if mcp_context:
                message = f"{mcp_context}\n\n---\n\nUser Request: {message}"
        except Exception as e:
            logger.warning(f"Failed to get MCP tools context: {e}")

    # Intent detection patterns
    code_gen_keywords = ["generate", "create", "write", "build", "implement", "code"]
    language_keywords = {
        "python": ["python", "py", "fastapi", "flask", "django"],
        "typescript": ["typescript", "ts", "react", "next.js", "angular"],
        "go": ["golang", "go"],
        "java": ["java", "spring", "maven"],
        "mcp_server": ["mcp", "model context protocol", "tool catalog"],
    }

    # Check if this is a code generation request
    is_code_gen = any(keyword in message_lower for keyword in code_gen_keywords)

    if is_code_gen:
        # Detect language
        detected_language = "python"  # default
        for lang, keywords in language_keywords.items():
            if any(kw in message_lower for kw in keywords):
                detected_language = lang
                break

        # Import the cagent function
        from cagent_integration import invoke_powershell_agent

        # Map language to agent file
        agent_map = {
            "python": "python_generator_agent.yaml",
            "typescript": "typescript_generator_agent.yaml",
            "go": "go_generator_agent.yaml",
            "java": "java_generator_agent.yaml",
            "mcp_server": "mcp_server_generator.yaml",
        }

        agent_file = agent_map.get(detected_language)
        result = invoke_powershell_agent(agent_file, message)

        if result.get("success"):
            return {
                "success": True,
                "response": f"🤖 Cagent ({detected_language}):\n\n{result.get('output', '')}",
                "model": "cagent",
                "provider": "cagent",
                "agent": agent_file,
                "language": detected_language,
            }
        else:
            return {
                "success": False,
                "error": f"Cagent error: {result.get('error', 'Unknown error')}",
            }
    else:
        # General query - use coordinator agent
        from cagent_integration import invoke_powershell_agent

        result = invoke_powershell_agent("coordinator_agent.yaml", message)

        if result.get("success"):
            return {
                "success": True,
                "response": f"🤖 Cagent (Coordinator):\n\n{result.get('output', '')}",
                "model": "cagent",
                "provider": "cagent",
            }
        else:
            return {
                "success": False,
                "error": f"Cagent error: {result.get('error', 'Unknown error')}",
            }


@app.get("/api/cagent/examples")
async def cagent_examples():
    """Return list of discovered cagent examples with basic metadata."""
    examples = find_cagent_examples()
    return {"examples": examples, "count": len(examples)}


@app.post("/api/cagent/run")
async def cagent_run(req: CagentRunRequest):
    """Run a cagent example in a docker/cagent image with safety checks.
    Enforces CAGENT_DRY_RUN=1 and checks max_iterations <= 10.
    Returns logs (synchronously) or an error.
    """
    # Resolve path and ensure it exists and is under allowed roots
    example_path = os.path.abspath(req.example_path)
    allowed_roots = [
        os.path.abspath(p)
        for p in ["/workspace", "/app/workspace", "/app", os.getcwd()]
    ]
    if not any(example_path.startswith(r) for r in allowed_roots):
        raise HTTPException(
            status_code=400, detail="example path not inside allowed repository paths"
        )
    if not os.path.exists(example_path):
        raise HTTPException(status_code=404, detail="example file not found")

    # Parse YAML to inspect safety fields
    try:
        with open(example_path, "r", encoding="utf-8") as fh:
            docs = list(yaml.safe_load_all(fh))
            # merge keys from docs for top-level fields
            merged = {}
            for d in docs:
                if isinstance(d, dict):
                    merged.update(d)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to parse YAML: {e}")

    # Enforce/validate safety
    if "max_iterations" in merged:
        try:
            mi = int(merged.get("max_iterations"))
            if mi > 10:
                raise HTTPException(
                    status_code=400, detail="max_iterations too large (must be <= 10)"
                )
        except ValueError:
            raise HTTPException(
                status_code=400, detail="max_iterations is not an integer"
            )

    # We'll enforce dry run using env var regardless of file
    env_overrides = req.overrides or {}
    env = {"CAGENT_DRY_RUN": "1"}
    # Merge any safe overrides (but do not allow disabling dry_run or increasing max_iterations)
    if env_overrides.get("CAGENT_DRY_RUN") in ["0", "false", "False"]:
        raise HTTPException(
            status_code=403, detail="Disabling dry_run via UI is not permitted"
        )

    # Ensure docker client available
    if docker_client is None:
        raise HTTPException(
            status_code=500, detail="Docker client not available in server environment"
        )

    image = "docker/cagent:latest"
    try:
        # Pull image (may be no-op if present)
        docker_client.images.pull(image)
    except Exception:
        # Not fatal; may be available locally
        pass

    # Determine workdir inside container. We expect repo root to be mounted at /workspace
    # and example_path to be accessible under that mount. Map host path to /workspace.
    host_workspace = None
    for root in allowed_roots:
        if example_path.startswith(root):
            host_workspace = root
            break
    if not host_workspace:
        host_workspace = os.path.dirname(example_path)

    bind_workspace = {host_workspace: {"bind": "/workspace", "mode": "rw"}}
    # Also mount docker socket so the cagent container can use docker if needed
    if os.path.exists("/var/run/docker.sock"):
        bind_workspace["/var/run/docker.sock"] = {
            "bind": "/var/run/docker.sock",
            "mode": "rw",
        }

    # Run the container (synchronously) and capture logs
    # Use the image entrypoint: run <example_relative_path>
    # We pass command ['run', example_relpath]
    example_rel = os.path.relpath(example_path, start=host_workspace)
    try:
        logs = docker_client.containers.run(
            image=image,
            command=["run", example_rel],
            environment=env,
            volumes=bind_workspace,
            remove=True,
            stdout=True,
            stderr=True,
            stream=False,
            detach=False,
            working_dir="/workspace",
        )
        # logs may be bytes
        if isinstance(logs, bytes):
            logs_text = logs.decode("utf-8", errors="replace")
        else:
            logs_text = str(logs)
        return {"success": True, "logs": logs_text}
    except docker.errors.ContainerError as ce:
        # container failed, get logs
        return JSONResponse(
            status_code=500,
            content={
                "success": False,
                "error": str(ce),
                "logs": getattr(ce, "stderr", ""),
            },
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/", response_class=HTMLResponse)
async def home(request: Request):
    """Serve the main web interface"""
    return templates.TemplateResponse("index.html", {"request": request})


# (rest of file unchanged: models, chat, execute_code, health)


@app.get("/api/models")
async def get_models():
    """Return available AI models"""
    models = [
        {"id": "gpt-4", "name": "GPT-4 (OpenAI)", "provider": "openai"},
        {
            "id": "gpt-4-turbo-preview",
            "name": "GPT-4 Turbo (OpenAI)",
            "provider": "openai",
        },
        {"id": "gpt-3.5-turbo", "name": "GPT-3.5 Turbo (OpenAI)", "provider": "openai"},
        {
            "id": "claude-3-5-sonnet-20241022",
            "name": "Claude 3.5 Sonnet (Anthropic)",
            "provider": "anthropic",
        },
        {
            "id": "claude-3-opus-20240229",
            "name": "Claude 3 Opus (Anthropic)",
            "provider": "anthropic",
        },
        {"id": "gemini-pro", "name": "Gemini Pro (Google)", "provider": "google"},
        {"id": "sgpt", "name": "Shell-GPT (CLI)", "provider": "sgpt"},
        {"id": "cagent", "name": "Cagent (AI Agent with Tools)", "provider": "cagent"},
        {"id": "mcp", "name": "MCP Tools (Dynamic Discovery)", "provider": "mcp"},
    ]

    if (powerinfer_host and powerinfer_model) or (powerinfer_cli and powerinfer_model):
        models.append(
            {
                "id": "powerinfer",
                "name": f"PowerInfer ({powerinfer_model or 'cli'})",
                "provider": "powerinfer",
            }
        )

    if (turbosparse_host and turbosparse_model) or (
        turbosparse_cli and turbosparse_model
    ):
        models.append(
            {
                "id": "turbosparse",
                "name": f"TurboSparse ({turbosparse_model or 'cli'})",
                "provider": "turbosparse",
            }
        )

    return {"models": models}


@app.get("/api/agents/specialized", response_class=FileResponse)
async def get_specialized_agents():
    """Serve the specialized agents guide for the frontend to consume."""
    path = get_specialized_agents_path()
    if not path:
        raise HTTPException(status_code=404, detail="SPECIALIZED AGENTS file not found")
    return FileResponse(
        path, media_type="text/markdown", filename="SPECIALIZED_AGENTS.md"
    )


@app.get("/api/agents", response_class=JSONResponse)
async def list_agents():
    """Return structured agent definitions for frontend consumption."""
    return {"agents": AGENTS}


@app.post("/api/chat/stream")
async def chat_stream(request: ChatRequest):
    """Stream a chat response progressively. Uses real streaming when available,
    otherwise chunks a full response."""

    async def chunked_text(text: str, size: int = 64):
        for i in range(0, len(text), size):
            yield text[i : i + size]

    def openai_stream_gen():
        try:
            stream = openai_client.chat.completions.create(
                model=request.model,
                messages=[{"role": "user", "content": request.message}],
                stream=True,
            )
            for chunk in stream:
                try:
                    delta = getattr(chunk.choices[0], "delta", None)
                    if delta and getattr(delta, "content", None):
                        yield delta.content
                    else:
                        msg = getattr(chunk.choices[0], "message", None)
                        if msg and getattr(msg, "content", None):
                            yield msg.content
                except Exception:
                    continue
        except Exception as e:
            yield f"\n[stream error: {e}]\n"

    def anthropic_stream_gen():
        try:
            stream = anthropic_client.messages.create(
                model=request.model,
                max_tokens=4096,
                messages=[{"role": "user", "content": request.message}],
                stream=True,
            )
            # Anthropics SDK may yield events; try common fields
            for event in stream:
                try:
                    # content_block_delta with text
                    delta = getattr(event, "delta", None)
                    if delta and getattr(delta, "text", None):
                        yield delta.text
                    # message_delta with new content
                    elif getattr(event, "type", "") == "message_delta":
                        parts = getattr(event, "delta", {}).get("content", [])
                        for p in parts:
                            t = p.get("text")
                            if t:
                                yield t
                except Exception:
                    continue
        except Exception as e:
            yield f"\n[stream error: {e}]\n"

    def gemini_stream_gen():
        try:
            stream = gemini_client.models.generate_content(
                model=gemini_model_name,
                contents=request.message,
                stream=True,
            )
            for event in stream:
                try:
                    # Prefer direct text field if present
                    t = getattr(event, "text", None)
                    if t:
                        yield t
                        continue
                    # Fallback: iterate candidates/parts for text
                    candidates = getattr(event, "candidates", None)
                    if candidates:
                        for c in candidates:
                            content = getattr(c, "content", None)
                            parts = getattr(content, "parts", []) if content else []
                            for p in parts:
                                pt = getattr(p, "text", None)
                                if pt:
                                    yield pt
                except Exception:
                    continue
        except Exception as e:
            yield f"\n[stream error: {e}]\n"

    async def local_full_response():
        # Fallback: call non-stream path and return text
        data = await chat(request)
        if isinstance(data, dict) and data.get("success"):
            return data.get("response", "")
        return data.get("error", "Failed") if isinstance(data, dict) else "Failed"

    try:
        if request.model.startswith("gpt"):
            if not openai_client:
                return JSONResponse(
                    status_code=400,
                    content={"success": False, "error": "OpenAI not configured"},
                )
            return StreamingResponse(openai_stream_gen(), media_type="text/plain")

        if request.model.startswith("claude"):
            if not anthropic_client:
                return JSONResponse(
                    status_code=400,
                    content={"success": False, "error": "Anthropic not configured"},
                )
            return StreamingResponse(anthropic_stream_gen(), media_type="text/plain")

        if request.model == "gemini-pro":
            if not gemini_client:
                return JSONResponse(
                    status_code=400,
                    content={"success": False, "error": "Gemini not configured"},
                )
            return StreamingResponse(gemini_stream_gen(), media_type="text/plain")

        # Chunked fallback for other providers
        text = await local_full_response()
        return StreamingResponse(chunked_text(text), media_type="text/plain")
    except Exception as e:
        logger.error(f"Stream chat error: {e}", exc_info=True)
        return JSONResponse(
            status_code=500, content={"success": False, "error": str(e)}
        )


@app.post("/api/chat")
async def chat(request: ChatRequest):
    """Send a message to the selected AI model"""
    try:
        if request.model.startswith("gpt"):
            # OpenAI
            if not openai_client:
                return {
                    "success": False,
                    "error": "OpenAI API key not configured. Set OPENAI_API_KEY environment variable.",
                }

            # Build messages with optional MCP tools context
            messages = []
            if request.include_mcp_tools:
                mcp_context = await get_mcp_tools_context()
                if mcp_context:
                    messages.append(
                        {
                            "role": "system",
                            "content": f"You have access to the following tools:\n\n{mcp_context}",
                        }
                    )
            messages.append({"role": "user", "content": request.message})

            response = openai_client.chat.completions.create(
                model=request.model,
                messages=messages,
            )
            return {
                "success": True,
                "response": response.choices[0].message.content,
                "model": request.model,
                "provider": "openai",
                "mcp_tools_included": request.include_mcp_tools,
            }

        elif request.model.startswith("claude"):
            # Anthropic
            if not anthropic_client:
                return {
                    "success": False,
                    "error": "Anthropic API key not configured. Set ANTHROPIC_API_KEY environment variable.",
                }
            response = anthropic_client.messages.create(
                model=request.model,
                max_tokens=4096,
                messages=[{"role": "user", "content": request.message}],
            )
            return {
                "success": True,
                "response": response.content[0].text,
                "model": request.model,
                "provider": "anthropic",
            }

        elif request.model == "gemini-pro":
            # Google Gemini (google.genai client)
            if not gemini_client:
                return {
                    "success": False,
                    "error": "Gemini API key not configured. Set GEMINI_API_KEY environment variable.",
                }
            response = gemini_client.models.generate_content(
                model=gemini_model_name,
                contents=request.message,
            )
            text = getattr(response, "text", None)
            if not text and getattr(response, "candidates", None):
                try:
                    text = response.candidates[0].content.parts[0].text
                except Exception:
                    text = None
            if not text:
                text = str(response)
            return {
                "success": True,
                "response": text,
                "model": request.model,
                "provider": "google",
            }

        elif request.model == "sgpt":
            # Shell-GPT
            try:
                result = subprocess.run(
                    ["sgpt", request.message],
                    capture_output=True,
                    text=True,
                    timeout=60,
                )
                if result.returncode == 0:
                    return {
                        "success": True,
                        "response": result.stdout,
                        "model": "sgpt",
                        "provider": "sgpt",
                    }
                else:
                    return {
                        "success": False,
                        "error": result.stderr or "Shell-GPT execution failed",
                    }
            except FileNotFoundError:
                return {
                    "success": False,
                    "error": "Shell-GPT not installed. Install with: pip install shell-gpt",
                }

        elif request.model == "powerinfer":
            if powerinfer_host and powerinfer_model:
                content = await call_local_chat(
                    powerinfer_host, powerinfer_model, request.message
                )
            elif powerinfer_cli and powerinfer_model:
                content = run_cli_chat(powerinfer_cli, request.message)
            else:
                return {
                    "success": False,
                    "error": "PowerInfer not configured. Set POWERINFER_HOST/POWERINFER_MODEL or POWERINFER_CLI/POWERINFER_MODEL.",
                }
            return {
                "success": True,
                "response": content,
                "model": request.model,
                "provider": "powerinfer",
            }

        elif request.model == "turbosparse":
            if turbosparse_host and turbosparse_model:
                content = await call_local_chat(
                    turbosparse_host, turbosparse_model, request.message
                )
            elif turbosparse_cli and turbosparse_model:
                content = run_cli_chat(turbosparse_cli, request.message)
            else:
                return {
                    "success": False,
                    "error": "TurboSparse not configured. Set TURBOSPARSE_HOST/TURBOSPARSE_MODEL or TURBOSPARSE_CLI/TURBOSPARSE_MODEL.",
                }
            return {
                "success": True,
                "response": content,
                "model": request.model,
                "provider": "turbosparse",
            }

        elif request.model == "cagent":
            # Route to cagent with intelligent intent detection
            return await route_to_cagent(request.message)

        elif request.model == "mcp":
            # MCP Tools mode - uses OpenAI with MCP tools context and function calling
            if not openai_client:
                return {
                    "success": False,
                    "error": "MCP mode requires OpenAI. Set OPENAI_API_KEY.",
                }

            # Get MCP tools context
            mcp_context = await get_mcp_tools_context()

            # Build system message with MCP tools
            system_message = """You are an AI assistant with access to MCP (Model Context Protocol) tools.
When the user asks to perform an action that requires a tool, explain which tool you would use and with what parameters.
If the user explicitly asks you to invoke a tool, describe the invocation request.

"""
            if mcp_context:
                system_message += mcp_context

            # Call OpenAI with the enhanced context
            response = openai_client.chat.completions.create(
                model="gpt-4",
                messages=[
                    {"role": "system", "content": system_message},
                    {"role": "user", "content": request.message},
                ],
            )

            return {
                "success": True,
                "response": response.choices[0].message.content,
                "model": "mcp",
                "provider": "mcp",
                "mcp_tools_available": bool(mcp_context),
            }

        else:
            return {"success": False, "error": f"Unknown model: {request.model}"}

    except Exception as e:
        logger.error(f"Chat error: {e}", exc_info=True)
        return {"success": False, "error": str(e)}


@app.post("/api/execute-code")
async def execute_code(request: CodeRequest):
    """Execute Python code in the container"""
    try:
        logger.info(f"Executing {request.language} code")
        if request.language == "python":
            result = subprocess.run(
                ["python", "-c", request.code],
                capture_output=True,
                text=True,
                timeout=30,
            )
            return {
                "success": result.returncode == 0,
                "stdout": result.stdout,
                "stderr": result.stderr,
                "exit_code": result.returncode,
            }
        else:
            return {
                "success": False,
                "error": f"Unsupported language: {request.language}",
            }
    except subprocess.TimeoutExpired:
        logger.warning("Code execution timeout")
        return {"success": False, "error": "Execution timeout (30s limit)"}
    except Exception as e:
        logger.error(f"Code execution error: {e}", exc_info=True)
        return {"success": False, "error": str(e)}


@app.get("/api/gpu")
async def get_gpu_info():
    """Return detailed GPU status and memory usage"""
    try:
        import torch

        if not torch.cuda.is_available():
            return {"available": False, "error": "CUDA not available"}

        return {
            "available": True,
            "device_name": torch.cuda.get_device_name(0),
            "memory_allocated": f"{torch.cuda.memory_allocated(0) / 1024**2:.2f} MB",
            "memory_reserved": f"{torch.cuda.memory_reserved(0) / 1024**2:.2f} MB",
            "max_memory_allocated": f"{torch.cuda.max_memory_allocated(0) / 1024**2:.2f} MB",
            "vram_total": f"{torch.cuda.get_device_properties(0).total_memory / 1024**2:.2f} MB",
            "capability": torch.cuda.get_device_capability(0),
        }
    except Exception as e:
        return {"available": False, "error": str(e)}


@app.get("/api/health")
async def health():
    """Health check endpoint with detailed status and GPU monitoring"""
    gpu_status = "unknown"
    try:
        import torch

        gpu_status = "available" if torch.cuda.is_available() else "unavailable"
    except Exception:
        gpu_status = "torch_not_found"

    return {
        "status": "healthy",
        "timestamp": __import__("datetime").datetime.utcnow().isoformat(),
        "gpu_status": gpu_status,
        "apis_configured": {
            "openai": bool(openai_client),
            "anthropic": bool(anthropic_client),
            "gemini": bool(gemini_client),
            "docker": docker_client is not None,
            "powerinfer": bool(
                (powerinfer_host and powerinfer_model)
                or (powerinfer_cli and powerinfer_model)
            ),
            "turbosparse": bool(
                (turbosparse_host and turbosparse_model)
                or (turbosparse_cli and turbosparse_model)
            ),
        },
        "environment": {"template_dir": template_dir, "cwd": os.getcwd()},
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
