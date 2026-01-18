# PowerInfer Enterprise Integration Plan

## Overview

This document outlines the **enterprise-grade integration** of PowerInfer into the AI-Tools ecosystem, treating it as a first-class backend alongside existing engines with proper CLI integration, YAML policy management, and observability.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     AI-Tools CLI                             │
│                  (ai-tools run ...)                          │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│            Engine Router / Orchestrator                      │
│         (selects backend by --engine flag)                   │
└──────────────┬──────────────────────────┬───────────────────┘
               │                          │
       ┌───────▼────────┐        ┌───────▼────────┐
       │  PowerInfer    │        │ Other Backends │
       │    Backend     │        │ (llama.cpp,    │
       │ (engines/      │        │  vLLM, etc.)   │
       │  powerinfer)   │        │                │
       └───────┬────────┘        └───────┬────────┘
               │                         │
       ┌───────▼────────┐        ┌───────▼────────┐
       │ PowerInfer     │        │ Other Engine   │
       │ Binary & Libs  │        │   Runtimes     │
       │ (build/        │        │                │
       │  powerinfer)   │        │                │
       └───────┬────────┘        └────────────────┘
               │
       ┌───────▼────────────────────────────────┐
       │  GGUF Models + YAML Policies           │
       │  models/powerinfer/...                 │
       │  configs/models/powerinfer/*.yaml      │
       └────────────────────────────────────────┘
```

## Phase 0: Repository Structure

### Recommended Layout

```
AI-Tools/
├── external/
│   └── powerinfer/              # Git submodule
├── engines/
│   ├── powerinfer/
│   │   ├── __init__.py
│   │   ├── backend.py           # PowerInfer backend implementation
│   │   ├── config.py            # Configuration management
│   │   └── utils.py             # Helper functions
│   └── registry.py              # Engine registry
├── configs/
│   └── models/
│       └── powerinfer/
│           ├── bamboo-7b-dpo.yaml
│           ├── prosparse-llama2-7b.yaml
│           └── mixtral-47b.yaml
├── models/
│   └── powerinfer/
│       ├── bamboo-7b-dpo/
│       │   ├── model.powerinfer.gguf
│       │   └── policy.yaml
│       └── prosparse-llama2-7b/
│           ├── model.powerinfer.gguf
│           └── policy.yaml
├── scripts/
│   └── powerinfer/
│       ├── build.sh             # Build script (Linux/Mac)
│       ├── build.ps1            # Build script (Windows)
│       ├── convert.py           # Model conversion
│       └── validate.py          # Model validation
├── build/
│   └── powerinfer/              # Build artifacts
└── cli.py                       # Main CLI entry point
```

### Setup Submodule

```bash
# Add PowerInfer as submodule
git submodule add https://github.com/SJTU-IPADS/PowerInfer external/powerinfer
git submodule update --init --recursive
```

## Phase 1: Build System

### Windows Build Script

**File:** `scripts/powerinfer/build.ps1`

```powershell
#!/usr/bin/env pwsh
# PowerInfer Build Script for Windows

param(
    [switch]$Clean = $false,
    [string]$BuildType = "Release",
    [int]$Jobs = 8
)

$ErrorActionPreference = "Stop"

# Paths
$ROOT_DIR = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$SOURCE_DIR = Join-Path $ROOT_DIR "external" "powerinfer"
$BUILD_DIR = Join-Path $ROOT_DIR "build" "powerinfer"

Write-Host "🔨 Building PowerInfer" -ForegroundColor Cyan
Write-Host "  Source: $SOURCE_DIR" -ForegroundColor Gray
Write-Host "  Build: $BUILD_DIR" -ForegroundColor Gray
Write-Host "  Type: $BuildType" -ForegroundColor Gray

# Clean if requested
if ($Clean -and (Test-Path $BUILD_DIR)) {
    Write-Host "🧹 Cleaning build directory..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $BUILD_DIR
}

# Create build directory
New-Item -ItemType Directory -Force -Path $BUILD_DIR | Out-Null

# Configure
Write-Host "⚙️  Configuring CMake..." -ForegroundColor Yellow
cmake -S $SOURCE_DIR -B $BUILD_DIR `
    -DLLAMA_CUBLAS=ON `
    -DCMAKE_BUILD_TYPE=$BuildType

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ CMake configuration failed!" -ForegroundColor Red
    exit 1
}

# Build
Write-Host "🔧 Building..." -ForegroundColor Yellow
cmake --build $BUILD_DIR --config $BuildType -j $Jobs

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build completed successfully!" -ForegroundColor Green
Write-Host "📍 Binaries: $BUILD_DIR\bin\$BuildType\" -ForegroundColor Cyan
```

## Phase 2: Backend Implementation

### PowerInfer Backend Module

**File:** `engines/powerinfer/backend.py`

```python
"""PowerInfer Backend Implementation"""

import subprocess
import json
from pathlib import Path
from typing import Dict, Any, List, Optional
import logging

logger = logging.getLogger(__name__)


class PowerInferBackend:
    """PowerInfer engine backend with policy-based configuration"""

    def __init__(self, repo_root: Path):
        self.repo_root = Path(repo_root)
        self.binary = self._find_binary()
        self.server_binary = self._find_server_binary()

    def _find_binary(self) -> Path:
        """Locate PowerInfer main binary"""
        # Windows
        win_path = self.repo_root / "build" / "powerinfer" / "bin" / "Release" / "main.exe"
        if win_path.exists():
            return win_path

        # Linux/Mac
        unix_path = self.repo_root / "build" / "powerinfer" / "bin" / "main"
        if unix_path.exists():
            return unix_path

        raise FileNotFoundError("PowerInfer binary not found. Run build script first.")

    def _find_server_binary(self) -> Path:
        """Locate PowerInfer server binary"""
        # Windows
        win_path = self.repo_root / "build" / "powerinfer" / "bin" / "Release" / "server.exe"
        if win_path.exists():
            return win_path

        # Linux/Mac
        unix_path = self.repo_root / "build" / "powerinfer" / "bin" / "server"
        if unix_path.exists():
            return unix_path

        raise FileNotFoundError("PowerInfer server binary not found.")

    def _build_cmd(
        self,
        model_path: Path,
        prompt: str,
        policy: Dict[str, Any],
    ) -> List[str]:
        """Build command line arguments from policy"""
        gen = policy.get("generation", {})
        rt = policy.get("runtime", {})

        cmd = [
            str(self.binary),
            "-m", str(model_path),
            "-p", prompt,
            "-n", str(gen.get("max_tokens", 256)),
            "-t", str(rt.get("threads", 8)),
        ]

        # GPU layers (optional)
        if "gpu_layers" in rt:
            cmd += ["--gpu-layers", str(rt["gpu_layers"])]

        # VRAM budget
        if "vram_budget_gb" in rt:
            cmd += ["--vram-budget", str(rt["vram_budget_gb"])]

        # Temperature
        if "temperature" in gen:
            cmd += ["--temp", str(gen["temperature"])]

        # Top-p sampling
        if "top_p" in gen:
            cmd += ["--top-p", str(gen["top_p"])]

        # Batch size
        if "batch_size" in rt:
            cmd += ["-b", str(rt["batch_size"])]

        # Context size
        if "context_size" in rt:
            cmd += ["-c", str(rt["context_size"])]

        return cmd

    def generate(
        self,
        prompt: str,
        policy: Dict[str, Any],
        model_root: Optional[Path] = None,
    ) -> str:
        """Generate text using PowerInfer"""
        if model_root is None:
            model_root = self.repo_root

        # Resolve model path
        model_path = model_root / policy["model_path"]
        if not model_path.exists():
            raise FileNotFoundError(f"Model not found: {model_path}")

        # Build command
        cmd = self._build_cmd(model_path, prompt, policy)

        logger.info(f"Running PowerInfer: {' '.join(cmd)}")

        # Execute
        try:
            proc = subprocess.run(
                cmd,
                check=True,
                capture_output=True,
                text=True,
                timeout=policy.get("runtime", {}).get("timeout", 300),
            )
            return proc.stdout
        except subprocess.TimeoutExpired:
            logger.error("PowerInfer generation timed out")
            raise
        except subprocess.CalledProcessError as e:
            logger.error(f"PowerInfer failed: {e.stderr}")
            raise

    def start_server(
        self,
        policy: Dict[str, Any],
        model_root: Optional[Path] = None,
        host: str = "0.0.0.0",
        port: int = 8081,
    ) -> subprocess.Popen:
        """Start PowerInfer API server"""
        if model_root is None:
            model_root = self.repo_root

        model_path = model_root / policy["model_path"]
        if not model_path.exists():
            raise FileNotFoundError(f"Model not found: {model_path}")

        rt = policy.get("runtime", {})

        cmd = [
            str(self.server_binary),
            "-m", str(model_path),
            "--host", host,
            "--port", str(port),
            "-t", str(rt.get("threads", 8)),
            "--vram-budget", str(rt.get("vram_budget_gb", 10)),
            "-c", str(rt.get("context_size", 2048)),
        ]

        logger.info(f"Starting PowerInfer server: {' '.join(cmd)}")

        return subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

    def validate_model(self, model_path: Path, policy: Dict[str, Any]) -> bool:
        """Validate model file and policy"""
        # Check file exists
        if not model_path.exists():
            logger.error(f"Model file not found: {model_path}")
            return False

        # Check file size
        size_mb = model_path.stat().st_size / (1024 * 1024)
        logger.info(f"Model size: {size_mb:.2f} MB")

        # Validate checksum if provided
        audit = policy.get("audit", {})
        if "checksum" in audit:
            # TODO: Implement checksum validation
            pass

        return True

    def info(self) -> Dict[str, Any]:
        """Get engine information"""
        return {
            "engine": "powerinfer",
            "binary": str(self.binary),
            "server_binary": str(self.server_binary),
            "version": self._get_version(),
        }

    def _get_version(self) -> str:
        """Get PowerInfer version"""
        try:
            proc = subprocess.run(
                [str(self.binary), "--version"],
                capture_output=True,
                text=True,
                timeout=5,
            )
            return proc.stdout.strip()
        except:
            return "unknown"
```

### Engine Registry

**File:** `engines/registry.py`

```python
"""Engine Registry for AI-Tools"""

from pathlib import Path
from typing import Dict, Type
from engines.powerinfer.backend import PowerInferBackend

# Engine registry
ENGINES: Dict[str, Type] = {
    "powerinfer": PowerInferBackend,
    # Add other engines here
    # "llama_cpp": LlamaCppBackend,
    # "vllm": VLLMBackend,
}


def get_engine(name: str, repo_root: Path):
    """Get engine backend by name"""
    if name not in ENGINES:
        raise ValueError(f"Unknown engine: {name}. Available: {list(ENGINES.keys())}")

    return ENGINES[name](repo_root)
```

## Phase 3: Policy Configuration

### Model Policy Example

**File:** `configs/models/powerinfer/bamboo-7b-dpo.yaml`

```yaml
# PowerInfer Model Policy: Bamboo-7B DPO
engine: powerinfer
model_path: models/powerinfer/bamboo-7b-dpo/model.powerinfer.gguf

generation:
  max_tokens: 512
  temperature: 0.7
  top_p: 0.9
  top_k: 40

runtime:
  threads: 8
  gpu_layers: 32
  vram_budget_gb: 10
  batch_size: 4
  context_size: 2048
  timeout: 300

audit:
  model_version: "bamboo-7b-dpo-v0.1"
  source_repo: "hf://PowerInfer/Bamboo-DPO-v0.1-gguf"
  checksum: "sha256:..."
  created_at: "2026-01-18"

metadata:
  description: "Bamboo-7B DPO - Fast and high-quality local LLM"
  use_cases:
    - "General conversation"
    - "Code generation"
    - "Question answering"
  performance:
    tokens_per_second: "15-20"
    vram_usage: "6-8GB"
```

**File:** `configs/models/powerinfer/prosparse-llama2-7b.yaml`

```yaml
# PowerInfer Model Policy: ProSparse Llama2-7B
engine: powerinfer
model_path: models/powerinfer/prosparse-llama2-7b/model.powerinfer.gguf

generation:
  max_tokens: 512
  temperature: 0.7
  top_p: 0.9

runtime:
  threads: 8
  gpu_layers: 28
  vram_budget_gb: 8
  batch_size: 4
  context_size: 2048

audit:
  model_version: "prosparse-llama2-7b-q4"
  source_repo: "hf://SparseLLM/prosparse-llama-2-7b"
  sparsity: "90%"

metadata:
  description: "ProSparse Llama2-7B - Fastest with 90% sparsity"
  performance:
    tokens_per_second: "20-25"
    vram_usage: "5-7GB"
```

## Phase 4: CLI Integration

### Main CLI Entry Point

**File:** `cli.py`

```python
#!/usr/bin/env python3
"""AI-Tools CLI with PowerInfer Integration"""

import argparse
import yaml
import logging
from pathlib import Path
from engines.registry import get_engine

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def load_policy(config_path: Path) -> dict:
    """Load model policy from YAML"""
    with open(config_path) as f:
        return yaml.safe_load(f)


def run_command(args):
    """Run inference with specified engine"""
    # Get repository root
    repo_root = Path(__file__).parent

    # Load policy
    config_path = repo_root / args.config
    policy = load_policy(config_path)

    # Validate engine matches
    if policy.get("engine") != args.engine:
        logger.warning(
            f"Engine mismatch: CLI={args.engine}, Policy={policy.get('engine')}"
        )

    # Get backend
    backend = get_engine(args.engine, repo_root)

    # Log configuration
    logger.info(f"Engine: {args.engine}")
    logger.info(f"Model: {args.model}")
    logger.info(f"Policy: {config_path}")

    # Generate
    try:
        output = backend.generate(
            prompt=args.prompt,
            policy=policy,
            model_root=repo_root,
        )
        print(output)
    except Exception as e:
        logger.error(f"Generation failed: {e}")
        return 1

    return 0


def server_command(args):
    """Start PowerInfer API server"""
    repo_root = Path(__file__).parent
    config_path = repo_root / args.config
    policy = load_policy(config_path)

    backend = get_engine(args.engine, repo_root)

    logger.info(f"Starting {args.engine} server on {args.host}:{args.port}")

    proc = backend.start_server(
        policy=policy,
        model_root=repo_root,
        host=args.host,
        port=args.port,
    )

    try:
        proc.wait()
    except KeyboardInterrupt:
        logger.info("Shutting down server...")
        proc.terminate()
        proc.wait()


def main():
    parser = argparse.ArgumentParser(description="AI-Tools CLI")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Run command
    run_parser = subparsers.add_parser("run", help="Run inference")
    run_parser.add_argument("--engine", required=True, help="Engine name")
    run_parser.add_argument("--model", required=True, help="Model name")
    run_parser.add_argument("--config", required=True, help="Policy config path")
    run_parser.add_argument("--prompt", required=True, help="Input prompt")
    run_parser.set_defaults(func=run_command)

    # Server command
    server_parser = subparsers.add_parser("server", help="Start API server")
    server_parser.add_argument("--engine", required=True, help="Engine name")
    server_parser.add_argument("--config", required=True, help="Policy config path")
    server_parser.add_argument("--host", default="0.0.0.0", help="Server host")
    server_parser.add_argument("--port", type=int, default=8081, help="Server port")
    server_parser.set_defaults(func=server_command)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    exit(main())
```

### Usage Examples

```bash
# Run inference
python cli.py run \
  --engine powerinfer \
  --model bamboo-7b-dpo \
  --config configs/models/powerinfer/bamboo-7b-dpo.yaml \
  --prompt "Explain PowerInfer in simple terms"

# Start API server
python cli.py server \
  --engine powerinfer \
  --config configs/models/powerinfer/bamboo-7b-dpo.yaml \
  --host 0.0.0.0 \
  --port 8081
```

## Phase 5: VS Code Integration

### Tasks Configuration

**File:** `.vscode/tasks.json`

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Build PowerInfer",
      "type": "shell",
      "windows": {
        "command": ".\\scripts\\powerinfer\\build.ps1"
      },
      "linux": {
        "command": "./scripts/powerinfer/build.sh"
      },
      "group": "build",
      "problemMatcher": []
    },
    {
      "label": "Run PowerInfer (Bamboo-7B)",
      "type": "shell",
      "command": "python cli.py run --engine powerinfer --model bamboo-7b-dpo --config configs/models/powerinfer/bamboo-7b-dpo.yaml --prompt \"Hello from PowerInfer\"",
      "dependsOn": "Build PowerInfer",
      "group": "test",
      "problemMatcher": []
    },
    {
      "label": "Start PowerInfer Server",
      "type": "shell",
      "command": "python cli.py server --engine powerinfer --config configs/models/powerinfer/bamboo-7b-dpo.yaml --port 8081",
      "isBackground": true,
      "problemMatcher": []
    }
  ]
}
```

### Launch Configuration

**File:** `.vscode/launch.json`

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "AI-Tools: PowerInfer Backend",
      "type": "python",
      "request": "launch",
      "program": "cli.py",
      "args": [
        "run",
        "--engine",
        "powerinfer",
        "--model",
        "bamboo-7b-dpo",
        "--config",
        "configs/models/powerinfer/bamboo-7b-dpo.yaml",
        "--prompt",
        "Debugging PowerInfer backend"
      ],
      "console": "integratedTerminal",
      "cwd": "${workspaceFolder}"
    },
    {
      "name": "AI-Tools: PowerInfer Server",
      "type": "python",
      "request": "launch",
      "program": "cli.py",
      "args": [
        "server",
        "--engine",
        "powerinfer",
        "--config",
        "configs/models/powerinfer/bamboo-7b-dpo.yaml",
        "--port",
        "8081"
      ],
      "console": "integratedTerminal",
      "cwd": "${workspaceFolder}"
    }
  ]
}
```

## Phase 6: Observability & Monitoring

### Metrics Collection

Add to `engines/powerinfer/backend.py`:

```python
import time
from dataclasses import dataclass
from typing import Optional

@dataclass
class GenerationMetrics:
    """Metrics for a generation request"""
    prompt_tokens: int
    completion_tokens: int
    total_tokens: int
    duration_seconds: float
    tokens_per_second: float
    gpu_memory_mb: Optional[float] = None
    cpu_percent: Optional[float] = None

class PowerInferBackend:
    # ... existing code ...

    def generate_with_metrics(
        self,
        prompt: str,
        policy: Dict[str, Any],
        model_root: Optional[Path] = None,
    ) -> tuple[str, GenerationMetrics]:
        """Generate with performance metrics"""
        start_time = time.time()

        # Run generation
        output = self.generate(prompt, policy, model_root)

        duration = time.time() - start_time

        # Calculate metrics (simplified)
        prompt_tokens = len(prompt.split())
        completion_tokens = len(output.split())
        total_tokens = prompt_tokens + completion_tokens

        metrics = GenerationMetrics(
            prompt_tokens=prompt_tokens,
            completion_tokens=completion_tokens,
            total_tokens=total_tokens,
            duration_seconds=duration,
            tokens_per_second=completion_tokens / duration if duration > 0 else 0,
        )

        return output, metrics
```

### Logging Configuration

```python
import logging
import json

class StructuredLogger:
    """Structured logging for observability"""

    def __init__(self, name: str):
        self.logger = logging.getLogger(name)

    def log_generation(
        self,
        model: str,
        policy_hash: str,
        metrics: GenerationMetrics,
        success: bool,
    ):
        """Log generation event"""
        self.logger.info(json.dumps({
            "event": "generation",
            "model": model,
            "policy_hash": policy_hash,
            "metrics": {
                "tokens_per_second": metrics.tokens_per_second,
                "duration_seconds": metrics.duration_seconds,
                "total_tokens": metrics.total_tokens,
            },
            "success": success,
        }))
```

## Next Steps

1. **Setup Repository Structure**

   ```bash
   # Create directories
   mkdir -p engines/powerinfer configs/models/powerinfer scripts/powerinfer models/powerinfer

   # Add submodule
   git submodule add https://github.com/SJTU-IPADS/PowerInfer external/powerinfer
   ```

2. **Build PowerInfer**

   ```powershell
   .\scripts\powerinfer\build.ps1
   ```

3. **Download Models**

   ```powershell
   .\download-powerinfer-models.ps1 -ModelName bamboo-dpo
   ```

4. **Test CLI**

   ```bash
   python cli.py run \
     --engine powerinfer \
     --model bamboo-7b-dpo \
     --config configs/models/powerinfer/bamboo-7b-dpo.yaml \
     --prompt "Test"
   ```

5. **Integrate with Open-WebUI**
   - Start PowerInfer server via CLI
   - Configure Open-WebUI to use `http://localhost:8081/v1`

This enterprise-grade integration provides:

- ✅ Policy-based configuration
- ✅ Multi-engine support
- ✅ Observability and metrics
- ✅ VS Code integration
- ✅ Proper abstraction layers
- ✅ Extensibility for future engines
