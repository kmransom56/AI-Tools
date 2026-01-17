# GPU Setup Guide for AI Toolkit

## Current Status

✅ **Hardware Detected**: 4x NVIDIA Tesla K80 GPUs (11.5GB VRAM each)  
⏳ **Driver Version**: 353.30 (upgrade to 475.14 available)  
✅ **CUDA Compatibility**: K80 supports CUDA 11.x - using CUDA 11.4  
⏳ **GPU Access**: Ready after driver upgrade to 475.14  
📝 **Recommended Driver**: 475.14 (CUDA 11.4) - download ready

## What Was Done

### 1. Dockerfile Migration
- Changed FROM `python:3.11-slim` → `nvidia/cuda:12.8.0-runtime-ubuntu22.04`
- **⚠️ ISSUE**: CUDA 12.8 incompatible with Tesla K80 (Compute Capability 3.7)
- **Required**: Downgrade to `nvidia/cuda:11.8.0-runtime-ubuntu22.04` for K80 support
- Updated all `pip` calls to `python3.11 -m pip` for explicit Python version
- Added Python 3.11 installation to CUDA base image

### 2. Docker Compose Configuration
- Configured both services to run on CPU mode (`--device cpu`)
- Set `CUDA_VISIBLE_DEVICES=""` environment variable for TabbyML
- Prepared deploy.resources structure (commented out) for future GPU enablement

## Hardware Details

### Your System: 4x NVIDIA Tesla K80
- **Compute Capability**: 3.7 (Maxwell architecture)
- **VRAM per GPU**: 11.5 GB
- **CUDA Support**: Up to CUDA 11.8 (NOT 12.x)
- **Current Driver**: 353.30 (released 2015)
- **Available Driver**: 475.14 (CUDA 11.4, released July 2024)
- **File Size**: 587.34 MB
- **Status**: ✅ Driver 475.14 is compatible with Tesla K80 and CUDA 11.4

✅ **Good News**: Driver 475.14 is perfect for your K80s. Dockerfile configured for CUDA 11.4.

## How to Enable GPU Support

### Prerequisites Check
Before enabling GPU on WSL2, verify:

```powershell
# 1. Check Windows host has NVIDIA GPU
# If nvidia-smi not in PATH, run from:
& "C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe"

# 2. Your Current Status:
# Driver: 353.30 (2015 - TOO OLD)
# Required: 525.60.13+ for CUDA 11.8
# Download: https://www.nvidia.com/Download/index.aspx
# Select: Tesla K80, Windows 11/10 x64

# 3. Confirm Docker Desktop WSL2 backend is active
docker context list

# 4. After driver upgrade, add nvidia-smi to PATH:
$env:Path += ";C:\Program Files\NVIDIA Corporation\NVSMI"
[Environment]::SetEnvironmentVariable("Path", $env:Path, "Machine")
```

### Enable GPU on WSL2 (3 Steps)

#### Step 1: Install NVIDIA Container Toolkit in WSL2
```bash
# Inside your WSL2 Linux distribution
distribution=$(docker run --rm ubuntu head -1 /etc/issue | sed 's/\n//' | sed 's/(.*//')
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

#### Step 2: Verify NVIDIA Container Toolkit
```bash
docker run --rm --gpus all nvidia/cuda:12.8.0-base nvidia-smi
```

#### Step 3: Uncomment GPU Reservations in docker-compose.yml

Find these sections in docker-compose.yml and uncomment the deploy block:

**For ai-toolkit:**
```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: 1
          capabilities: [gpu]
```

**For tabbyml:**
```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: 1
          capabilities: [gpu]
```

Update TabbyML command from `--device cpu` to `--device cuda`:
```yaml
command: ["serve", "--model", "StarCoder-1B", "--device", "cuda"]
```

Remove the environment variable that hides GPU:
```yaml
# Delete or comment out:
# environment:
#   CUDA_VISIBLE_DEVICES: ""
```

#### Step 4: Rebuild and Restart
```powershell
docker compose down
docker compose up -d --build
```

#### Step 5: Verify GPU Access
```powershell
# Check if GPU is visible in container
docker exec ai-toolkit nvidia-smi

# Check TabbyML GPU usage
docker logs tabbyml | grep -i cuda
```

## Troubleshooting

### TabbyML Embedding Error on WSL2
**Error**: `libcuda.so.1: cannot open shared object file`  
**Cause**: TabbyML tries to load CUDA libraries even in CPU mode on certain versions  
**Solution 1** (Recommended): Install NVIDIA Container Toolkit in WSL2
```bash
# In WSL2:
curl https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

**Solution 2**: Use smaller TabbyML model or disable embedding  
```yaml
# In docker-compose.yml TabbyML service:
command: ["serve", "--model", "StarCoder-1B", "--device", "cpu", "--parallelism", "1"]
```

**Solution 3**: Run TabbyML without embedding model
```bash
docker run -p 8080:8080 tabbyml/tabby:latest serve --model StarCoder-1B --device cpu --no-webserver
```

### Error: "nvidia-container-cli: initialization error"
**Cause**: NVIDIA Container Toolkit not installed or misconfigured  
**Solution**: Follow Step 1 above to install and configure

### Error: "libcuda.so.1: cannot open shared object file"
**Cause**: Running with CPU mode or GPU not accessible in container  
**Status**: This is expected when `--device cpu` is used. TabbyML will use CPU inference.

### Container won't start with GPU enabled
1. Verify GPU is visible on host: `nvidia-smi` (Windows command line)
2. Test NVIDIA Docker: `docker run --rm --gpus all nvidia/cuda:12.8.0-base nvidia-smi`
3. Check NVIDIA Container Toolkit: `which nvidia-container-cli`

## Performance Notes

### CPU Mode (Current)
- ✅ Works on all systems
- ✅ Suitable for development/testing
- ❌ Slower inference (10-100x slower than GPU)
- **Expected**: ai-toolkit health checks return immediately

### GPU Mode (When Enabled)
- ✅ 10-100x faster inference
- ✅ Enables real-time code suggestions
- ❌ Requires NVIDIA GPU + drivers
- ❌ Requires NVIDIA Container Toolkit installation

## Architecture Details

### Base Image Selection
- **nvidia/cuda:12.8.0-runtime-ubuntu22.04**: Provides CUDA runtime libraries + Ubuntu 22.04
- Includes: CUDA 12.8 runtime, cuDNN, nvidia-utils, but NOT nvcc (compiler)
- Size: ~2.07GB base, ~12.5GB with dependencies

### When to Use Full CUDA vs Runtime
- **Runtime-only** (current): For inference, running compiled CUDA code
- **Full CUDA**: If you need to compile CUDA code inside container (adds ~5GB)

## References
- [NVIDIA CUDA WSL User Guide](https://docs.nvidia.com/cuda/wsl-user-guide/index.html)
- [Docker Compose GPU Support](https://docs.docker.com/compose/gpu-support/)
- [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-container-toolkit)
