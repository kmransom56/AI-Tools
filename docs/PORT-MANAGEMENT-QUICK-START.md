# Port Management Quick Start

## Setup (One-Time)

Run this once to make port management available system-wide:

```powershell
.\integrations\setup-port-env.ps1
```

This will:
- Add Port Manager to your PowerShell profile
- Set environment variables (`PORT_MANAGER_MODULE`, `PORT_CLI_PATH`, `PORT_REGISTRY_PATH`)
- Make it available to all tools

## Usage for Different Tools

### PowerShell Scripts
```powershell
Import-Module "$env:PORT_MANAGER_MODULE" -Force
$port = Get-AvailablePort -ApplicationName "MyApp"
```

### Python Tools (cursor-agent, cline-cli, etc.)
```python
from integrations.python_port_helper import get_port

port = get_port('my-ai-tool')
# or
port = get_port('my-ai-tool', preferred_port=11000)
```

### Node.js Tools (copilot-cli, etc.)
```javascript
const { getPort } = require('./integrations/node-port-helper');

const port = getPort('my-ai-tool');
// or
const port = getPort('my-ai-tool', 11000);
```

### Command Line (Any Tool)
```bash
# Get port
powershell -File port-cli.ps1 get -ApplicationName "MyApp"

# Check registered port
powershell -File port-cli.ps1 check -ApplicationName "MyApp"

# List all registered ports
powershell -File port-cli.ps1 list
```

### Direct JSON Access (Any Language)
Read `%USERPROFILE%\AI-Tools\port-registry.json` directly.

## Integration Examples

### Cursor Agent
Add to your Cursor config or startup script:
```python
from integrations.python_port_helper import get_port
PORT = get_port('cursor-agent', 11000)
```

### Copilot CLI
Create a wrapper that calls port-cli.ps1 before starting.

### Claude Code / Cline CLI
Import the Python helper in your tool's initialization.

### Gemini CLI
Use the Node.js or Python helper depending on your tool's language.

## Port Ranges

- **11000-12000**: Preferred range (auto-assigned)
- **3000-8000**: Migration range (will be moved to 11000-12000)

## Registry Location

`%USERPROFILE%\AI-Tools\port-registry.json`

All registered ports are stored here and can be read by any tool.

