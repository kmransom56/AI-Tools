"""
AI Toolkit Web Frontend
FastAPI application for interacting with AI tools through a web interface
"""
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel
import os
import subprocess
import openai
import anthropic
import google.generativeai as genai
import yaml
import docker
import pathlib
import tempfile

app = FastAPI(title="AI Toolkit Web Interface")

# Configure templates
templates = Jinja2Templates(directory="/app/templates")

# Configure AI clients
openai_client = openai.OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
anthropic_client = anthropic.Anthropic(api_key=os.getenv('ANTHROPIC_API_KEY'))
genai.configure(api_key=os.getenv('GEMINI_API_KEY'))

# Docker client (may not be available in all environments)
try:
    docker_client = docker.from_env()
except Exception:
    docker_client = None

class ChatRequest(BaseModel):
    message: str
    model: str = "gpt-4"  # gpt-4, claude-3-5-sonnet-20241022, gemini-pro, or sgpt

class CodeRequest(BaseModel):
    code: str
    language: str = "python"

class CagentRunRequest(BaseModel):
    example_path: str
    # Optional overrides (not trusted from UI in most cases)
    overrides: dict = {}


def find_cagent_examples():
    """Search for YAML files under common repo locations and return metadata."""
    candidates = []
    roots = ["/workspace", "/app/workspace", "/app", "./"]
    seen = set()
    for root in roots:
        if not os.path.exists(root):
            continue
        for dirpath, dirs, files in os.walk(root):
            # only consider files under a path containing 'cagent' and 'examples'
            if not ("cagent" in dirpath and "examples" in dirpath):
                continue
            for f in files:
                if f.endswith(".yaml") or f.endswith(".yml"):
                    full = os.path.join(dirpath, f)
                    absfull = os.path.abspath(full)
                    if absfull in seen:
                        continue
                    seen.add(absfull)
                    meta = {
                        "path": absfull,
                        "relpath": os.path.relpath(absfull, start=root),
                        "name": f,
                        "tag": None,
                        "dry_run": None,
                        "max_iterations": None,
                    }
                    # try to parse basic fields
                    try:
                        with open(full, "r", encoding="utf-8") as fh:
                            docs = list(yaml.safe_load_all(fh))
                            # Find first dict that contains keys of interest
                            for doc in docs:
                                if isinstance(doc, dict):
                                    if not meta['tag'] and 'tag' in doc:
                                        meta['tag'] = doc.get('tag')
                                    if meta['dry_run'] is None and 'dry_run' in doc:
                                        meta['dry_run'] = bool(doc.get('dry_run'))
                                    if meta['max_iterations'] is None and 'max_iterations' in doc:
                                        try:
                                            meta['max_iterations'] = int(doc.get('max_iterations'))
                                        except Exception:
                                            meta['max_iterations'] = None
                    except Exception:
                        # Could not parse YAML; ignore and still include
                        pass
                    candidates.append(meta)
    # sort
    candidates.sort(key=lambda x: (x.get('tag') or '', x['name']))
    return candidates


@app.get("/api/cagent/examples")
async def cagent_examples():
    """Return list of discovered cagent examples with basic metadata."""
    examples = find_cagent_examples()
    return {"examples": examples, "count": len(examples)}


@app.post("/api/cagent/run")
async def cagent_run(req: CagentRunRequest):
    """Run a cagent example in a docker/cagent image with safety checks.
    Enforces CAGENT_DRY_RUN=1 and checks max_iterations <= 10.
    Returns logs (synchronously) or an error.
    """
    # Resolve path and ensure it exists and is under allowed roots
    example_path = os.path.abspath(req.example_path)
    allowed_roots = [os.path.abspath(p) for p in ["/workspace", "/app/workspace", "/app", os.getcwd()]]
    if not any(example_path.startswith(r) for r in allowed_roots):
        raise HTTPException(status_code=400, detail="example path not inside allowed repository paths")
    if not os.path.exists(example_path):
        raise HTTPException(status_code=404, detail="example file not found")

    # Parse YAML to inspect safety fields
    try:
        with open(example_path, 'r', encoding='utf-8') as fh:
            docs = list(yaml.safe_load_all(fh))
            # merge keys from docs for top-level fields
            merged = {}
            for d in docs:
                if isinstance(d, dict):
                    merged.update(d)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to parse YAML: {e}")

    # Enforce/validate safety
    if 'max_iterations' in merged:
        try:
            mi = int(merged.get('max_iterations'))
            if mi > 10:
                raise HTTPException(status_code=400, detail="max_iterations too large (must be <= 10)")
        except ValueError:
            raise HTTPException(status_code=400, detail="max_iterations is not an integer")

    # We'll enforce dry run using env var regardless of file
    env_overrides = req.overrides or {}
    env = {'CAGENT_DRY_RUN': '1'}
    # Merge any safe overrides (but do not allow disabling dry_run or increasing max_iterations)
    if env_overrides.get('CAGENT_DRY_RUN') in ['0', 'false', 'False']:
        raise HTTPException(status_code=403, detail="Disabling dry_run via UI is not permitted")

    # Ensure docker client available
    if docker_client is None:
        raise HTTPException(status_code=500, detail="Docker client not available in server environment")

    image = 'docker/cagent:latest'
    try:
        # Pull image (may be no-op if present)
        docker_client.images.pull(image)
    except Exception as e:
        # Not fatal; may be available locally
        pass

    # Determine workdir inside container. We expect repo root to be mounted at /workspace
    # and example_path to be accessible under that mount. Map host path to /workspace.
    host_workspace = None
    for root in allowed_roots:
        if example_path.startswith(root):
            host_workspace = root
            break
    if not host_workspace:
        host_workspace = os.path.dirname(example_path)

    bind_workspace = {host_workspace: {'bind': '/workspace', 'mode': 'rw'}}
    # Also mount docker socket so the cagent container can use docker if needed
    if os.path.exists('/var/run/docker.sock'):
        bind_workspace['/var/run/docker.sock'] = {'bind': '/var/run/docker.sock', 'mode': 'rw'}

    # Run the container (synchronously) and capture logs
    # Use the image entrypoint: run <example_relative_path>
    # We pass command ['run', example_relpath]
    example_rel = os.path.relpath(example_path, start=host_workspace)
    try:
        logs = docker_client.containers.run(
            image=image,
            command=['run', example_rel],
            environment=env,
            volumes=bind_workspace,
            remove=True,
            stdout=True,
            stderr=True,
            stream=False,
            detach=False,
            working_dir='/workspace'
        )
        # logs may be bytes
        if isinstance(logs, bytes):
            logs_text = logs.decode('utf-8', errors='replace')
        else:
            logs_text = str(logs)
        return {"success": True, "logs": logs_text}
    except docker.errors.ContainerError as ce:
        # container failed, get logs
        return JSONResponse(status_code=500, content={"success": False, "error": str(ce), "logs": getattr(ce, 'stderr', '')})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/", response_class=HTMLResponse)
async def home(request: Request):
    """Serve the main web interface"""
    return templates.TemplateResponse("index.html", {"request": request})

# (rest of file unchanged: models, chat, execute_code, health)

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
