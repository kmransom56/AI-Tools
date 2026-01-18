# AI-Tools Project - Claude Assistant Guide

**Last Updated**: 2026-01-17
**Project Type**: AI Development Toolkit with GPU-accelerated inference, agent orchestration, and network automation
**Tech Stack**: Python 3.10+, FastAPI, Docker, PowerShell, CUDA, PyTorch

---

## Quick Start Reference

### Essential Commands

```bash
# Development Server (Local)
python run_dev_server.py

# Docker Compose (Production)
docker compose up --build -d

# View logs
docker compose logs -f ai-toolkit

# Health check
curl http://localhost:11000/api/health

# Run quality checks (in order)
black ai_web_app.py cagent_integration.py
flake8 ai_web_app.py cagent_integration.py --max-line-length=88
python -m py_compile *.py
```

### Key URLs

- **Web Interface**: http://localhost:11000/
- **API Documentation**: http://localhost:11000/docs
- **TabbyML**: http://localhost:11001/
- **Cagent Service**: http://localhost:11002/
- **MCP Server**: http://localhost:11003/

---

## Architecture Overview

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                AI-Tools Unified Platform                     │
│                   (Port 11000)                               │
├─────────────────────────────────────────────────────────────┤
│  FastAPI Web Application (ai_web_app.py)                    │
│  ├── Chat Interface (Multi-model: OpenAI, Anthropic, Gemini)│
│  ├── Code Execution Engine (Python sandbox)                 │
│  ├── Agent Browser (Specialized AI agents)                  │
│  ├── GPU Monitoring (CUDA/PyTorch integration)              │
│  └── Cagent Integration Router                              │
└─────────────────────────────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│   TabbyML    │ │    Cagent    │ │  MCP Server  │
│  (Port 11001)│ │ (Port 11002) │ │ (Port 11003) │
├──────────────┤ ├──────────────┤ ├──────────────┤
│ Code         │ │ Agent        │ │ Tool         │
│ Completion   │ │ Orchestration│ │ Catalog      │
│ (StarCoder)  │ │ & Workflows  │ │ Management   │
└──────────────┘ └──────────────┘ └──────────────┘
        │               │               │
        └───────────────┴───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │   GPU Layer (NVIDIA CUDA)     │
        │   - RTX 3060 (Compute 8.6)    │
        │   - Tesla K80 (Compute 3.7)   │
        └───────────────────────────────┘
```

### Core Components

1. **ai_web_app.py** (Main Application)
   - FastAPI web server
   - Multi-provider AI chat (OpenAI, Anthropic, Gemini, local models)
   - Code execution sandbox
   - GPU monitoring and warmup
   - Template-based web UI
   - Specialized agent definitions

2. **cagent_integration.py** (Agent Router)
   - Code generation endpoints (Python, TypeScript, Go, Java, MCP)
   - Workflow orchestration (generation + CI pipeline)
   - PowerShell bridge to cagent agents
   - Agent discovery and health checks

3. **PortManager.psm1** (Port Management)
   - System-wide port registry (11000-12000 range)
   - Port allocation and conflict prevention
   - PowerShell-Python bridge functions

4. **Docker Services** (docker-compose.yml)
   - ai-toolkit: Main web application
   - tabbyml: Code completion service
   - cagent: Agent runtime
   - mcp-server: Tool catalog server

---

## Project Structure

```
AI-Tools/
├── ai_web_app.py              # Main FastAPI application (1025 lines)
├── cagent_integration.py      # Agent orchestration router (274 lines)
├── run_dev_server.py          # Development server launcher
├── requirements.txt           # Python dependencies
├── docker-compose.yml         # Multi-service orchestration
├── Dockerfile.ai-toolkit.rtx3060  # GPU-optimized container
│
├── templates/                 # Jinja2 web UI templates
│   ├── index.html            # Main web interface
│   └── cagent_section.html   # Agent UI components
│
├── cagent_examples/          # Agent YAML definitions (23 files)
│   ├── python_generator_agent.yaml
│   ├── typescript_generator_agent.yaml
│   ├── go_generator_agent.yaml
│   ├── java_generator_agent.yaml
│   ├── mcp_server_generator.yaml
│   ├── generator_ci_workflow.yaml
│   ├── coordinator_agent.yaml
│   ├── git_sync_agent.yaml
│   ├── docker_agent.yaml
│   ├── filesystem_agent.yaml
│   ├── tool_catalog.yaml
│   └── invoke_cagent.ps1     # PowerShell bridge
│
├── PortManager/              # Port management system
│   ├── PortManager.psm1      # PowerShell module
│   └── port-config.json      # Port registry
│
├── scripts/                  # Automation scripts
│   ├── Launch-AI-Tools.bat
│   ├── Set-API-Keys.ps1
│   ├── Set-Environment-Variables-System.ps1
│   └── Port-Manager.ps1
│
├── docs/                     # Documentation
│   ├── QUICK-START.md
│   ├── PORT-MANAGEMENT-README.md
│   ├── GPU-SETUP.md
│   ├── LOCAL-INFERENCE.md
│   └── optimize_build.md
│
├── config/                   # Configuration files
│   ├── cli-config.yml
│   ├── opencode-config.yml
│   └── tabby-token.txt
│
├── .github/                  # GitHub workflows & docs
│   ├── workflows/            # CI/CD pipelines
│   │   ├── portmanager-tests.yml
│   │   ├── docker-compose-validate.yml
│   │   └── powershell-lint.yml
│   ├── copilot-instructions.md
│   └── SPECIALIZED AGENTS.md
│
└── integrations/             # Helper scripts
    ├── python-port-helper.py
    └── node-port-helper.js
```

---

## Technology Stack

### Backend
- **Framework**: FastAPI 
- **Language**: Python 3.10+ (designed for 3.12+)
- **ASGI Server**: Uvicorn with uvloop and httptools
- **Templating**: Jinja2

### AI & ML
- **LLM Providers**: OpenAI, Anthropic Claude, Google Gemini
- **Local Inference**: PowerInfer, TurboSparse support
- **GPU**: PyTorch with CUDA 12.1
- **Code Completion**: TabbyML (StarCoder-1B)
- **Agent Framework**: Cagent (custom YAML-based orchestration)

### Infrastructure
- **Containerization**: Docker & Docker Compose
- **GPU Support**: NVIDIA CUDA 12.1 (RTX 3060, Tesla K80)
- **Package Management**: pip (moving to uv)
- **Port Management**: Custom PowerShell registry system

### Development Tools
- **Code Quality**: Black (line length 88), Flake8
- **Testing**: pytest, Playwright (E2E)
- **Linting**: PSScriptAnalyzer (PowerShell)
- **Version Control**: Git with GitHub Actions CI/CD

---

## Key Patterns & Conventions

### Code Style

#### Python
- **Formatter**: Black with line length 88
- **Linting**: Flake8 (ignore E203, W503, E501)
- **Async**: Use async/await for I/O operations
- **Type Hints**: Required for function signatures
- **Docstrings**: Module and public function documentation
- **Error Handling**: Comprehensive try-except with logging

#### PowerShell
- **Module Export**: Explicit Export-ModuleMember
- **Error Handling**: Use -ErrorAction Stop
- **Naming**: Verb-Noun convention (e.g., Invoke-ToolAgent)
- **Comments**: Inline documentation for complex logic

### Architecture Patterns

#### 1. Multi-Provider AI Pattern
```python
# Graceful degradation - app starts without all API keys
openai_client = None
anthropic_client = None
gemini_client = None

if openai_key:
    try:
        openai_client = openai.OpenAI(api_key=openai_key)
    except Exception as e:
        logger.error(f"Failed to initialize OpenAI: {e}")
```

#### 2. Template Directory Discovery
```python
# Support Docker (/app/templates) and local (./templates)
template_dirs = [
    "/app/templates",
    os.path.join(os.path.dirname(__file__), "templates"),
    "./templates",
]
template_dir = next((d for d in template_dirs if os.path.isdir(d)), None)
```

#### 3. PowerShell-Python Bridge
```python
# Invoke cagent agents via PowerShell module
ps_command = f"""
Import-Module "{ps_module_path}"
Invoke-ToolAgent -AgentFile '{agent_file}' -Input '{input_data}'
"""
result = subprocess.run(["powershell", "-NoProfile", "-Command", ps_command], ...)
```

#### 4. Port Registry System
- Preferred range: 11000-12000 (avoid conflicts with common ports)
- Migration from 3000-8000 to 11000-12000
- System-wide registry in port-registry.json
- PowerShell module for port allocation

#### 5. GPU Warmup on Startup
```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Warmup CUDA kernels at startup
    import torch
    if torch.cuda.is_available():
        _ = torch.zeros(1).cuda()
    yield
```

### Environment Configuration

#### Required Environment Variables
```bash
# API Keys (LLM providers)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GEMINI_API_KEY=AIza...

# Optional: Local inference
POWERINFER_HOST=http://localhost:11434
POWERINFER_MODEL=llama3.gguf
TURBOSPARSE_HOST=http://localhost:11435
TURBOSPARSE_MODEL=llama3.gguf

# Optional: PowerShell module path
PORT_MANAGER_MODULE=C:\Users\Keith Ransom\AI-Tools\PortManager\PortManager.psm1

# Docker optimizations
PYTHONUNBUFFERED=1
TOKENIZERS_PARALLELISM=false
PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
```

#### Configuration Files
- `.env` - API keys and secrets (gitignored)
- `.env.example` - Template for required variables
- `port-registry.json` - System-wide port allocations
- `config/cli-config.yml` - CLI tool configuration
- `config/tabby-token.txt` - TabbyML authentication

---

## Common Development Tasks

### Starting the Application

#### Option 1: Local Development (Recommended for development)
```bash
cd "C:\Users\Keith Ransom\AI-Tools"
python run_dev_server.py
# Runs on http://localhost:8000 with hot-reload
```

#### Option 2: Docker Compose (Recommended for production)
```bash
cd "C:\Users\Keith Ransom\AI-Tools"
docker compose up --build -d
# Main app on http://localhost:11000
```

### Testing Changes

```bash
# 1. Format code
black ai_web_app.py cagent_integration.py

# 2. Lint code
flake8 ai_web_app.py cagent_integration.py --max-line-length=88 --ignore=E203,W503,E501

# 3. Syntax check
python -m py_compile ai_web_app.py cagent_integration.py

# 4. Run tests (if available)
pytest tests/

# 5. Validate Docker config
docker compose -f docker-compose.yml config
```

### Adding a New AI Provider

1. Add client initialization in `ai_web_app.py`:
```python
newprovider_key = os.getenv("NEWPROVIDER_API_KEY")
newprovider_client = None
if newprovider_key:
    newprovider_client = NewProviderClient(api_key=newprovider_key)
```

2. Add model to `/api/models` endpoint
3. Add handler in `/api/chat` endpoint
4. Update `.env.example` with new variable
5. Document in README.md

### Adding a New Cagent Agent

1. Create YAML file in `cagent_examples/`:
```yaml
#!/usr/bin/env cagent run

agents:
  root:
    model: gpt
    description: My custom agent
    instruction: |
      Your instructions here
    toolsets:
      - type: filesystem
      - type: shell

models:
  gpt:
    provider: openai
    model: gpt-4o
```

2. Add to language map in `cagent_integration.py` (if language-specific)
3. Test via API:
```bash
curl -X POST http://localhost:11000/api/cagent/invoke \
  -H "Content-Type: application/json" \
  -d '{"agent_file":"my_agent.yaml","input":"test"}'
```

### Working with Ports

```powershell
# Find available port
Import-Module .\PortManager\PortManager.psm1
Find-AvailablePort -ApplicationName "MyApp"

# Register port
Register-Port -Port 11005 -ApplicationName "MyApp" -Description "My service"

# View registry
Show-PortRegistry
```

### Docker Workflow

```bash
# Stop services
docker compose down

# Make code changes
# Run quality checks (black, flake8)

# Rebuild and restart
docker compose up --build -d

# View logs
docker compose logs -f ai-toolkit

# Check health
curl http://localhost:11000/api/health
```

---

## API Endpoints Reference

### Main Application (ai_web_app.py)

#### GET /
- **Description**: Main web interface
- **Returns**: HTML page with chat, code execution, and agent browser

#### GET /api/health
- **Description**: Health check with detailed status
- **Returns**: 
  ```json
  {
    "status": "healthy",
    "gpu_status": "available",
    "apis_configured": {
      "openai": true,
      "anthropic": true,
      "gemini": true,
      "docker": true
    },
    "environment": {
      "template_dir": "/app/templates",
      "cwd": "/app"
    }
  }
  ```

#### GET /api/models
- **Description**: List available AI models
- **Returns**: Array of model objects with id, name, provider

#### POST /api/chat
- **Description**: Send message to AI model
- **Body**: `{"message": "string", "model": "gpt-4"}`
- **Returns**: `{"success": true, "response": "string", "model": "string"}`

#### POST /api/chat/stream
- **Description**: Stream chat response progressively
- **Body**: `{"message": "string", "model": "gpt-4"}`
- **Returns**: StreamingResponse (text/plain)

#### POST /api/execute-code
- **Description**: Execute Python code in sandbox
- **Body**: `{"code": "string", "language": "python"}`
- **Returns**: `{"success": true, "stdout": "string", "stderr": "string"}`

#### GET /api/gpu
- **Description**: GPU status and memory usage
- **Returns**: 
  ```json
  {
    "available": true,
    "device_name": "NVIDIA GeForce RTX 3060",
    "memory_allocated": "123.45 MB",
    "vram_total": "12288.00 MB"
  }
  ```

#### GET /api/agents
- **Description**: List specialized agent definitions
- **Returns**: Array of agent objects with role, purpose, skills

#### GET /api/cagent/examples
- **Description**: Discover cagent example YAML files
- **Returns**: 
  ```json
  {
    "examples": [
      {
        "path": "/path/to/agent.yaml",
        "name": "agent.yaml",
        "tag": "generator",
        "dry_run": true,
        "max_iterations": 5
      }
    ],
    "count": 23
  }
  ```

#### POST /api/cagent/run
- **Description**: Run cagent example with safety checks
- **Body**: `{"example_path": "/path/to/agent.yaml", "overrides": {}}`
- **Returns**: `{"success": true, "logs": "string"}`

### Cagent Integration (cagent_integration.py)

#### POST /api/cagent/generate
- **Description**: Generate code using language-specific agents
- **Body**: 
  ```json
  {
    "language": "python",
    "input": "Create a REST API endpoint",
    "options": {}
  }
  ```
- **Returns**: `{"success": true, "agent": "python_generator_agent.yaml", "response": "Generated code..."}`
- **Supported Languages**: python, typescript, go, java, mcp_server

#### POST /api/cagent/workflow
- **Description**: Run full generator + CI workflow
- **Body**: 
  ```json
  {
    "language": "python",
    "input": "Create CLI app",
    "run_ci": true,
    "options": {}
  }
  ```
- **Returns**: `{"success": true, "workflow": "generator_ci_workflow.yaml", "response": "Workflow output..."}`

#### POST /api/cagent/invoke
- **Description**: Invoke any cagent agent by filename
- **Body**: 
  ```json
  {
    "agent_file": "git_sync_agent.yaml",
    "input": "C:\\MyProject",
    "options": {}
  }
  ```
- **Returns**: `{"success": true, "agent": "git_sync_agent.yaml", "response": "Agent output..."}`

#### GET /api/cagent/agents
- **Description**: List all available cagent agents
- **Returns**: 
  ```json
  {
    "agents": [...],
    "count": 23,
    "categorized": {
      "generators": [...],
      "workflows": [...],
      "tools": [...],
      "coordinators": [...]
    }
  }
  ```

#### GET /api/cagent/health
- **Description**: Check cagent integration health
- **Returns**: 
  ```json
  {
    "healthy": true,
    "checks": {
      "powershell_module": true,
      "examples_directory": true,
      "cagent_service": true,
      "mcp_server": true
    }
  }
  ```

---

## Bi-Directional Chat ↔ Cagent Integration

**NEW (2025-01-17)**: The main chat window can now route messages directly to cagent agents!

### How It Works

Users can select "Cagent (AI Agent with Tools)" from the model dropdown in the main chat interface. When selected, messages are intelligently routed to appropriate cagent agents based on content.

### Intelligent Intent Detection

The system automatically detects user intent and routes to the best agent:

**Code Generation Requests** → Language-specific generator agents:
- Keywords: "generate", "create", "write", "build", "implement", "code"
- Language detection:
  - Python: "python", "py", "fastapi", "flask", "django"
  - TypeScript: "typescript", "ts", "react", "next.js", "angular"
  - Go: "golang", "go"
  - Java: "java", "spring", "maven"
  - MCP: "mcp", "model context protocol", "tool catalog"

**General Queries** → Coordinator agent:
- Non-code generation requests
- Orchestrates multiple agents as needed

### Example Usage

**In Main Chat (select "Cagent" model)**:
```
User: "Create a Python FastAPI endpoint that returns user data"

Cagent: 🤖 Cagent (python):

from fastapi import FastAPI, HTTPException
...
```

**Another Example**:
```
User: "Generate a React component for a login form"

Cagent: 🤖 Cagent (typescript):

import React, { useState } from 'react';
...
```

### Implementation Details

**Backend** (`ai_web_app.py:466-540`):
```python
async def route_to_cagent(message: str) -> dict:
    """Intelligent routing to cagent based on message content"""
    # Detect intent (code generation vs general query)
    # Detect programming language
    # Route to appropriate agent
    # Return formatted response
```

**Model Registration** (`/api/models`):
- New model ID: `"cagent"`
- Provider: `"cagent"`
- Always available (no API key required)

**Chat Endpoint** (`/api/chat`):
- Handles `model == "cagent"` case
- Calls `route_to_cagent(message)`
- Returns consistent response format

### Benefits

1. **Unified Interface**: No need to switch between chat and cagent sections
2. **Intelligent Routing**: System automatically picks the right agent
3. **Consistent UX**: Same chat interface for all AI interactions
4. **Tool Access**: Cagent agents have access to filesystem, shell, Docker, etc.
5. **Multi-Step Workflows**: Coordinator agent can orchestrate complex tasks

---

## Unified API Response Format

**IMPORTANT**: All API endpoints now use a consistent response format for better error handling and debugging.

### Success Response Format
```json
{
  "success": true,
  "response": "The actual data or output",
  "message": "Optional success message",
  // Additional context-specific fields
}
```

### Error Response Format
```json
{
  "success": false,
  "error": "Human-readable error message"
}
```

### Key Changes (2025-01-17)

**Backend Changes** (`cagent_integration.py`):
- **Before**: Raised `HTTPException` with `detail` field → FastAPI wrapped as `{"detail": "error"}`
- **After**: Returns consistent `{"success": bool, "response": str, "error": str}` format
- **Field Standardization**: Changed `output` → `response` to match main chat API
- **No More HTTPException**: Business logic errors returned as normal responses (200 OK with `success: false`)

**Frontend Changes** (both `index.html` and `cagent_section.html`):
- **Unified Handler**: Created `handleApiResponse(response)` function used by all API calls
- **Safe JSON Parsing**: All `response.json()` calls wrapped in try-catch
- **HTTP Status Handling**: Checks `response.ok` before parsing
- **Error Fallbacks**: Looks for `error`, `detail`, or `message` fields in any order
- **Preview on Error**: Shows first 200 chars of non-JSON responses for debugging

### Example Usage

**JavaScript (Frontend)**:
```javascript
// Both main chat and cagent section use this pattern
const response = await fetch('/api/cagent/generate', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ language: 'python', input: 'Create a hello world' })
});

const data = await handleApiResponse(response);

if (data.success) {
  console.log('Output:', data.response);
} else {
  console.error('Error:', data.error);
}
```

**Python (Backend)**:
```python
# Old pattern (AVOID)
if not result.get("success"):
    raise HTTPException(status_code=500, detail=result.get("error"))

# New pattern (USE THIS)
if not result.get("success"):
    return {
        "success": False,
        "error": result.get("error", "Operation failed")
    }

return {
    "success": True,
    "response": result.get("output"),
    "message": "Operation completed successfully"
}
```

### Benefits

1. **Consistent Error Handling**: Same pattern across all endpoints
2. **Better Debugging**: Non-JSON responses show preview instead of cryptic parse errors
3. **No Silent Failures**: All errors properly surfaced to user
4. **Type Safety**: Frontend can rely on `success` field being present
5. **Graceful Degradation**: Handles HTTP errors, JSON parse errors, and business logic errors uniformly

---

## Specialized Agents System

The application defines 6 specialized AI agents for different development tasks:

### 1. Python Developer Agent
- **Role**: python-dev
- **Activation**: Python code modifications, FastAPI endpoints, package management
- **Skills**: FastAPI, async/await, pytest, black/flake8, uv package manager

### 2. DevOps & Deployment Agent
- **Role**: devops
- **Activation**: Docker changes, deployment config, port allocation, containers
- **Skills**: Docker, docker-compose, port registry, environment config, health checks

### 3. Network Infrastructure Agent
- **Role**: network
- **Activation**: FortiGate/Meraki config, DNS management, network topology
- **Skills**: Fortinet ecosystem, Meraki API, Technitium DNS, network visualization
- **Context**: Multi-site enterprise (3,500+ locations)

### 4. Database & Data Agent
- **Role**: data
- **Activation**: Database schema, migrations, data processing, query optimization
- **Skills**: SQL, Alembic migrations, Pandas, analytics, backups

### 5. Testing & QA Agent
- **Role**: qa
- **Activation**: Test creation, quality checks, E2E testing, coverage analysis
- **Skills**: pytest, Playwright, coverage tools, mocking, regression testing

### 6. Documentation Agent
- **Role**: docs
- **Activation**: Documentation updates, API docs, user guides, ADRs
- **Skills**: Markdown, OpenAPI/Swagger, architecture diagrams, troubleshooting guides

---

## Cagent Agent Catalog

### Code Generators
- **python_generator_agent.yaml**: Generate Python code and FastAPI endpoints
- **typescript_generator_agent.yaml**: Generate TypeScript/React components
- **go_generator_agent.yaml**: Generate Go code and services
- **java_generator_agent.yaml**: Generate Java applications
- **mcp_server_generator.yaml**: Generate MCP (Model Context Protocol) servers

### Workflows
- **generator_ci_workflow.yaml**: Full generation + CI testing pipeline
- **monitor_workflow.yaml**: Monitoring and alerting workflow
- **tool_sync_agent.yaml**: Synchronize tool catalog

### Tool Agents
- **git_sync_agent.yaml**: Git repository synchronization
- **docker_agent.yaml**: Docker operations and management
- **filesystem_agent.yaml**: File system operations
- **curl_agent.yaml**: HTTP requests and API testing

### Coordinators
- **coordinator_agent.yaml**: Multi-agent orchestration (8369 lines)
- **ci_agent.yaml**: Continuous integration automation
- **planner.yaml**: Task planning and decomposition

### Utilities
- **agent.yaml**: Basic agent template
- **executor.yaml**: Task execution runtime
- **workflow.yaml**: Generic workflow template
- **tool_catalog.yaml**: Tool definitions and metadata (4385 lines)

---

## Docker Configuration

### Services

#### ai-toolkit (Port 11000)
- **Image**: Built from Dockerfile.ai-toolkit.rtx3060
- **Base**: nvidia/cuda:12.1.0-runtime-ubuntu22.04
- **Purpose**: Main web application with GPU support
- **Volumes**: 
  - `./config:/app/config`
  - `./workspace:/app/workspace`
  - `./:/workspace:rw`
  - `/var/run/docker.sock:/var/run/docker.sock`
- **GPU**: NVIDIA GPU with CUDA capabilities
- **Command**: Uvicorn with uvloop and httptools

#### tabbyml (Port 11001)
- **Image**: tabbyml/tabby:latest
- **Purpose**: AI code completion (StarCoder-1B model)
- **GPU**: CUDA acceleration
- **Volume**: tabby-data persistent volume

#### cagent (Port 11002)
- **Image**: cagent:latest
- **Purpose**: Agent runtime with tool integration
- **Volumes**: 
  - `./cagent_examples:/app/examples`
  - `./cagent_examples/tool_catalog.yaml:/app/tool_catalog.yaml`
- **Health Check**: http://localhost:8000/healthz

#### mcp-server (Port 11003)
- **Image**: ghcr.io/github/github-mcp-server:latest
- **Purpose**: GitHub Model Context Protocol server for tool integration
- **Environment Variables**: MCP_API_KEY, GITHUB_TOKEN
- **Health Check**: http://localhost:8000/health

### Build Optimizations (RTX 3060)

- **Multi-stage build**: Separate builder and runtime stages
- **Python venv**: Isolated dependencies in /opt/venv
- **Non-root user**: Security best practice (uid 1000)
- **CUDA config**: Optimized for Ampere architecture (Compute 8.6)
- **Memory management**: PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
- **Health checks**: 30s interval, 40s start period

---

## Port Allocation Strategy

### Port Registry System

The project uses a custom PowerShell-based port registry to prevent conflicts:

**Preferred Range**: 11000-12000 (reserved for this toolkit)

**Current Allocations**:
- 11000: ai-toolkit (main web app)
- 11001: tabbyml (code completion)
- 11002: cagent (agent runtime)
- 11003: mcp-server (tool catalog)
- 11004-11999: Available for new services

**Migration**: Applications in 3000-8000 range should migrate to 11000-12000

**Registry Location**: `./port-registry.json`

**PowerShell Functions**:
```powershell
Find-AvailablePort -ApplicationName "MyApp"
Register-Port -Port 11005 -ApplicationName "MyApp" -Description "..."
Show-PortRegistry
Get-UsedPorts
```

---

## Important Files & Their Purpose

### Core Application Files
- **ai_web_app.py** (1025 lines): Main FastAPI application with chat, execution, and agent management
- **cagent_integration.py** (274 lines): Router for code generation and agent orchestration
- **run_dev_server.py**: Development server launcher with environment checks

### Configuration
- **.env**: API keys and secrets (create from .env.example)
- **requirements.txt**: Python dependencies
- **docker-compose.yml**: Multi-service orchestration
- **port-registry.json**: System-wide port allocations

### PowerShell Modules
- **PortManager/PortManager.psm1**: Port management functions
- **cagent_examples/invoke_cagent.ps1**: PowerShell-cagent bridge

### Documentation
- **README.md**: Project overview and installation
- **QUICK-START.md**: Getting started guide
- **CAGENT_INTEGRATION.md**: Cagent API documentation
- **docs/GPU-SETUP.md**: GPU configuration guide
- **docs/PORT-MANAGEMENT-README.md**: Port system documentation

### Templates
- **templates/index.html**: Main web interface
- **templates/cagent_section.html**: Agent UI components

### Cursor IDE Configuration
- **cursor-rules.md**: Development standards and workflows
- **cursor-skills.md**: Agent skills reference
- **cursor-subagents.md**: Specialized agent definitions
- **.github/copilot-instructions.md**: AI assistant guidelines

---

## Development Workflow

### Golden Rules

❌ **NEVER**:
- Hardcode port numbers (use port-registry)
- Commit credentials (use .env)
- Skip quality checks (black, flake8, pytest)
- Deploy without rebuilding Docker images
- Use copy-paste for file operations (use tools)

✅ **ALWAYS**:
- Run quality checks in order: black → flake8 → compile
- Use async/await for I/O operations
- Register ports before using them
- Use environment variables for configuration
- Document API changes in docstrings
- Test Docker changes: down → change → checks → up --build

### Quality Check Sequence

```bash
# 1. Format code
black ai_web_app.py cagent_integration.py *.py

# 2. Lint code
flake8 . --max-line-length=88 --ignore=E203,W503,E501

# 3. Type check (optional)
python -m py_compile ai_web_app.py cagent_integration.py

# 4. Run tests
pytest tests/ -v

# 5. Validate Docker
docker compose -f docker-compose.yml config
```

### Docker Development Cycle

```bash
# 1. Stop containers
docker compose down

# 2. Make code changes
# ... edit files ...

# 3. Run quality checks
black *.py && flake8 . --max-line-length=88

# 4. Rebuild and start
docker compose up --build -d

# 5. Verify
docker compose logs -f ai-toolkit
curl http://localhost:11000/api/health
```

### Adding New Features

1. **Plan**: Define requirements and affected components
2. **Port**: Allocate port if needed (Find-AvailablePort)
3. **Code**: Implement with type hints and docstrings
4. **Test**: Write unit tests and integration tests
5. **Quality**: Run black → flake8 → compile
6. **Docker**: Test in containerized environment
7. **Document**: Update relevant .md files and docstrings
8. **PR**: Create pull request with description

---

## Troubleshooting Guide

### Common Issues

#### "Templates directory not found"
**Cause**: Running from wrong directory
**Solution**: 
```bash
cd "C:\Users\Keith Ransom\AI-Tools"
python run_dev_server.py
```

#### "API key not configured"
**Cause**: Missing or invalid .env file
**Solution**:
```bash
cp .env.example .env
notepad .env  # Add your API keys
```

#### "Port 11000 already in use"
**Cause**: Previous instance still running
**Solution**:
```bash
docker compose down
# Or use different port
python -m uvicorn ai_web_app:app --port 8001
```

#### "Docker socket not found"
**Cause**: Docker Desktop not running or permission issue
**Solution**:
```powershell
# Windows: Restart Docker Desktop
Stop-Service com.docker.service
Start-Service com.docker.service

# Or check Docker is running
docker ps
```

#### "CUDA not available"
**Cause**: GPU drivers not installed or Docker GPU support missing
**Solution**: See docs/GPU-SETUP.md for detailed instructions

#### "PowerShell module not found"
**Cause**: PORT_MANAGER_MODULE env var not set
**Solution**:
```powershell
$env:PORT_MANAGER_MODULE = "C:\Users\Keith Ransom\AI-Tools\PortManager\PortManager.psm1"
```

#### "Agent execution timeout"
**Cause**: Long-running agent operation (default 5min timeout)
**Solution**: Increase timeout in cagent_integration.py line 59

#### "MCP server failed to start"
**Cause**: Docker image `mcp-server:latest` not found
**Solution**: The correct image is `ghcr.io/github/github-mcp-server:latest`
```bash
# Pull the correct image
docker pull ghcr.io/github/github-mcp-server:latest

# Restart the service
docker compose up -d mcp-server
```

#### "JSON parse error" in cagent chat window
**Cause**: Server returning non-JSON response (HTML error page, etc.)
**Solution**: Updated templates/cagent_section.html with proper error handling
- All `response.json()` calls now have try-catch wrappers
- Shows helpful error messages with status code and response preview
- Check backend logs: `docker compose logs ai-toolkit`

### Health Check Commands

```bash
# Check application health
curl http://localhost:11000/api/health

# Check GPU status
curl http://localhost:11000/api/gpu

# Check cagent integration
curl http://localhost:11000/api/cagent/health

# Check Docker services
docker compose ps
docker compose logs ai-toolkit
docker compose logs cagent

# Check API keys loaded
python -c "import os; from dotenv import load_dotenv; load_dotenv(); print('OpenAI:', bool(os.getenv('OPENAI_API_KEY')))"
```

---

## CI/CD Pipelines

### GitHub Actions Workflows

#### portmanager-tests.yml
- **Trigger**: Push to main, PRs
- **Purpose**: Test PowerShell PortManager module
- **Steps**: PSScriptAnalyzer, Pester tests, normalize line endings

#### docker-compose-validate.yml
- **Trigger**: Push to main, PRs
- **Purpose**: Validate docker-compose.yml syntax
- **Steps**: docker compose config validation

#### powershell-lint.yml
- **Trigger**: Push to main, PRs
- **Purpose**: Lint PowerShell scripts
- **Steps**: PSScriptAnalyzer with settings from PSScriptAnalyzerSettings.psd1

#### ci-status-report.yml
- **Trigger**: Scheduled (daily)
- **Purpose**: Generate CI health report
- **Steps**: Aggregate test results, create summary

### Local CI Commands

```bash
# Validate docker-compose
docker compose -f docker-compose.yml config

# Lint PowerShell (if PSScriptAnalyzer installed)
pwsh -c "Invoke-ScriptAnalyzer -Path . -Recurse -Settings ./PSScriptAnalyzerSettings.psd1"

# Run Python tests
pytest tests/ -v --cov=.

# Full local CI simulation
./scripts/run-local-ci.sh  # If available
```

---

## Security Considerations

### Credentials Management
- **Never commit**: API keys, passwords, certificates, SSH keys
- **Use .env files**: Gitignored, loaded at runtime
- **Environment variables**: System-level for production
- **Docker secrets**: For sensitive data in containers (future improvement)

### Code Execution Sandbox
- **Timeout**: 30 seconds max for code execution
- **Restricted**: Python only (no shell access)
- **No persistence**: Execution in isolated subprocess
- **Logging**: All executed code is logged

### Docker Security
- **Non-root user**: Containers run as uid 1000 (appuser)
- **Read-only volumes**: Where possible
- **Limited capabilities**: No unnecessary privileges
- **Health checks**: Automatic restart on failure

### API Security
- **No authentication**: Currently open (add JWT/API keys for production)
- **Rate limiting**: Not implemented (future improvement)
- **Input validation**: Pydantic models validate all inputs
- **CORS**: Configure for production environments

---

## Performance Optimization

### GPU Utilization
- **Warmup**: CUDA kernels warmed up at startup
- **Memory management**: PYTORCH_CUDA_ALLOC_CONF tuned for RTX 3060
- **Batch processing**: Future improvement for multiple requests
- **Model caching**: Keep models loaded in memory

### Docker Build
- **Multi-stage**: Separate builder and runtime (smaller image)
- **Layer caching**: Requirements installed before code copy
- **Virtual environment**: Isolated dependencies
- **Minimal base**: Runtime image has only required packages

### Application Performance
- **Async I/O**: All I/O operations use async/await
- **Uvloop**: Faster event loop implementation
- **HTTPtools**: Faster HTTP parsing
- **Connection pooling**: Reuse HTTP connections to AI providers
- **Template caching**: Jinja2 templates cached in memory

### Database (Future)
- Currently no database (stateless application)
- Consider Redis for session storage
- PostgreSQL for persistent data (user prefs, history)

---

## Future Enhancements

### Planned Features
1. **Authentication & Authorization**: JWT tokens, API keys
2. **User Management**: Multi-user support, preferences
3. **Conversation History**: Persistent chat storage
4. **Model Fine-tuning**: Custom model training pipeline
5. **Advanced Monitoring**: Prometheus metrics, Grafana dashboards
6. **Webhook Integration**: GitHub, GitLab, CI/CD triggers
7. **Agent Scheduling**: Periodic agent runs (cron-like)
8. **Web Socket Support**: Real-time streaming for all models

### Infrastructure Improvements
1. **Kubernetes Support**: Helm charts for orchestration
2. **Load Balancing**: Multiple instances, auto-scaling
3. **Database Integration**: PostgreSQL for persistence
4. **Caching Layer**: Redis for sessions and temporary data
5. **CDN Integration**: Static asset delivery
6. **Backup & Recovery**: Automated backup procedures

### Code Quality
1. **Migrate to uv**: From pip to uv package manager
2. **Type Checking**: mypy integration
3. **API Versioning**: /v1/, /v2/ endpoints
4. **OpenAPI 3.1**: Enhanced API documentation
5. **Integration Tests**: Full E2E test suite
6. **Coverage Target**: 90%+ code coverage

---

## Project Context & Background

### Purpose
Unified AI development toolkit for:
- Multi-provider LLM integration (OpenAI, Anthropic, Gemini)
- GPU-accelerated local inference (PowerInfer, TurboSparse)
- Agent-based code generation and orchestration
- Network automation (Fortinet, Meraki, DNS)
- Enterprise multi-site management (3,500+ locations)

### Technology Choices
- **FastAPI**: High performance, async, automatic OpenAPI docs
- **Docker**: Reproducible environments, GPU support
- **PowerShell**: Windows automation, system integration
- **Cagent**: Flexible YAML-based agent definitions
- **PyTorch**: GPU acceleration, model inference

### Design Principles
1. **Modularity**: Each component is independent and replaceable
2. **Graceful Degradation**: App works without all API keys
3. **Developer Experience**: Fast iteration, hot reload, clear logs
4. **Production Ready**: Health checks, monitoring, error handling
5. **GPU Optimized**: Maximum performance from available hardware

---

## Contact & Resources

### Documentation
- **Project README**: /mnt/c/Users/Keith Ransom/AI-Tools/README.md
- **Quick Start**: /mnt/c/Users/Keith Ransom/AI-Tools/QUICK-START.md
- **Cagent Docs**: /mnt/c/Users/Keith Ransom/AI-Tools/CAGENT_INTEGRATION.md
- **GPU Setup**: /mnt/c/Users/Keith Ransom/AI-Tools/docs/GPU-SETUP.md

### Key Scripts
- **Port Management**: /mnt/c/Users/Keith Ransom/AI-Tools/scripts/Port-Manager.ps1
- **Environment Setup**: /mnt/c/Users/Keith Ransom/AI-Tools/scripts/Set-Environment-Variables-System.ps1
- **API Keys**: /mnt/c/Users/Keith Ransom/AI-Tools/scripts/Set-API-Keys.ps1

### External Resources
- **FastAPI Docs**: https://fastapi.tiangolo.com/
- **PyTorch CUDA**: https://pytorch.org/docs/stable/cuda.html
- **Docker Compose**: https://docs.docker.com/compose/
- **TabbyML**: https://tabby.tabbyml.com/

---

**Version**: 1.0
**Last Updated**: 2026-01-17
**Maintainer**: Keith Ransom
**Status**: Production Ready

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────┐
│                  AI-Tools Quick Reference                │
├─────────────────────────────────────────────────────────┤
│ Start Dev:     python run_dev_server.py                 │
│ Start Prod:    docker compose up --build -d             │
│ Health:        curl localhost:11000/api/health          │
│ Quality:       black . && flake8 . && python -m compile │
│ Port Find:     Find-AvailablePort -App "Name"           │
│ Docker Logs:   docker compose logs -f ai-toolkit        │
├─────────────────────────────────────────────────────────┤
│ Main App:      http://localhost:11000/                  │
│ API Docs:      http://localhost:11000/docs              │
│ TabbyML:       http://localhost:11001/                  │
│ Cagent:        http://localhost:11002/                  │
├─────────────────────────────────────────────────────────┤
│ Files:         ai_web_app.py (main)                     │
│                cagent_integration.py (agents)            │
│                docker-compose.yml (services)             │
│                .env (secrets)                            │
├─────────────────────────────────────────────────────────┤
│ Never:         Commit secrets, skip tests, hardcode ports│
│ Always:        Use .env, run black+flake8, rebuild Docker│
└─────────────────────────────────────────────────────────┘
```
