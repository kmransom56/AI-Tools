# Port Management Integration Examples

## For AI CLI Tools (Python/Node.js)

### Python Example
```python
import subprocess
import json
import os

def get_port(application_name, preferred_port=0):
    """Get an available port for an application"""
    cli_path = os.environ.get('PORT_CLI_PATH', 'port-cli.ps1')
    cmd = ['powershell', '-File', cli_path, 'get', '-ApplicationName', application_name]
    if preferred_port > 0:
        cmd.extend(['-Port', str(preferred_port)])
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0:
        return int(result.stdout.strip())
    return None

def get_registered_port(application_name):
    """Get registered port for an application"""
    cli_path = os.environ.get('PORT_CLI_PATH', 'port-cli.ps1')
    cmd = ['powershell', '-File', cli_path, 'check', '-ApplicationName', application_name]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0:
        return int(result.stdout.strip())
    return None

# Usage
port = get_port('my-ai-tool')
print(f"Assigned port: {port}")
```

### Node.js Example
```javascript
const { execSync } = require('child_process');
const path = require('path');

function getPort(applicationName, preferredPort = 0) {
    const cliPath = process.env.PORT_CLI_PATH || 'port-cli.ps1';
    let cmd = `powershell -File "${cliPath}" get -ApplicationName "${applicationName}"`;
    if (preferredPort > 0) {
        cmd += ` -Port ${preferredPort}`;
    }
    
    try {
        const result = execSync(cmd, { encoding: 'utf-8' });
        return parseInt(result.trim());
    } catch (error) {
        return null;
    }
}

function getRegisteredPort(applicationName) {
    const cliPath = process.env.PORT_CLI_PATH || 'port-cli.ps1';
    const cmd = `powershell -File "${cliPath}" check -ApplicationName "${applicationName}"`;
    
    try {
        const result = execSync(cmd, { encoding: 'utf-8' });
        return parseInt(result.trim());
    } catch (error) {
        return null;
    }
}

// Usage
const port = getPort('my-ai-tool');
console.log(`Assigned port: ${port}`);
```

## For PowerShell Scripts

### Direct Module Import
```powershell
Import-Module "$env:PORT_MANAGER_MODULE" -Force
$port = Get-AvailablePort -ApplicationName "MyApp"
```

### Using CLI
```powershell
$port = & "$env:PORT_CLI_PATH" get -ApplicationName "MyApp"
```

## For VS Code / Cursor Extensions

### TypeScript/JavaScript
```typescript
import { execSync } from 'child_process';

export function getPort(applicationName: string): number | null {
    const cliPath = process.env.PORT_CLI_PATH || 'port-cli.ps1';
    try {
        const result = execSync(
            `powershell -File "${cliPath}" get -ApplicationName "${applicationName}"`,
            { encoding: 'utf-8' }
        );
        return parseInt(result.trim());
    } catch {
        return null;
    }
}
```

## Reading Registry Directly (JSON)

### Python
```python
import json
import os

def get_registry():
    registry_path = os.path.expandvars(r'%USERPROFILE%\AI-Tools\port-registry.json')
    if os.path.exists(registry_path):
        with open(registry_path, 'r') as f:
            return json.load(f)
    return None

def get_app_port(application_name):
    registry = get_registry()
    if registry:
        for port, info in registry.get('RegisteredPorts', {}).items():
            if info.get('ApplicationName') == application_name:
                return int(port)
    return None
```

### Node.js
```javascript
const fs = require('fs');
const path = require('path');
const os = require('os');

function getRegistry() {
    const registryPath = path.join(os.homedir(), 'AI-Tools', 'port-registry.json');
    if (fs.existsSync(registryPath)) {
        return JSON.parse(fs.readFileSync(registryPath, 'utf-8'));
    }
    return null;
}

function getAppPort(applicationName) {
    const registry = getRegistry();
    if (registry && registry.RegisteredPorts) {
        for (const [port, info] of Object.entries(registry.RegisteredPorts)) {
            if (info.ApplicationName === applicationName) {
                return parseInt(port);
            }
        }
    }
    return null;
}
```

## Environment Variables

After running `setup-port-env.ps1`, these are available:
- `PORT_MANAGER_MODULE` - Path to PowerShell module
- `PORT_CLI_PATH` - Path to CLI script
- `PORT_REGISTRY_PATH` - Path to JSON registry

## Tools Integration

### Cursor Agent
Add to your Cursor config:
```json
{
  "portManager": {
    "cliPath": "%PORT_CLI_PATH%",
    "getPort": "powershell -File \"%PORT_CLI_PATH%\" get -ApplicationName"
  }
}
```

### Copilot CLI
Create wrapper script that calls port-cli.ps1 before starting.

### Claude Code / Cline CLI
Use the Python/Node.js examples above in your tool's initialization.

