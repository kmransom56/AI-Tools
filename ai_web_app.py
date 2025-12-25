"""
AI Toolkit Web Frontend
FastAPI application for interacting with AI tools through a web interface
"""
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel
import os
import subprocess
import openai
import anthropic
import google.generativeai as genai

app = FastAPI(title="AI Toolkit Web Interface")

# Configure templates
templates = Jinja2Templates(directory="/app/templates")

# Configure AI clients
openai_client = openai.OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
anthropic_client = anthropic.Anthropic(api_key=os.getenv('ANTHROPIC_API_KEY'))
genai.configure(api_key=os.getenv('GEMINI_API_KEY'))

class ChatRequest(BaseModel):
    message: str
    model: str = "gpt-4"  # gpt-4, claude-3-5-sonnet-20241022, gemini-pro, or sgpt

class CodeRequest(BaseModel):
    code: str
    language: str = "python"

@app.get("/", response_class=HTMLResponse)
async def home(request: Request):
    """Serve the main web interface"""
    return templates.TemplateResponse("index.html", {"request": request})

@app.get("/api/models")
async def get_models():
    """Return available AI models"""
    return {
        "models": [
            {"id": "gpt-4", "name": "GPT-4 (OpenAI)", "provider": "openai"},
            {"id": "gpt-4-turbo-preview", "name": "GPT-4 Turbo (OpenAI)", "provider": "openai"},
            {"id": "gpt-3.5-turbo", "name": "GPT-3.5 Turbo (OpenAI)", "provider": "openai"},
            {"id": "claude-3-5-sonnet-20241022", "name": "Claude 3.5 Sonnet (Anthropic)", "provider": "anthropic"},
            {"id": "claude-3-opus-20240229", "name": "Claude 3 Opus (Anthropic)", "provider": "anthropic"},
            {"id": "gemini-pro", "name": "Gemini Pro (Google)", "provider": "google"},
            {"id": "sgpt", "name": "Shell-GPT (CLI)", "provider": "sgpt"}
        ]
    }

@app.post("/api/chat")
async def chat(request: ChatRequest):
    """Send a message to the selected AI model"""
    try:
        if request.model.startswith("gpt"):
            # OpenAI
            response = openai_client.chat.completions.create(
                model=request.model,
                messages=[{"role": "user", "content": request.message}]
            )
            return {
                "success": True,
                "response": response.choices[0].message.content,
                "model": request.model,
                "provider": "openai"
            }
        
        elif request.model.startswith("claude"):
            # Anthropic
            response = anthropic_client.messages.create(
                model=request.model,
                max_tokens=4096,
                messages=[{"role": "user", "content": request.message}]
            )
            return {
                "success": True,
                "response": response.content[0].text,
                "model": request.model,
                "provider": "anthropic"
            }
        
        elif request.model == "gemini-pro":
            # Google Gemini
            model = genai.GenerativeModel('gemini-pro')
            response = model.generate_content(request.message)
            return {
                "success": True,
                "response": response.text,
                "model": request.model,
                "provider": "google"
            }
        
        elif request.model == "sgpt":
            # Shell-GPT
            result = subprocess.run(
                ["sgpt", request.message],
                capture_output=True,
                text=True,
                timeout=60
            )
            if result.returncode == 0:
                return {
                    "success": True,
                    "response": result.stdout,
                    "model": "sgpt",
                    "provider": "sgpt"
                }
            else:
                return {
                    "success": False,
                    "error": result.stderr or "Shell-GPT execution failed"
                }
        
        else:
            return {
                "success": False,
                "error": f"Unknown model: {request.model}"
            }
    
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }

@app.post("/api/execute-code")
async def execute_code(request: CodeRequest):
    """Execute Python code in the container"""
    try:
        if request.language == "python":
            result = subprocess.run(
                ["python", "-c", request.code],
                capture_output=True,
                text=True,
                timeout=30
            )
            return {
                "success": result.returncode == 0,
                "stdout": result.stdout,
                "stderr": result.stderr,
                "exit_code": result.returncode
            }
        else:
            return {
                "success": False,
                "error": f"Unsupported language: {request.language}"
            }
    except subprocess.TimeoutExpired:
        return {
            "success": False,
            "error": "Execution timeout (30s limit)"
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }

@app.get("/api/health")
async def health():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "apis_configured": {
            "openai": bool(os.getenv('OPENAI_API_KEY')),
            "anthropic": bool(os.getenv('ANTHROPIC_API_KEY')),
            "gemini": bool(os.getenv('GEMINI_API_KEY'))
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
