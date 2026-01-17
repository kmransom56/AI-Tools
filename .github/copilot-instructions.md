# AI Development Toolkit - Copilot Instructions

**Windows-first AI toolkit**: Multi-provider LLM web app with centralized port management, local inference support, and AI agent orchestration.

**Last Updated**: 2026-01-17  
**Version**: 1.2  

---

## 🎯 Project Overview

This is a **Windows-focused AI development toolkit** that provides:
1. **FastAPI web interface** ([ai_web_app.py](../ai_web_app.py)) for OpenAI/Anthropic/Gemini APIs + local inference (PowerInfer/TurboSparse)
2. **Port Manager** ([scripts/Port-Manager.ps1](../scripts/Port-Manager.ps1)) - Windows registry-based port allocation system
3. **cagent orchestration** - Run AI agent examples with safety constraints (dry-run enforced, max_iterations ≤ 10)
4. **Streaming responses** - Real-time chat completion streaming for responsive UX
5. **Automated installer** ([AI-Toolkit-Auto.ps1](../AI-Toolkit-Auto.ps1)) for AI tools (Void, Cursor, TabbyML, Continue.dev)
6. **Docker containerization** for reproducible deployments

---

## 🏗️ Architecture (The "Why")

### Three-Tier Design
- **Tier 1**: AI tools (Void/Cursor/Continue.dev) on Windows desktop
- **Tier 2**: Port Manager (Windows registry at `%USERPROFILE%\AI-Tools\port-registry.json`) prevents conflicts
- **Tier 3**: FastAPI app (default port 8000) → routes to OpenAI/Anthropic/Gemini APIs

**Why this design?** Running 5+ AI tools simultaneously creates port chaos. Port Manager provides single source of truth; FastAPI layer decouples tool configuration from API complexity.

### Critical Architectural Decisions

| Decision | Rationale | File Reference |
|----------|-----------|----------------|
| **Windows-only** | Relies on PowerShell 5.1+, `Get-NetTCPConnection`, WSL2 Docker | [AI-Toolkit-Auto.ps1](../AI-Toolkit-Auto.ps1#L28-L41) |
| **Port range 11000-12000** | Avoids web framework conflicts (3000-8000) | [port-registry.json](../port-registry.json) |
| **Single FastAPI file** | ~975 lines keeps it hackable | [ai_web_app.py](../ai_web_app.py) |
| **No API abstraction** | Each provider (OpenAI/Anthropic/Gemini/PowerInfer/TurboSparse) gets own client/handler | [ai_web_app.py](../ai_web_app.py#L86-L108) |
| **Docker-required** | Simplifies Python SDK dependencies (openai/anthropic/google-genai) | [docker-compose.yml](../docker-compose.yml) |
| **cagent dry-run enforced** | Security: All cagent runs execute with `CAGENT_DRY_RUN=1` and `max_iterations ≤ 10` | [ai_web_app.py](../ai_web_app.py#L452-L530) |
| **Streaming-first responses** | `/api/chat/stream` preferred for responsive UX; `/api/chat` for non-stream | [ai_web_app.py](../ai_web_app.py#L700-L800) |

---

## 🔧 Code Patterns (Use These EXACTLY)

### 1. API Provider Integration Pattern
**DO NOT abstract providers** - each gets its own client:

```python
# From ai_web_app.py lines 86-108
openai_client = openai.OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
anthropic_client = anthropic.Anthropic(api_key=os.getenv('ANTHROPIC_API_KEY'))
genai.configure(api_key=os.getenv('GEMINI_API_KEY'))

# Then call directly - routing happens in FastAPI layer only
response = openai_client.chat.completions.create(...)
```

### 2. Environment Variable Cascade (Three-Step Pattern)
See [AI-Toolkit-Auto.ps1](../AI-Toolkit-Auto.ps1#L52-L78):

```powershell
# 1. Check Windows environment variables first
$OPENAI = $env:OPENAI_API_KEY

# 2. Fall back to .env file if not set
if (-not $OPENAI) {
    $envFile = Join-Path $PSScriptRoot ".env"
    if (Test-Path $envFile) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^\s*OPENAI_API_KEY=(.*)$') {
                $OPENAI = $matches[1].Trim()
                $env:OPENAI_API_KEY = $OPENAI
            }
        }
    }
}

# 3. Prompt user if still missing (validation before Docker starts)
if (-not $OPENAI) {
    Write-Error "Missing OPENAI_API_KEY - set in .env or system environment"
    exit 1
}
```

**Never hardcode or commit keys.** Use [env.template](../env.template) as reference.

### 3. PowerShell Script Structure
All scripts follow this pattern ([AI-Toolkit-Auto.ps1](../AI-Toolkit-Auto.ps1#L1-L25)):

```powershell
# 1. Load Port Manager (dot-source, NOT Import-Module)
. $PSScriptRoot\scripts\Port-Manager.ps1

# 2. Setup logging early
Function Write-ToolLog {
    param([string]$message)
    "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) - $message" | Out-File -Append -FilePath $logPath
}

# 3. Admin check before Chocolatey/Docker operations
if (-not ([Security.Principal.WindowsPrincipal]...).IsInRole(...)) {
    Write-Error "Administrator privileges required"
    exit 1
}

# 4. Validate API keys before any network calls
```

### 4. Port Manager Usage Pattern
**CRITICAL**: Never hardcode port numbers!

```powershell
# PowerShell - Find and register
$port = Get-AvailablePort -ApplicationName "my-tool" -PreferredPort 11000
Register-Port -ApplicationName "my-tool" -Port $port -Description "My service"

# Python - Query existing
from integrations.python_port_helper import get_port
port = get_port('my-tool', 11000)
```

See [scripts/Port-Manager.ps1](../scripts/Port-Manager.ps1) for implementation.

### 5. Docker Deployment Pattern
From [docker-compose.yml](../docker-compose.yml#L6-L24):

```yaml
services:
  ai-toolkit:
    build:
      context: .
      dockerfile: Dockerfile.ai-toolkit
    ports:
      - "11000:8000"  # Host:Container (use Port Manager for host side)
    volumes:
      - ./:/workspace:rw  # Mount repo for cagent access
      - /var/run/docker.sock:/var/run/docker.sock  # Nested container support
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY}  # From .env or shell
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - GEMINI_API_KEY=${GEMINI_API_KEY}
    restart: unless-stopped
```

### 6. Local Inference Pattern (PowerInfer & TurboSparse)
**New**: HTTP and CLI fallback support for local LLMs. See [docs/LOCAL-INFERENCE.md](../docs/LOCAL-INFERENCE.md) for details.

**HTTP takes priority over CLI**:
```
Decision tree for PowerInfer:
├─ POWERINFER_HOST + POWERINFER_MODEL both set?
│  └─ YES → Use HTTP client (OpenAI-compatible, 30s timeout)
├─ POWERINFER_CLI + POWERINFER_MODEL both set?
│  └─ YES → Use subprocess runner (60s timeout)
└─ Neither configured? → HTTP 503 Service Unavailable

Same logic applies to TURBOSPARSE_*
```

```python
# From ai_web_app.py lines 69-78 (config), 820-835 (routing)
powerinfer_host = os.getenv("POWERINFER_HOST")     # e.g., http://localhost:11434
powerinfer_model = os.getenv("POWERINFER_MODEL")   # e.g., "meta-llama-3-8b-q4"
powerinfer_cli = os.getenv("POWERINFER_CLI")       # e.g., "powerinfer --model ... --prompt '{prompt}'"

# Routing in /api/chat:
elif request.model == "powerinfer":
    if powerinfer_host and powerinfer_model:
        # HTTP takes priority: OpenAI-compatible chat/completions endpoint
        content = await call_local_chat(powerinfer_host, powerinfer_model, request.message)
    elif powerinfer_cli and powerinfer_model:
        # CLI fallback: subprocess with {prompt} placeholder substitution
        content = run_cli_chat(powerinfer_cli, request.message)
    else:
        raise HTTPException(status_code=503, detail="PowerInfer not configured")
```

Set in `.env` (choose one):
```bash
# Option A: HTTP backend (preferred - requires running local server)
POWERINFER_HOST=http://localhost:11434
POWERINFER_MODEL=meta-llama-3-8b-q4

# Option B: CLI fallback (requires local binary installed)
POWERINFER_CLI=powerinfer --model "C:\\models\\llama3.gguf" --prompt "{prompt}" --n-predict 256
POWERINFER_MODEL=meta-llama-3-8b-q4

# Same options for TurboSparse
TURBOSPARSE_HOST=http://localhost:11435
TURBOSPARSE_MODEL=meta-llama-3-8b-q4
```

**Key behaviors**:
- `{prompt}` placeholder in CLI templates is mandatory
- HTTP timeout: 30s; CLI timeout: 60s
- Auto-normalizes HTTP host to `/v1/chat/completions` endpoint

### 7. cagent Orchestration Pattern
**New**: Discover and run cagent examples from the web UI with built-in safety enforcement.

```python
# From ai_web_app.py lines 445-570
@app.get("/api/cagent/examples")
async def cagent_examples():
    """Returns list of YAML files under */cagent/examples/* with metadata."""
    examples = find_cagent_examples()
    # Scans: /workspace, /app/workspace, /app, ./ for */cagent/examples/*.yml
    # Parses: tag, dry_run, max_iterations from YAML frontmatter
    return {"examples": examples, "count": len(examples)}

@app.post("/api/cagent/run")
async def cagent_run(req: CagentRunRequest):
    """Run YAML example with ENFORCED safety constraints.
    
    Key constraint: CAGENT_DRY_RUN=1 is ALWAYS set (cannot be disabled)
    Key constraint: max_iterations validated to be <= 10 before execution
    """
    # Validation layer: rejects max_iterations > 10
    if merged.get("max_iterations", 0) > 10:
        raise HTTPException(status_code=400, detail="max_iterations too large (max 10)")
    
    # Enforcement: Always set dry-run, UI cannot override
    env = {"CAGENT_DRY_RUN": "1"}
    
    # Container mount: repo root at /workspace, docker.sock for nested containers
    docker_client.containers.run(
        image="docker/cagent:latest",
        command=["run", example_relpath],
        environment=env,
        volumes={host_workspace: {"bind": "/workspace", "mode": "rw"},
                 "/var/run/docker.sock": {"bind": "/var/run/docker.sock", "mode": "rw"}}
    )
```

**Expected YAML structure** (`*/cagent/examples/my-task.yml`):
```yaml
tag: "example-agent-task"
dry_run: true
max_iterations: 5  # Must be <= 10
steps:
  - action: "execute"
    command: "echo 'Task running'"
```

**Troubleshooting**:
| Issue | Root Cause | Fix |
|-------|-----------|-----|
| "max_iterations too large" | YAML has `max_iterations > 10` | Reduce to ≤ 10 in YAML |
| Example not discoverable | File path doesn't match `*/cagent/examples/*` pattern | Ensure: `/cagent/examples/filename.yml` |
| Container fails to start | docker/cagent image not available | `docker pull docker/cagent:latest` |
| "/workspace not found" errors | Container-side mount failure | Check host path exists; verify `docker.sock` mounted |
| Unexpected file operations running | Dry-run not enforced | Verify logs show `CAGENT_DRY_RUN=1` (always set) |

### 8. Streaming Response Pattern
**New**: `/api/chat/stream` for real-time responses. Prefer this in UI.

```python
# From ai_web_app.py lines 649-760
@app.post("/api/chat/stream")
async def chat_stream(request: ChatRequest):
    """Stream responses from OpenAI/Anthropic/Gemini in real-time.
    
    Architecture:
    - Each provider has its own generator (openai_stream_gen, anthropic_stream_gen)
    - Falls back to chunking non-streaming response for local models
    - Catches exceptions and yields [stream error: ...] to client
    """
    try:
        if request.model.startswith("gpt"):
            return StreamingResponse(openai_stream_gen(), media_type="text/plain")
        # ... route to other providers similarly
    except Exception as e:
        logger.error(f"Stream chat error: {e}", exc_info=True)
        return JSONResponse(status_code=500, content={"error": str(e)})
```

**Frontend: Complete example for streaming responses**:
```javascript
// Modern async/await pattern with error handling
async function streamChatMessage(message, model) {
  const response = await fetch('/api/chat/stream', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message, model })
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(`Stream failed: ${error.error}`);
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let fullResponse = '';
  
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      
      const chunk = decoder.decode(value, { stream: true });
      fullResponse += chunk;
      
      // Update UI incrementally: append to display element
      document.getElementById('response').textContent += chunk;
      
      // Optional: auto-scroll to bottom
      document.getElementById('response').scrollTop = 
        document.getElementById('response').scrollHeight;
    }
  } catch (error) {
    console.error('Stream interrupted:', error);
    document.getElementById('response').textContent += 
      `\n\n[Stream error: ${error.message}]`;
  } finally {
    reader.releaseLock();
  }
  
  return fullResponse;
}

// Usage
document.getElementById('send-btn').addEventListener('click', async () => {
  const message = document.getElementById('message-input').value;
  const model = document.getElementById('model-select').value;
  
  document.getElementById('response').textContent = '';  // Clear previous
  try {
    await streamChatMessage(message, model);
  } catch (err) {
    console.error(err);
  }
});
```

**Key behaviors**:
- Streams real-time text chunks as provider generates them
- Falls back to 64-byte chunking for non-streaming models (local inference)
- Catches stream exceptions and yields `[stream error: ...]` so client sees error
- Preferred over `/api/chat` for responsive UX (large responses feel instant)
- Response type: `text/plain` (plain text chunks, not JSON)

### 9. Error Handling Pattern
**Consistent across all endpoints**: HTTP errors with `HTTPException`, business errors with response dicts.

```python
# From ai_web_app.py - Three error patterns

# Pattern 1: Configuration/HTTP-layer errors → HTTPException
if not openai_client:
    raise HTTPException(status_code=503, detail="OpenAI not configured")

# Pattern 2: Business logic errors → success/error dict
@app.post("/api/chat")
async def chat(request: ChatRequest):
    try:
        # ... call provider API
        return {"success": True, "response": text, "model": request.model}
    except Exception as e:
        logger.error(f"Chat error: {e}", exc_info=True)  # Always log
        return {"success": False, "error": str(e)}

# Pattern 3: Streaming errors → yield to client in stream
def openai_stream_gen():
    try:
        stream = openai_client.chat.completions.create(..., stream=True)
        for chunk in stream:
            yield chunk.choices[0].delta.content
    except Exception as e:
        yield f"\\n[stream error: {e}]\\n"  # Client sees error in stream
```

**Status codes** (HTTP errors only):
- `400`: Bad request (missing `{prompt}` in CLI, path traversal, invalid YAML)
- `404`: Not found (example file, template not found)
- `503`: Service unavailable (API key missing, backend not configured)
- `504`: Gateway timeout (local inference subprocess timeout)
- `500`: Server error (unexpected exception, container failure)

### 10. Validation Pattern (Pydantic models)
**All API inputs use Pydantic `BaseModel` for automatic validation**:

```python
# From ai_web_app.py lines 119-132
from pydantic import BaseModel

class ChatRequest(BaseModel):
    message: str
    model: str = "gpt-4"  # Default value

class CodeRequest(BaseModel):
    code: str
    language: str = "python"

class CagentRunRequest(BaseModel):
    example_path: str
    overrides: dict = {}  # Optional
```

**Validation happens automatically**:
- Missing required fields → `422 Unprocessable Entity`
- Type mismatch (e.g., `model: 123` instead of string) → `422 Unprocessable Entity`
- Extra fields → ignored by default
- FastAPI returns detailed error messages listing which fields failed

### 11. Async/Await Patterns
**All I/O operations are async**: HTTP calls, file reads, Docker operations.

```python
# Pattern 1: Async HTTP client (respects timeouts)
async with httpx.AsyncClient(timeout=30.0) as client:
    resp = await client.post(url, json=payload)
    # Safe: timeout kills stuck requests after 30s

# Pattern 2: Async FastAPI endpoints
@app.post("/api/chat/stream")
async def chat_stream(request: ChatRequest):  # Always async
    # Streaming response (generator)
    return StreamingResponse(generator_func())

@app.post("/api/chat")
async def chat(request: ChatRequest):  # Even if not awaiting, use async
    # Returns immediately (sync-friendly providers)
    response = openai_client.chat.completions.create(...)
    return {"success": True, "response": ...}

# Pattern 3: Mixing sync and async
def openai_stream_gen():  # Sync generator (can't be async)
    stream = openai_client.chat.completions.create(..., stream=True)
    for chunk in stream:
        yield chunk.choices[0].delta.content  # Yields synchronously

@app.post("/api/chat/stream")
async def chat_stream(request: ChatRequest):  # Async wrapper
    return StreamingResponse(openai_stream_gen())  # Pass sync generator
```

---

## 🔄 Development Workflows

### Starting the Dev Server

**Docker (recommended)**:
```powershell
docker compose down           # Stop existing
docker compose up --build -d  # Rebuild and start detached
docker compose logs -f        # Follow logs
```

**Direct Python** (fast iteration on ai_web_app.py):
```powershell
pip install openai anthropic google-generativeai fastapi uvicorn
python -m uvicorn ai_web_app:app --reload --port 8000
```

### Testing Workflow

**CI runs these automatically** (see [workflows/](workflows/)):
- [psscriptanalyzer.yml](workflows/psscriptanalyzer.yml) - Lint PowerShell scripts
- [docker-compose-validate.yml](workflows/docker-compose-validate.yml) - Validate compose syntax
- [portmanager-tests.yml](workflows/portmanager-tests.yml) - Test port registry operations

**Manual smoke test**:
```powershell
# Test API endpoint
$body = @{message = "Test"; model = "gpt-4"} | ConvertTo-Json
Invoke-WebRequest -Uri http://localhost:11000/api/chat `
  -Method POST -Headers @{"Content-Type"="application/json"} -Body $body
```

### Common Dev Tasks

| Task | Command |
|------|---------|
| Validate Docker | `docker compose config` |
| Lint PowerShell | `Invoke-ScriptAnalyzer -Path scripts/ -Recurse` |
| View port registry | `Get-Content $env:USERPROFILE\AI-Tools\port-registry.json` |
| Check running containers | `docker ps` |
| View FastAPI logs | `docker compose logs -f ai-toolkit` |
| Test streaming endpoint | See below |
| Discover cagent examples | `docker exec ai-toolkit find /workspace -path "*/cagent/examples/*.yml"` |

**Test streaming endpoint**:
```powershell
# PowerShell - stream chunked response
$uri = "http://localhost:11000/api/chat/stream"
$body = @{message="Hello"; model="gpt-4"} | ConvertTo-Json
$response = Invoke-WebRequest -Uri $uri -Method POST -Headers @{"Content-Type"="application/json"} -Body $body
Write-Output $response.Content  # Prints streamed text
```

---

## ⚠️ Critical Constraints (Don't Work Around These)

1. **Admin privileges required** for [AI-Toolkit-Auto.ps1](../AI-Toolkit-Auto.ps1) (installs Chocolatey, Docker)
2. **All three API keys** (OpenAI, Anthropic, Gemini) must exist before startup
3. **Docker Desktop must be running** on Windows (app polls with 60s timeout)
4. **Port Manager is source of truth** - query `port-registry.json`, don't hardcode ports
5. **Windows PowerShell 5.1+ or Core 7+** required (uses `Get-NetTCPConnection`)
6. **cagent dry-run enforced** - cannot be disabled; `max_iterations` capped at 10 for safety
7. **Local inference (PowerInfer/TurboSparse) optional** - HTTP takes priority over CLI if both configured

---

## 🚨 Common Pitfalls

## 🚨 Common Pitfalls

| ❌ Mistake | ✅ Fix | Why It Matters |
|-----------|--------|----------------|
| Hardcode port `8000` | Query Port Manager | Multiple tools conflict on same ports |
| Abstract API providers | Keep separate clients | Reduces complexity, easier debugging |
| Commit `.env` with keys | Use `env.template` | Security - keys exposed in repo |
| Run installer without admin | Use [Launch-AI-Tools-NoAdmin.ps1](../Launch-AI-Tools-NoAdmin.ps1) | Chocolatey/Docker need elevation |
| Skip `docker compose down` | Always stop before rebuild | Container state persists, causes confusion |
| Import Port-Manager.ps1 | Dot-source it: `. $PSScriptRoot\scripts\Port-Manager.ps1` | Import-Module creates isolation issues |
| Disable cagent dry-run | Never - enforced by code | Security - prevents accidental destructive runs |
| Set both PowerInfer HTTP + CLI | Use HTTP only | CLI is fallback if HTTP unavailable |

---

## 📦 Project Structure

```
AI-Tools/
├── ai_web_app.py              # FastAPI server (975 lines) - main app
├── AI-Toolkit-Auto.ps1        # Combined installer + launcher
├── docker-compose.yml         # Multi-service orchestration
├── Dockerfile.ai-toolkit      # Python app container
├── port-registry.json         # Port allocation registry (in %USERPROFILE%\AI-Tools)
├── env.template               # API key template (copy to .env)
├── scripts/
│   ├── Port-Manager.ps1       # Core port management functions
│   └── port-cli.ps1           # CLI wrapper for port operations
├── integrations/
│   ├── python-port-helper.py  # Python bindings for Port Manager
│   └── node-port-helper.js    # Node.js bindings for Port Manager
├── templates/
│   └── index.html             # Web UI for chat interface
└── .github/workflows/
    ├── psscriptanalyzer.yml   # PowerShell linting
    ├── docker-compose-validate.yml
    └── portmanager-tests.yml  # Port Manager tests
```

---

## 🎯 Agent Definitions

The FastAPI app includes agent definitions at [ai_web_app.py](../ai_web_app.py#L200-L380) for frontend consumption. These agents represent different responsibilities in the codebase:

1. **Python Developer Agent** - FastAPI/Python code modifications
2. **DevOps & Deployment Agent** - Docker, port allocation, CI/CD
3. **Network Infrastructure Agent** - (Reserved for future network features)
4. **Database & Data Agent** - (Reserved for future data features)
5. **Testing & QA Agent** - Tests, quality checks, CI workflows
6. **Documentation Agent** - READMEs, inline docs, setup guides

**Note**: These are **informational structures** exposed via `/api/agents` endpoint, not actual separate codebases.

---

## 🔍 Data Flows

### API Request Flow
```
Browser → http://localhost:11000/api/chat
  ↓
FastAPI (ai_web_app.py)
  ↓
Route by model param:
  - "gpt-4" → openai_client.chat.completions.create()
  - "claude-3" → anthropic_client.messages.create()
  - "gemini-pro" → genai.GenerativeModel().generate_content()
  ↓
External API (OpenAI/Anthropic/Google)
  ↓
Stream response back to browser
```

### Port Allocation Flow
```
Script needs port
  ↓
Get-AvailablePort -ApplicationName "app" -PreferredPort 11000
  ↓
Check %USERPROFILE%\AI-Tools\port-registry.json
  ↓
If available: Register-Port -ApplicationName "app" -Port 11000
  ↓
Return port to script
```

### Docker Container Startup
```
docker compose up --build
  ↓
Read .env for API keys (or $env:* variables)
  ↓
Build Dockerfile.ai-toolkit (Python 3.11 + deps)
  ↓
Mount volumes: ./:/workspace, docker.sock
  ↓
Start FastAPI on container port 8000
  ↓
Expose on host port 11000 (Port Manager registered)
```

---

## 🛠️ Extension Points

### Adding a New AI Provider

1. **Add client initialization** in [ai_web_app.py](../ai_web_app.py#L86-L108):
```python
newprovider_key = os.getenv("NEWPROVIDER_API_KEY")
newprovider_client = None
if newprovider_key:
    newprovider_client = NewProvider(api_key=newprovider_key)
```

2. **Add routing logic** in `/api/chat` endpoint (around line 400):
```python
elif "newmodel" in model_name.lower():
    if not newprovider_client:
        raise HTTPException(status_code=503, detail="NewProvider not configured")
    response = newprovider_client.chat(...)
```

3. **Update environment**:
   - Add `NEWPROVIDER_API_KEY` to [env.template](../env.template)
   - Add to [docker-compose.yml](../docker-compose.yml) environment section
   - Update [AI-Toolkit-Auto.ps1](../AI-Toolkit-Auto.ps1#L52-L78) validation

### Adding a New Tool to Installer

Edit [AI-Toolkit-Auto.ps1](../AI-Toolkit-Auto.ps1):

1. **Allocate port** (around line 150):
```powershell
$newToolPort = Get-AvailablePort -ApplicationName "newtool" -PreferredPort 11005
Register-Port -ApplicationName "newtool" -Port $newToolPort -Description "New Tool Service"
```

2. **Add Chocolatey install** (around line 200):
```powershell
choco install newtool -y
```

3. **Add to docker-compose.yml** (if containerized):
```yaml
newtool:
  image: newtool/newtool:latest
  ports:
    - "${NEWTOOL_PORT:-11005}:8080"
```

---

## 📖 References

### Key Files to Read First
1. [README.md](../README.md) - Quick start and overview
2. [ai_web_app.py](../ai_web_app.py) - Main application logic
3. [scripts/Port-Manager.ps1](../scripts/Port-Manager.ps1) - Port management API
4. [docker-compose.yml](../docker-compose.yml) - Service definitions
5. [AI-Toolkit-Auto.ps1](../AI-Toolkit-Auto.ps1) - Installation flow

### Documentation
- [docs/PORT-MANAGEMENT-README.md](../docs/PORT-MANAGEMENT-README.md) - Port Manager deep dive
- [docs/RUNNING-WINDOWS.md](../docs/RUNNING-WINDOWS.md) - Windows service setup (NSSM)
- [docs/GPU-SETUP.md](../docs/GPU-SETUP.md) - NVIDIA Container Toolkit setup
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines

### CI/CD Workflows
- All workflows require branch prefixes: `feat/`, `fix/`, `hotfix/`, `chore/`, `docs/`, `release/`
- PSScriptAnalyzer enforces PowerShell best practices
- Docker compose validation catches syntax errors before deployment

---

## ✅ Quick Checklist for Changes

### Before Committing
- [ ] All API keys in `.env` or environment variables (never committed)
- [ ] Port Manager queries used (no hardcoded ports)
- [ ] PowerShell scripts dot-source Port-Manager.ps1
- [ ] Docker: `docker compose config` validates successfully
- [ ] PowerShell: `Invoke-ScriptAnalyzer` passes (or suppressed with reason)

### Before Deploying
- [ ] `.env` file exists with all three API keys
- [ ] Docker Desktop running (Windows)
- [ ] Port registry initialized: `Test-Path $env:USERPROFILE\AI-Tools\port-registry.json`
- [ ] Admin privileges if running [AI-Toolkit-Auto.ps1](../AI-Toolkit-Auto.ps1)

### When Adding Features
- [ ] Follow existing patterns (see Code Patterns section)
- [ ] Don't abstract API providers unless truly necessary
- [ ] Update [env.template](../env.template) for new environment variables
- [ ] Document in relevant README or inline comments

---

## 🎓 Learning Resources

**PowerShell Port Manager**:
- Read [scripts/Port-Manager.ps1](../scripts/Port-Manager.ps1) functions: `Get-AvailablePort`, `Register-Port`, `Get-RegisteredPort`
- Example usage: [AI-Toolkit-Auto.ps1](../AI-Toolkit-Auto.ps1#L150-L180)

**FastAPI Multi-Provider Pattern**:
- Client initialization: [ai_web_app.py](../ai_web_app.py#L86-L108)
- Routing logic: Search for `elif` chains in `/api/chat` endpoint
- No shared interface - each provider called directly

**Docker Multi-Service Setup**:
- Service definitions: [docker-compose.yml](../docker-compose.yml)
- Volume mounts for nested containers: `/var/run/docker.sock`
- Environment variable substitution: `${OPENAI_API_KEY}`

---

## 🚀 Getting Started (Developer Quick Start)

```powershell
# 1. Clone and navigate
cd c:\Users\south\AI-Tools

# 2. Create .env from template
Copy-Item env.template .env
notepad .env  # Add your API keys

# 3. Validate Docker setup
docker compose config

# 4. Start services
docker compose up --build -d

# 5. Check logs
docker compose logs -f

# 6. Test endpoint
$body = @{message="Hello"; model="gpt-4"} | ConvertTo-Json
Invoke-WebRequest -Uri http://localhost:11000/api/chat -Method POST `
  -Headers @{"Content-Type"="application/json"} -Body $body

# 7. View in browser
Start-Process http://localhost:11000
```

---

**Status**: Production Ready  
**Last Validated**: 2026-01-17  
**Maintained By**: AI Development Team

Questions or issues? Check [CONTRIBUTING.md](../CONTRIBUTING.md) or open an issue.
