# AI Toolkit - Quick Start Guide

## Setup Instructions

### 1. Verify Python Environment
Your Python environment has been configured:
- **Location**: `c:\Users\south\AI-Tools\.venv`
- **Version**: Python 3.14.2
- **Status**: ✓ Ready

All required packages have been installed:
```
openai, anthropic, google-generativeai, google-genai, fastapi, uvicorn, 
docker, pydantic, jinja2, pyyaml, requests, httpx, python-dotenv, and more
```

### 2. Configure API Keys

The `.env` file has been created at the project root. You need to fill in your API keys:

```powershell
# Open the .env file
notepad .env
```

Replace placeholder keys with your actual API keys:
- **OPENAI_API_KEY**: Get from https://platform.openai.com/api-keys
- **ANTHROPIC_API_KEY**: Get from https://console.anthropic.com
- **GEMINI_API_KEY**: Get from https://makersuite.google.com

Example:
```
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxx
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxxxxxxxxx
GEMINI_API_KEY=AIzaSyxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Important**: The `.env` file is gitignored and will never be committed.

### 3. Verify Docker Installation
Docker is already installed on your system:
```
Docker version 29.1.3, build f52814d
```

Ensure Docker Desktop is running before using Docker Compose features.

### 4. Start the Web Server

#### Option A: Direct Python (Recommended for Development)
```powershell
cd c:\Users\south\AI-Tools
python run_dev_server.py
```

This will:
- Load environment variables from `.env`
- Start the FastAPI server on port 8000
- Enable hot-reload for code changes
- Show detailed logs

#### Option B: Docker Compose (Recommended for Production Testing)
```powershell
cd c:\Users\south\AI-Tools
docker compose up --build
```

This will:
- Build the Docker image
- Start the ai-toolkit service
- Start the optional TabbyML service
- Mount volumes for development

### 5. Test the Application

Once the server is running, access:
- **Web Interface**: http://localhost:8000
- **API Docs (Swagger)**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/api/health
- **Available Models**: http://localhost:8000/api/models

### 6. Test API Endpoints

#### Test Health Endpoint
```powershell
curl http://localhost:8000/api/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2026-01-16T23:32:10.123456",
  "apis_configured": {
    "openai": true,
    "anthropic": true,
    "gemini": true,
    "docker": true
  }
}
```

#### Test Chat Endpoint
```powershell
$body = @{
    message = "Hello! What is 2 + 2?"
    model = "gpt-4"
} | ConvertTo-Json

curl -X POST http://localhost:8000/api/chat `
  -Headers @{"Content-Type"="application/json"} `
  -Body $body
```

#### Test Code Execution
```powershell
$body = @{
    code = "import sys; print(f'Python {sys.version}')"
    language = "python"
} | ConvertTo-Json

curl -X POST http://localhost:8000/api/execute-code `
  -Headers @{"Content-Type"="application/json"} `
  -Body $body
```

## Improvements Made

### Code Quality Enhancements
✓ **Better Path Handling**: Templates directory detection works in both dev and Docker modes
✓ **Graceful Degradation**: App starts even if some API keys are missing
✓ **Comprehensive Logging**: All operations logged with timestamps and levels
✓ **Error Handling**: Detailed error messages for debugging
✓ **Health Check**: Extended health endpoint shows configuration status

### New Features
✓ **Startup Event**: Logs initialization information
✓ **Improved Chat Endpoint**: Better error messages when providers are misconfigured
✓ **Code Execution Logging**: Tracks all executed code
✓ **Environment Details**: Health check shows template and working directories

### Debugging & Support
✓ **Run Script**: `run_dev_server.py` for easy development startup
✓ **Detailed Status**: Check API availability and configuration
✓ **.env Configuration**: Easy setup without system environment variables
✓ **Docker Validation**: Compose file already validated

## Troubleshooting

### Problem: "Templates directory not found"
**Solution**: Make sure you're running from the project root:
```powershell
cd c:\Users\south\AI-Tools
python run_dev_server.py
```

### Problem: "ModuleNotFoundError: No module named 'openai'"
**Solution**: Packages are already installed. Make sure you're using the project venv:
```powershell
# Verify venv is active
which python  # Should show .venv path
```

### Problem: API returns "API key not configured"
**Solution**: Update your `.env` file with actual API keys, then restart the server.

### Problem: Docker socket not found
**Solution**: This error only affects cagent functionality. Docker Desktop may need restart:
```powershell
# Restart Docker Desktop
Stop-Service com.docker.service
Start-Service com.docker.service
```

### Problem: Port 8000 already in use
**Solution**: Either stop the conflicting service or use a different port:
```powershell
python -m uvicorn ai_web_app:app --port 8001
```

## Next Steps

1. **Update .env** with your actual API keys
2. **Start the dev server** with `python run_dev_server.py`
3. **Test endpoints** using curl or the Swagger UI
4. **Check logs** for any configuration issues
5. **Use Docker** when you're ready for production-like testing

## File Structure

```
c:\Users\south\AI-Tools\
├── ai_web_app.py           # FastAPI application
├── run_dev_server.py        # Development startup script (NEW)
├── .env                     # API keys (created, add your keys here)
├── docker-compose.yml       # Docker services configuration
├── Dockerfile.ai-toolkit    # Docker image definition
├── templates/
│   └── index.html          # Web UI
├── .github/
│   └── copilot-instructions.md  # AI agent guidelines
└── docs/
    └── *.md                # Additional documentation
```

## Status Summary

| Component | Status | Notes |
|-----------|--------|-------|
| Python Environment | ✓ Ready | 3.14.2 with venv |
| Dependencies | ✓ Installed | All required packages installed |
| FastAPI App | ✓ Valid | 11 routes configured |
| Docker | ✓ Installed | v29.1.3 |
| Docker Compose | ✓ Valid | Config validated |
| API Keys | ⚠ Pending | Add actual keys to `.env` |
| Templates | ✓ Found | `templates/` directory exists |

---

**Ready to start development!** 🚀

Run `python run_dev_server.py` to begin.
