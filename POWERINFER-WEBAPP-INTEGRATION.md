# PowerInfer Integration Guide for AI Tools Web App

## ✅ Good News: PowerInfer is Already Integrated!

Your `ai_web_app.py` already has full PowerInfer support built-in. You just need to configure it!

## Configuration Options

You have **two ways** to use PowerInfer with your AI Tools application:

### Option 1: API Server Mode (Recommended)

Use PowerInfer as an OpenAI-compatible API server.

**1. Start PowerInfer Server:**

```powershell
cd PowerInfer
.\build\bin\Release\server.exe `
  -m ..\PowerInfer\models\bamboo-7b-dpo-v0.1.q4.powerinfer.gguf `
  --host 0.0.0.0 `
  --port 8081 `
  --vram-budget 10 `
  -t 8 `
  -c 2048
```

**2. Configure Environment Variables:**

Add to your `.env` file:

```bash
# PowerInfer Configuration (API Server Mode)
POWERINFER_HOST=http://localhost:8081
POWERINFER_MODEL=bamboo-7b-dpo
```

**3. Restart AI Tools:**

```powershell
docker-compose restart ai-toolkit
```

**4. Use in Web Interface:**

- Open http://localhost:11000
- Select "PowerInfer (bamboo-7b-dpo)" from model dropdown
- Start chatting!

### Option 2: CLI Mode

Use PowerInfer directly via command line.

**Configure Environment Variables:**

Add to your `.env` file:

```bash
# PowerInfer Configuration (CLI Mode)
POWERINFER_CLI=C:\Users\Keith Ransom\AI-Tools\PowerInfer\build\bin\Release\main.exe -m C:\Users\Keith Ransom\AI-Tools\PowerInfer\models\bamboo-7b-dpo-v0.1.q4.powerinfer.gguf -n 512 -t 8 --vram-budget 10 -p '{prompt}'
POWERINFER_MODEL=bamboo-7b-dpo
```

**Note:** The `{prompt}` placeholder will be replaced with the user's message.

## Docker Compose Integration

For automatic startup with Docker Compose, the PowerInfer service is already defined in `docker-compose.yml`.

**Start PowerInfer with Docker:**

```powershell
docker-compose up -d powerinfer
```

**Configure for Docker:**

```bash
# PowerInfer Configuration (Docker Mode)
POWERINFER_HOST=http://powerinfer:8080
POWERINFER_MODEL=bamboo-7b-dpo
```

## Verification

### 1. Check Model Availability

Visit: http://localhost:11000/api/models

You should see PowerInfer in the list:

```json
{
  "models": [
    ...
    {
      "id": "powerinfer",
      "name": "PowerInfer (bamboo-7b-dpo)",
      "provider": "powerinfer"
    }
  ]
}
```

### 2. Test Chat Endpoint

```powershell
curl http://localhost:11000/api/chat `
  -H "Content-Type: application/json" `
  -d '{
    "message": "Hello! What can you do?",
    "model": "powerinfer"
  }'
```

Expected response:

```json
{
  "success": true,
  "response": "Hello! I'm an AI assistant...",
  "model": "powerinfer",
  "provider": "powerinfer"
}
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  AI Tools Web Interface                      │
│                 (http://localhost:11000)                     │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   FastAPI Backend                            │
│                  (ai_web_app.py)                             │
│                                                              │
│  Model Router:                                               │
│  ├─ GPT-4 → OpenAI API                                       │
│  ├─ Claude → Anthropic API                                   │
│  ├─ Gemini → Google API                                      │
│  ├─ PowerInfer → Local API/CLI ✨                            │
│  └─ Cagent → Local Agent                                     │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              PowerInfer Server/CLI                           │
│         (http://localhost:8081 or CLI)                       │
│                                                              │
│  • Hybrid CPU/GPU inference                                  │
│  • GGUF model loading                                        │
│  • OpenAI-compatible API                                     │
│  • 15-20 tokens/s on RTX 3060                                │
└─────────────────────────────────────────────────────────────┘
```

## Code Flow

### 1. Model Selection (ai_web_app.py:737-744)

```python
if (powerinfer_host and powerinfer_model) or (powerinfer_cli and powerinfer_model):
    models.append({
        "id": "powerinfer",
        "name": f"PowerInfer ({powerinfer_model or 'cli'})",
        "provider": "powerinfer",
    })
```

### 2. Chat Request Handling (ai_web_app.py:1014-1031)

```python
elif request.model == "powerinfer":
    if powerinfer_host and powerinfer_model:
        # API Server Mode
        content = await call_local_chat(
            powerinfer_host, powerinfer_model, request.message
        )
    elif powerinfer_cli and powerinfer_model:
        # CLI Mode
        content = run_cli_chat(powerinfer_cli, request.message)
    else:
        return {
            "success": False,
            "error": "PowerInfer not configured..."
        }

    return {
        "success": True,
        "response": content,
        "model": request.model,
        "provider": "powerinfer",
    }
```

### 3. API Call Helper (ai_web_app.py:415-451)

```python
async def call_local_chat(host: str, model: str, message: str, timeout: float = 30.0):
    """Call a local LLM endpoint that speaks an OpenAI-compatible chat/completions API."""
    # Normalizes URL and calls /v1/chat/completions
    # Returns the generated text
```

### 4. CLI Helper (ai_web_app.py:454-481)

```python
def run_cli_chat(cmd_template: str, message: str, timeout: float = 60.0):
    """Run a local CLI command for LLM inference. Expects a {prompt} placeholder."""
    # Replaces {prompt} with user message
    # Executes command and returns output
```

## Enhanced Integration with Backend Module

To use the enterprise backend we created, update `ai_web_app.py`:

### Add Import

```python
# At top of file
from engines.powerinfer import PowerInferBackend
from pathlib import Path
import yaml
```

### Add Backend Initialization

```python
# After line 153 (after docker_client)
powerinfer_backend = None
if os.path.exists("configs/models/powerinfer/bamboo-7b-dpo.yaml"):
    try:
        powerinfer_backend = PowerInferBackend(Path("."))
        logger.info("PowerInfer backend initialized successfully")
    except Exception as e:
        logger.warning(f"PowerInfer backend initialization failed: {e}")
```

### Enhanced Chat Handler

```python
elif request.model == "powerinfer":
    # Try enterprise backend first
    if powerinfer_backend:
        try:
            # Load policy
            policy_path = Path("configs/models/powerinfer/bamboo-7b-dpo.yaml")
            with open(policy_path) as f:
                policy = yaml.safe_load(f)

            # Generate with metrics
            content, metrics = powerinfer_backend.generate_with_metrics(
                prompt=request.message,
                policy=policy,
            )

            return {
                "success": True,
                "response": content,
                "model": request.model,
                "provider": "powerinfer",
                "metrics": {
                    "tokens_per_second": metrics.tokens_per_second,
                    "duration_seconds": metrics.duration_seconds,
                    "total_tokens": metrics.total_tokens,
                }
            }
        except Exception as e:
            logger.error(f"PowerInfer backend error: {e}")
            # Fall through to original implementation

    # Original implementation (API/CLI)
    if powerinfer_host and powerinfer_model:
        content = await call_local_chat(powerinfer_host, powerinfer_model, request.message)
    elif powerinfer_cli and powerinfer_model:
        content = run_cli_chat(powerinfer_cli, request.message)
    else:
        return {
            "success": False,
            "error": "PowerInfer not configured..."
        }

    return {
        "success": True,
        "response": content,
        "model": request.model,
        "provider": "powerinfer",
    }
```

## Quick Start

### 1. Build PowerInfer

```powershell
.\setup-powerinfer.ps1
```

### 2. Download Model

```powershell
.\download-powerinfer-models.ps1 -ModelName bamboo-dpo
```

### 3. Start PowerInfer Server

```powershell
cd PowerInfer
.\build\bin\Release\server.exe -m ..\PowerInfer\models\bamboo-7b-dpo-v0.1.q4.powerinfer.gguf --host 0.0.0.0 --port 8081 --vram-budget 10 -t 8
```

### 4. Configure Environment

Add to `.env`:

```bash
POWERINFER_HOST=http://localhost:8081
POWERINFER_MODEL=bamboo-7b-dpo
```

### 5. Restart AI Tools

```powershell
docker-compose restart ai-toolkit
```

### 6. Test in Browser

1. Open http://localhost:11000
2. Select "PowerInfer (bamboo-7b-dpo)" from dropdown
3. Send a message!

## Troubleshooting

### PowerInfer Not in Model List

**Check:**

1. Environment variables are set in `.env`
2. AI Tools container restarted after `.env` changes
3. PowerInfer server is running: `curl http://localhost:8081/health`

**Solution:**

```powershell
# Verify .env has PowerInfer config
cat .env | Select-String "POWERINFER"

# Restart container
docker-compose restart ai-toolkit

# Check logs
docker logs ai-toolkit
```

### "PowerInfer not configured" Error

**Cause:** Environment variables not loaded

**Solution:**

```powershell
# Ensure .env is in docker-compose directory
# Restart with explicit env file
docker-compose --env-file .env up -d ai-toolkit
```

### Connection Refused

**Cause:** PowerInfer server not running or wrong URL

**Solution:**

```powershell
# Test PowerInfer server directly
curl http://localhost:8081/health

# Check if running
netstat -ano | findstr :8081

# Verify URL in .env matches server
```

## Summary

✅ **PowerInfer is already integrated** into your AI Tools web application!  
✅ **No code changes needed** - just configuration  
✅ **Two modes available**: API Server (recommended) or CLI  
✅ **Full UI support** - appears in model dropdown automatically  
✅ **OpenAI-compatible** - works with existing chat interface

**Next Steps:**

1. Configure `.env` with PowerInfer settings
2. Start PowerInfer server
3. Restart AI Tools container
4. Start using PowerInfer in the web interface!

The enterprise backend integration (engines/powerinfer/) is **optional** but provides:

- Policy-based configuration
- Performance metrics
- Checksum validation
- Better error handling
- Extensibility for future engines
