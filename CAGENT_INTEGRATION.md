# Cagent Integration with AI-Tools Web Application

## Overview

This integration connects all cagent functionality to the main AI-Tools web application running at `http://localhost:11000/`. It provides a complete code generation, testing, and agent orchestration platform accessible through both REST API and web UI.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   http://localhost:11000/                    │
│                  AI-Tools Web Application                    │
│                      (FastAPI)                               │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ├─ /api/cagent/generate
                        ├─ /api/cagent/workflow
                        ├─ /api/cagent/invoke
                        ├─ /api/cagent/agents
                        └─ /api/cagent/health
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              cagent_integration.py (Router)                  │
│         PowerShell → Invoke-ToolAgent → cagent               │
└───────────────────────┬─────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
        ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  Generator   │ │   Workflow   │ │    Tools     │
│   Agents     │ │   Agents     │ │   Agents     │
├──────────────┤ ├──────────────┤ ├──────────────┤
│ • Python     │ │ • Gen+CI     │ │ • Git Sync   │
│ • TypeScript │ │ • Monitor    │ │ • Docker     │
│ • Go         │ │ • Tool Sync  │ │ • Filesystem │
│ • Java       │ │              │ │ • Curl       │
│ • MCP Server │ │              │ │              │
└──────────────┘ └──────────────┘ └──────────────┘
        │               │               │
        └───────────────┴───────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              Docker Services (docker-compose)                │
├─────────────────────────────────────────────────────────────┤
│ • cagent (port 11002)      - Main agent runtime             │
│ • mcp-server (port 11003)  - Tool catalog server            │
│ • ai-toolkit (port 11000)  - Web application                │
│ • tabbyml (port 11001)     - Code completion                │
└─────────────────────────────────────────────────────────────┘
```

## API Endpoints

### 1. Code Generation

**POST** `/api/cagent/generate`

Generate code using language-specific agents.

**Request:**

```json
{
  "language": "python",
  "input": "Create a REST API endpoint that returns user data",
  "options": {}
}
```

**Response:**

```json
{
  "success": true,
  "language": "python",
  "agent": "python_generator_agent.yaml",
  "output": "Generated code and file path...",
  "message": "Code generated successfully"
}
```

**Supported Languages:**

- `python` → `python_generator_agent.yaml`
- `typescript` → `typescript_generator_agent.yaml`
- `go` → `go_generator_agent.yaml`
- `java` → `java_generator_agent.yaml`
- `mcp_server` → `mcp_server_generator.yaml`

---

### 2. Full Workflow (Generation + CI)

**POST** `/api/cagent/workflow`

Run the complete generator → CI testing pipeline.

**Request:**

```json
{
  "language": "python",
  "input": "Create a CLI todo-list app",
  "run_ci": true,
  "options": {}
}
```

**Response:**

```json
{
  "success": true,
  "language": "python",
  "workflow": "generator_ci_workflow.yaml",
  "output": "Generation and test results...",
  "message": "Workflow completed successfully"
}
```

---

### 3. Generic Agent Invocation

**POST** `/api/cagent/invoke`

Invoke any cagent agent by filename.

**Request:**

```json
{
  "agent_file": "git_sync_agent.yaml",
  "input": "Sync repository at C:\\MyProject",
  "options": {}
}
```

**Response:**

```json
{
  "success": true,
  "agent": "git_sync_agent.yaml",
  "output": "Agent execution output...",
  "message": "Agent executed successfully"
}
```

---

### 4. List Available Agents

**GET** `/api/cagent/agents`

Get all available agents categorized by type.

**Response:**

```json
{
  "agents": [...],
  "count": 15,
  "categorized": {
    "generators": [...],
    "workflows": [...],
    "tools": [...],
    "coordinators": [...],
    "other": [...]
  }
}
```

---

### 5. Health Check

**GET** `/api/cagent/health`

Check integration health status.

**Response:**

```json
{
  "healthy": true,
  "checks": {
    "powershell_module": true,
    "examples_directory": true,
    "cagent_service": true,
    "mcp_server": true
  },
  "message": "All systems operational"
}
```

## Web UI Integration

The cagent functionality is integrated into the main web interface at `http://localhost:11000/`.

### Features:

1. **Code Generation Panel**
   - Language selector (Python, TypeScript, Go, Java, MCP Server)
   - Description textarea
   - "Generate Code" button
   - "Generate + Test" button (full workflow)
   - Real-time output display

2. **Agent Browser**
   - Grid view of all available agents
   - Categorized by type (generators, workflows, tools, coordinators)
   - Click to select and invoke
   - Custom input panel for each agent

3. **Real-time Feedback**
   - Progress indicators
   - Success/error messages
   - Formatted output display

## Usage Examples

### Example 1: Generate Python Code via API

```bash
curl -X POST http://localhost:11000/api/cagent/generate \
  -H "Content-Type: application/json" \
  -d '{
    "language": "python",
    "input": "Create a FastAPI endpoint that accepts a JSON payload and stores it in a SQLite database"
  }'
```

### Example 2: Run Full Workflow via API

```bash
curl -X POST http://localhost:11000/api/cagent/workflow \
  -H "Content-Type: application/json" \
  -d '{
    "language": "typescript",
    "input": "Create a React component that fetches and displays a list of users",
    "run_ci": true
  }'
```

### Example 3: Invoke Git Sync Agent

```bash
curl -X POST http://localhost:11000/api/cagent/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "agent_file": "git_sync_agent.yaml",
    "input": "C:\\Users\\Keith Ransom\\AI-Tools"
  }'
```

### Example 4: Use Web UI

1. Navigate to `http://localhost:11000/`
2. Scroll to the "AI Code Generation" section
3. Select language (e.g., "Python")
4. Enter description: "Create a CLI tool that converts CSV to JSON"
5. Click "Generate + Test (Full Workflow)"
6. View results in the output panel

## PowerShell Integration

All API endpoints use PowerShell as a bridge to invoke cagent agents:

```powershell
Import-Module "C:\Users\Keith Ransom\AI-Tools\PortManager\PortManager.psm1"

# Direct invocation
Invoke-ToolAgent -AgentFile 'python_generator_agent.yaml' -Input 'Create a web scraper'

# Via UI wrapper
$payload = @{
    agent = 'typescript_generator_agent.yaml'
    input = 'Create a React form component'
} | ConvertTo-Json

Invoke-UIAgent -Payload $payload
```

## File Structure

```
AI-Tools/
├── ai_web_app.py                    # Main FastAPI application
├── cagent_integration.py            # Cagent router and endpoints
├── templates/
│   ├── index.html                   # Main UI template
│   └── cagent_section.html          # Cagent UI components
├── cagent_examples/
│   ├── python_generator_agent.yaml
│   ├── typescript_generator_agent.yaml
│   ├── go_generator_agent.yaml
│   ├── java_generator_agent.yaml
│   ├── mcp_server_generator.yaml
│   ├── generator_ci_workflow.yaml
│   ├── ci_agent.yaml
│   ├── coordinator_agent.yaml
│   ├── git_sync_agent.yaml
│   ├── docker_agent.yaml
│   ├── filesystem_agent.yaml
│   ├── curl_agent.yaml
│   ├── monitor_workflow.yaml
│   └── tool_sync_agent.yaml
├── PortManager/
│   └── PortManager.psm1             # PowerShell module with Invoke-ToolAgent
└── docker-compose.yml               # Services: cagent, mcp-server, ai-toolkit
```

## Environment Variables

Required environment variables (set in `.env` or system):

```bash
# API Keys (for generator agents)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GEMINI_API_KEY=...

# PowerShell Module Path (optional, has default)
PORT_MANAGER_MODULE=C:\Users\Keith Ransom\AI-Tools\PortManager\PortManager.psm1

# MCP Server (optional)
MCP_API_KEY=...
```

## Starting the Services

### Option 1: Docker Compose (Recommended)

```bash
cd "C:\Users\Keith Ransom\AI-Tools"
docker compose up -d
```

This starts:

- `ai-toolkit` on port 11000
- `tabbyml` on port 11001
- `cagent` on port 11002
- `mcp-server` on port 11003

### Option 2: Local Development

```bash
# Start the web application
cd "C:\Users\Keith Ransom\AI-Tools"
python ai_web_app.py

# In another terminal, ensure Docker services are running
docker compose up -d cagent mcp-server
```

## Testing the Integration

### 1. Health Check

```bash
curl http://localhost:11000/api/cagent/health
```

Expected output:

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

### 2. List Agents

```bash
curl http://localhost:11000/api/cagent/agents
```

### 3. Generate Code

```bash
curl -X POST http://localhost:11000/api/cagent/generate \
  -H "Content-Type: application/json" \
  -d '{"language":"python","input":"Create a hello world script"}'
```

## Troubleshooting

### Issue: "PowerShell module not found"

**Solution:** Set the `PORT_MANAGER_MODULE` environment variable:

```bash
$env:PORT_MANAGER_MODULE = "C:\Users\Keith Ransom\AI-Tools\PortManager\PortManager.psm1"
```

### Issue: "Agent file not found"

**Solution:** Verify the agent exists in `cagent_examples/`:

```bash
ls "C:\Users\Keith Ransom\AI-Tools\cagent_examples"
```

### Issue: "cagent service not running"

**Solution:** Start the Docker service:

```bash
docker compose up -d cagent
```

### Issue: "Timeout during agent execution"

**Solution:** Increase the timeout in `cagent_integration.py` (default: 300 seconds)

## Advanced Usage

### Custom Agent Creation

1. Create a new YAML file in `cagent_examples/`:

```yaml
#!/usr/bin/env cagent run

agents:
  root:
    model: gpt
    description: My custom agent
    instruction: |
      Your custom instructions here
    toolsets:
      - type: filesystem
      - type: shell

models:
  gpt:
    provider: openai
    model: gpt-4o
```

2. Invoke via API:

```bash
curl -X POST http://localhost:11000/api/cagent/invoke \
  -H "Content-Type: application/json" \
  -d '{"agent_file":"my_custom_agent.yaml","input":"test input"}'
```

### Workflow Chaining

Create complex workflows by chaining multiple agents:

```yaml
# custom_workflow.yaml
agents:
  root:
    model: gpt
    description: Multi-step workflow
    sub_agents:
      - generator
      - validator
      - deployer
  # ... define sub-agents
```

## Next Steps

1. **Add Authentication:** Secure the API endpoints with API keys or OAuth
2. **Add Logging:** Implement comprehensive logging for all agent invocations
3. **Add Metrics:** Track success rates, execution times, and usage patterns
4. **Add Caching:** Cache frequently used agent outputs
5. **Add Scheduling:** Schedule periodic agent runs (e.g., git-sync every hour)
6. **Add Webhooks:** Trigger agents via GitHub webhooks or other events

## Support

For issues or questions:

- Check the logs: `docker compose logs cagent`
- Review PowerShell output: `Get-Content $env:TEMP\cagent_*.log`
- Verify environment variables: `Get-ChildItem Env: | Where-Object Name -like '*API_KEY*'`
