# AI Development Toolkit - AI Coding Agent Instructions

## Project Overview
Multi-tool AI development toolkit consisting of:
1. **FastAPI Web Application** ([ai_web_app.py](ai_web_app.py)): Web interface for interacting with OpenAI, Anthropic, and Google Gemini APIs
2. **Port Management System** ([PortManager/PortManager.psm1](PortManager/PortManager.psm1)): System-wide port registry preventing conflicts between AI tools
3. **Installation/Launch System** ([AI-Toolkit-Auto.ps1](AI-Toolkit-Auto.ps1)): Automated installer for AI development tools (Void, TabbyML, Continue.dev, Cursor, etc.)

**Critical**: This is a Windows-first toolkit requiring PowerShell and Windows-specific integrations.

## Architecture

### Three-Tier System
```
AI Tools (Void/Cursor/Continue.dev) → Port Manager → AI Web App (port 8000) → AI APIs
                                           ↓
                          Port Registry (port-registry.json)
```

### FastAPI Web Application ([ai_web_app.py](ai_web_app.py))
- Single-file FastAPI server on port 8000 (default, configurable via Port Manager)
- Supports multiple AI providers: OpenAI (GPT-4), Anthropic (Claude), Google (Gemini), Shell-GPT
- Frontend: [templates/index.html](templates/index.html) with embedded CSS/JS (no build system)
- Docker deployment via [docker-compose.yml](docker-compose.yml) and [Dockerfile.ai-toolkit](Dockerfile.ai-toolkit)

**API Endpoints**:
- `GET /` - Serve web UI
- `GET /api/models` - List available AI models
- `POST /api/chat` - Send message to selected model (OpenAI/Anthropic/Gemini/sgpt)
- `POST /api/execute-code` - Execute Python code in container

### Port Management System
**PowerShell Module**: [PortManager/PortManager.psm1](PortManager/PortManager.psm1)
- **Purpose**: System-wide port registry preventing conflicts between AI tools
- **Registry Location**: `%USERPROFILE%\AI-Tools\port-registry.json`
- **Port Ranges**: 11000-12000 (preferred), 3000-8000 (migration targets)

**Key Functions**:
```powershell
Get-AvailablePort -ApplicationName "MyApp" [-PreferredPort 11000]
Register-Port -Port 11000 -ApplicationName "MyApp" -Description "..."
Get-UsedPorts  # Scans 0-65535 via netstat + Get-NetTCPConnection
Get-ApplicationPort -ApplicationName "MyApp"
```

**CLI Wrapper**: [scripts/port-cli.ps1](scripts/port-cli.ps1)
```powershell
port-cli.ps1 get -ApplicationName "MyApp" [-Port 11000]
port-cli.ps1 register -Port 11000 -ApplicationName "MyApp"
port-cli.ps1 list
port-cli.ps1 check -ApplicationName "MyApp"
port-cli.ps1 migrate  # List ports in 3000-8000 range
```

**Integration Helpers**:
- Python: [integrations/python-port-helper.py](integrations/python-port-helper.py) - `get_port('app-name', preferred_port=11000)`
- Node.js: [integrations/node-port-helper.js](integrations/node-port-helper.js) - `getPort('app-name', 11000)`
- Setup: [integrations/setup-port-env.ps1](integrations/setup-port-env.ps1) - Adds Port Manager to PowerShell profile

### Installation/Launch System ([AI-Toolkit-Auto.ps1](AI-Toolkit-Auto.ps1))
**500+ line PowerShell orchestrator** for automated installation and launch:
1. Admin check (required for Chocolatey installs)
2. API key validation (from `.env` or environment variables)
3. Dependency installation via Chocolatey (Node.js, Python, Git, Docker, VS Code)
4. Docker Desktop startup and verification
5. AI tool installation (Void, TabbyML, Continue.dev, Cursor, Copilot, OpenCode, ChatGPT CLIs)
6. Port management integration

**Non-Admin Alternative**: [Launch-AI-Tools-NoAdmin.ps1](Launch-AI-Tools-NoAdmin.ps1) - Launches web app without installing dependencies

## Development Workflows

### Starting the Web Application
**Docker (Recommended)**:
```powershell
docker-compose up --build
# Access at http://localhost:8000
```

**Direct Python**:
```powershell
python ai_web_app.py
# or with uvicorn
uvicorn ai_web_app:app --reload --port 8000
```

### Full Installation and Launch
```powershell
# Run as Administrator
.\AI-Toolkit-Auto.ps1
```

### Port Management Setup
```powershell
# One-time setup (adds to PowerShell profile)
.\integrations\setup-port-env.ps1

# Usage in scripts
Import-Module "$env:PORT_MANAGER_MODULE" -Force
$port = Get-AvailablePort -ApplicationName "my-ai-tool"
```

### API Key Configuration
**Option 1 - Environment Variables** (permanent):
```powershell
# Use Windows System Properties > Environment Variables
# or run:
.\scripts\Set-Environment-Variables-System.ps1
```

**Option 2 - .env File** (project-local):
```bash
cp env.template .env
# Edit .env with your keys
```

**Option 3 - Session Variables** (temporary):
```powershell
.\scripts\Set-API-Keys.ps1
```

## Project-Specific Patterns

### AI Provider Integration Pattern ([ai_web_app.py](ai_web_app.py#L64-L130))
Each AI provider has dedicated client initialization and request handling:
```python
# OpenAI
openai_client = openai.OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
response = openai_client.chat.completions.create(model="gpt-4", messages=[...])

# Anthropic
anthropic_client = anthropic.Anthropic(api_key=os.getenv('ANTHROPIC_API_KEY'))
response = anthropic_client.messages.create(model="claude-3-5-sonnet-20241022", ...)

# Google Gemini
genai.configure(api_key=os.getenv('GEMINI_API_KEY'))
model = genai.GenerativeModel('gemini-pro')
response = model.generate_content(message)

# Shell-GPT (subprocess)
subprocess.run(["sgpt", message], capture_output=True, timeout=60)
```

### Port Scanning Pattern ([PortManager/PortManager.psm1](PortManager/PortManager.psm1#L35-L62))
Combines two methods for complete port enumeration:
```powershell
# Method 1: PowerShell cmdlet (faster but may miss some)
Get-NetTCPConnection -State Listen | Select-Object -ExpandProperty LocalPort -Unique

# Method 2: netstat parsing (comprehensive)
netstat -ano | Select-String "LISTENING" | Extract port numbers

# Result: Deduplicated union of both methods
```

### PowerShell Module Loading Pattern
All PowerShell scripts use this pattern:
```powershell
$portManagerPath = Join-Path $PSScriptRoot "scripts\Port-Manager.ps1"
if (Test-Path $portManagerPath) {
    . $portManagerPath  # Dot-source the script
}
```

### Docker Environment Variable Injection ([docker-compose.yml](docker-compose.yml#L13-L16))
AI API keys are injected from host environment or `.env` file:
```yaml
environment:
  - OPENAI_API_KEY=${OPENAI_API_KEY}
  - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
  - GEMINI_API_KEY=${GEMINI_API_KEY}
```

## Critical Constraints

1. **Windows Only**: Port Manager relies on Windows `netstat`, PowerShell cmdlets, and path conventions
2. **Admin Required for Installation**: [AI-Toolkit-Auto.ps1](AI-Toolkit-Auto.ps1) installs software via Chocolatey (requires admin)
3. **API Keys Required**: All three keys (OpenAI, Anthropic, Gemini) validated before startup
4. **Port Range Convention**: Always use 11000-12000 for new tools (avoid 3000-8000 migration range)
5. **PowerShell 5.1+**: Port Manager requires Windows PowerShell 5.1 or PowerShell Core 7+
6. **Docker Desktop**: Required for containerized deployment, must have WSL2 backend enabled

## Integration Points

### Cross-Tool Port Resolution
Any AI tool can query port registry:
- **PowerShell**: `Import-Module PortManager; Get-ApplicationPort -ApplicationName "ai-toolkit"`
- **Python**: `from integrations.python_port_helper import get_port; port = get_port('ai-toolkit')`
- **Node.js**: `const {getPort} = require('./integrations/node-port-helper'); const port = getPort('ai-toolkit');`
- **Direct JSON**: Read `%USERPROFILE%\AI-Tools\port-registry.json`

### AI Provider Communication Flow
```
Browser → FastAPI (ai_web_app.py) → AI Provider SDK → External API
         ↓
   OpenAI/Anthropic/Gemini client libraries handle auth, retries, streaming
```

### Installation Dependencies
[AI-Toolkit-Auto.ps1](AI-Toolkit-Auto.ps1) orchestrates:
1. Chocolatey package manager (`choco install ...`)
2. Docker Desktop (`Start-Process "Docker Desktop"`), wait for daemon
3. Python packages (`pip install openai anthropic google-generativeai`)
4. VS Code extensions (`code --install-extension ...`)
5. PowerShell modules (Port Manager → profile)

## Common Issues & Solutions

**Problem**: Port conflicts with existing services (e.g., 8000 already in use)
**Solution**: Use Port Manager to auto-assign: `Get-AvailablePort -ApplicationName "ai-toolkit"`

**Problem**: API keys not detected after setting in `.env`
**Solution**: Source order is: environment vars → `.env` file → prompt. Verify `.env` format (no quotes around keys)

**Problem**: Docker Desktop not starting automatically
**Solution**: [AI-Toolkit-Auto.ps1](AI-Toolkit-Auto.ps1#L240-L260) has 60-second timeout + retry logic. Check Docker Desktop settings → "Start Docker Desktop when you log in"

**Problem**: PowerShell module not found after setup
**Solution**: Run `.\integrations\setup-port-env.ps1` to add to PowerShell profile, or set `$env:PORT_MANAGER_MODULE` manually

**Problem**: Chocolatey install fails (execution policy)
**Solution**: Run `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` before [AI-Toolkit-Auto.ps1](AI-Toolkit-Auto.ps1)

**Problem**: AI tool returns timeout on first request
**Solution**: Model initialization takes time. FastAPI timeout is 60s ([ai_web_app.py](ai_web_app.py#L107)), increase if needed

## File Organization

**Core Application**:
- [ai_web_app.py](ai_web_app.py): FastAPI server with AI provider integrations
- [templates/index.html](templates/index.html): Single-page web UI

**Port Management**:
- [PortManager/PortManager.psm1](PortManager/PortManager.psm1): PowerShell module with core functions
- [scripts/port-cli.ps1](scripts/port-cli.ps1): CLI wrapper for cross-tool usage
- [integrations/python-port-helper.py](integrations/python-port-helper.py): Python binding
- [integrations/node-port-helper.js](integrations/node-port-helper.js): Node.js binding
- [integrations/setup-port-env.ps1](integrations/setup-port-env.ps1): One-time setup script

**Installation**:
- [AI-Toolkit-Auto.ps1](AI-Toolkit-Auto.ps1): Main installer and launcher (admin required)
- [Launch-AI-Tools-NoAdmin.ps1](Launch-AI-Tools-NoAdmin.ps1): Launch-only script (no installs)
- [scripts/Set-API-Keys.ps1](scripts/Set-API-Keys.ps1): Interactive API key setter

**Configuration**:
- [env.template](env.template): Template for `.env` file with API keys
- [docker-compose.yml](docker-compose.yml): Docker deployment configuration
- [config/cli-config.yml](config/cli-config.yml): CLI tool configurations
- [PortManager/port-config.json](PortManager/port-config.json): Port manager configuration

**Documentation**:
- [README.md](README.md): High-level overview and prerequisites
- [docs/PORT-MANAGEMENT-README.md](docs/PORT-MANAGEMENT-README.md): Port system details
- [docs/PORT-MANAGEMENT-QUICK-START.md](docs/PORT-MANAGEMENT-QUICK-START.md): Integration examples
- [docs/AI-TOOLKIT-README.md](docs/AI-TOOLKIT-README.md): AI toolkit details
- [docs/GEMINI.md](docs/GEMINI.md): Gemini API integration guide

## Testing Patterns

### Test AI Provider Connectivity
```powershell
# Start web app
python ai_web_app.py

# Test OpenAI
curl -X POST http://localhost:8000/api/chat -H "Content-Type: application/json" `
  -d '{"message":"Hello","model":"gpt-4"}'

# Test Claude
curl -X POST http://localhost:8000/api/chat -H "Content-Type: application/json" `
  -d '{"message":"Hello","model":"claude-3-5-sonnet-20241022"}'

# Test Gemini
curl -X POST http://localhost:8000/api/chat -H "Content-Type: application/json" `
  -d '{"message":"Hello","model":"gemini-pro"}'
```

### Test Port Manager
```powershell
Import-Module .\PortManager\PortManager.psm1 -Force

# Get available port
$port = Get-AvailablePort -ApplicationName "test-app"
Write-Host "Assigned port: $port"

# Check port is registered
$registry = Get-PortRegistry
$registry.RegisteredPorts

# Verify port is not in use
$usedPorts = Get-UsedPorts
$usedPorts -contains $port  # Should be False
```

### Test Docker Deployment
```powershell
docker-compose up --build
# Wait for container to start (check logs)
docker-compose logs -f ai-toolkit

# Test API
curl http://localhost:8000/api/models
```
