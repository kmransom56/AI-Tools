"""
Cagent Integration Module
Provides endpoints for code generation, CI/CD workflows, and agent orchestration
"""

from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional, Dict, Any
import subprocess
import os
import json
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/cagent", tags=["cagent"])


class CodeGenerationRequest(BaseModel):
    language: str  # python, typescript, go, java, mcp_server
    input: str  # Description of code to generate
    options: Optional[Dict[str, Any]] = {}


class WorkflowRequest(BaseModel):
    language: str
    input: str
    run_ci: bool = True  # Whether to run CI after generation
    options: Optional[Dict[str, Any]] = {}


class AgentInvokeRequest(BaseModel):
    agent_file: str  # e.g., 'coordinator_agent.yaml'
    input: str
    options: Optional[Dict[str, Any]] = {}


def invoke_powershell_agent(agent_file: str, input_data: str) -> Dict[str, Any]:
    """
    Invoke a cagent agent via PowerShell Invoke-ToolAgent wrapper.
    Returns the result as a dictionary.
    """
    ps_module_path = os.getenv(
        "PORT_MANAGER_MODULE",
        r"C:\Users\Keith Ransom\AI-Tools\PortManager\PortManager.psm1",
    )

    # Build PowerShell command
    ps_command = f"""
    Import-Module "{ps_module_path}"
    Invoke-ToolAgent -AgentFile '{agent_file}' -Input '{input_data.replace("'", "''")}'
    """

    try:
        result = subprocess.run(
            ["powershell", "-NoProfile", "-Command", ps_command],
            capture_output=True,
            text=True,
            timeout=300,  # 5 minute timeout
        )

        if result.returncode == 0:
            return {
                "success": True,
                "output": result.stdout.strip(),
                "agent": agent_file,
            }
        else:
            return {
                "success": False,
                "error": result.stderr.strip() or "Agent execution failed",
                "agent": agent_file,
            }
    except subprocess.TimeoutExpired:
        return {
            "success": False,
            "error": "Agent execution timeout (5 minutes)",
            "agent": agent_file,
        }
    except Exception as e:
        logger.error(f"PowerShell agent invocation failed: {e}")
        return {"success": False, "error": str(e), "agent": agent_file}


@router.post("/generate")
async def generate_code(request: CodeGenerationRequest):
    """
    Generate code using language-specific generator agents.
    Maps language to appropriate agent file and invokes it.
    """
    agent_map = {
        "python": "python_generator_agent.yaml",
        "typescript": "typescript_generator_agent.yaml",
        "go": "go_generator_agent.yaml",
        "java": "java_generator_agent.yaml",
        "mcp_server": "mcp_server_generator.yaml",
    }

    agent_file = agent_map.get(request.language.lower())
    if not agent_file:
        return {
            "success": False,
            "error": f"Unsupported language: {request.language}. Supported: {list(agent_map.keys())}",
        }

    # Invoke the generator agent
    result = invoke_powershell_agent(agent_file, request.input)

    if not result.get("success"):
        return {
            "success": False,
            "error": result.get("error", "Generation failed"),
            "agent": agent_file,
        }

    return {
        "success": True,
        "language": request.language,
        "agent": agent_file,
        "response": result.get("output"),
        "message": f"Code generated successfully using {agent_file}",
    }


@router.post("/workflow")
async def run_workflow(request: WorkflowRequest):
    """
    Run the full generator → CI workflow.
    This chains code generation with automated testing.
    """
    # Prepare workflow input as JSON
    workflow_input = json.dumps(
        {
            "language": request.language,
            "input": request.input,
            "run_ci": request.run_ci,
            "options": request.options or {},
        }
    )

    # Invoke the workflow agent
    result = invoke_powershell_agent("generator_ci_workflow.yaml", workflow_input)

    if not result.get("success"):
        return {
            "success": False,
            "error": result.get("error", "Workflow failed"),
            "workflow": "generator_ci_workflow.yaml",
        }

    return {
        "success": True,
        "language": request.language,
        "workflow": "generator_ci_workflow.yaml",
        "response": result.get("output"),
        "message": "Workflow completed successfully",
    }


@router.post("/invoke")
async def invoke_agent(request: AgentInvokeRequest):
    """
    Generic endpoint to invoke any cagent agent by file name.
    Useful for custom workflows and specialized agents.
    """
    # Validate agent file exists
    agent_path = os.path.join(
        r"C:\Users\Keith Ransom\AI-Tools\cagent_examples", request.agent_file
    )

    if not os.path.exists(agent_path):
        return {
            "success": False,
            "error": f"Agent file not found: {request.agent_file}",
        }

    # Invoke the agent
    result = invoke_powershell_agent(request.agent_file, request.input)

    if not result.get("success"):
        return {
            "success": False,
            "error": result.get("error", "Agent execution failed"),
            "agent": request.agent_file,
        }

    return {
        "success": True,
        "agent": request.agent_file,
        "response": result.get("output"),
        "message": f"Agent {request.agent_file} executed successfully",
    }


@router.get("/agents")
async def list_available_agents():
    """
    List all available cagent agents in the cagent_examples directory.
    """
    examples_dir = r"C:\Users\Keith Ransom\AI-Tools\cagent_examples"

    if not os.path.exists(examples_dir):
        return {"agents": [], "count": 0}

    agents = []
    for file in os.listdir(examples_dir):
        if file.endswith(".yaml") or file.endswith(".yml"):
            agent_path = os.path.join(examples_dir, file)
            agents.append(
                {"name": file, "path": agent_path, "size": os.path.getsize(agent_path)}
            )

    # Categorize agents
    categorized = {
        "generators": [a for a in agents if "generator" in a["name"]],
        "workflows": [a for a in agents if "workflow" in a["name"]],
        "tools": [
            a
            for a in agents
            if any(x in a["name"] for x in ["git", "docker", "curl", "filesystem"])
        ],
        "coordinators": [a for a in agents if "coordinator" in a["name"]],
        "other": [
            a
            for a in agents
            if not any(
                x in a["name"]
                for x in [
                    "generator",
                    "workflow",
                    "git",
                    "docker",
                    "curl",
                    "filesystem",
                    "coordinator",
                ]
            )
        ],
    }

    return {"agents": agents, "count": len(agents), "categorized": categorized}


@router.get("/health")
async def cagent_health():
    """
    Check if cagent integration is healthy.
    Verifies PowerShell module and cagent examples directory exist.
    """
    ps_module_path = os.getenv(
        "PORT_MANAGER_MODULE",
        r"C:\Users\Keith Ransom\AI-Tools\PortManager\PortManager.psm1",
    )
    examples_dir = r"C:\Users\Keith Ransom\AI-Tools\cagent_examples"

    checks = {
        "powershell_module": os.path.exists(ps_module_path),
        "examples_directory": os.path.exists(examples_dir),
        "cagent_service": False,  # Will check Docker service
        "mcp_server": False,  # Will check MCP server
    }

    # Check if cagent Docker service is running
    try:
        result = subprocess.run(
            ["docker", "ps", "--filter", "name=cagent", "--format", "{{.Names}}"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        checks["cagent_service"] = "cagent" in result.stdout
    except Exception:
        pass

    # Check if MCP server is running
    try:
        result = subprocess.run(
            ["docker", "ps", "--filter", "name=mcp-server", "--format", "{{.Names}}"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        checks["mcp_server"] = "mcp-server" in result.stdout
    except Exception:
        pass

    all_healthy = all(checks.values())

    return {
        "healthy": all_healthy,
        "checks": checks,
        "message": (
            "All systems operational" if all_healthy else "Some components unavailable"
        ),
    }
