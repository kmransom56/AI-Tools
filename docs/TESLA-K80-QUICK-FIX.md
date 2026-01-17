# Tesla K80 GPU Quick Fix Guide

## What We Found

Your system has **4x NVIDIA Tesla K80 GPUs** but they're not properly configured for Docker/AI workloads.

### Current Issues
1. ❌ **Old Driver**: Version 353.30 (from 2015) - too old for modern CUDA
2. ❌ **Wrong CUDA Version**: Dockerfile uses CUDA 12.8 (K80 only supports up to 11.8)
3. ❌ **Missing PATH**: nvidia-smi not accessible from PowerShell
4. ❌ **No NVIDIA Container Toolkit**: Required for Docker GPU access

## Quick Fixes Applied

### ✅ 1. Dockerfile Updated
Changed from CUDA 12.8 → 11.8 (K80 compatible)
- File: `Dockerfile.ai-toolkit`
- Line 1: Now uses `nvidia/cuda:11.8.0-runtime-ubuntu22.04`

### ✅ 2. PATH Fix (Temporary)
Run this in PowerShell **as Administrator**:
```powershell
$nvidiaSmiPath = "C:\Program Files\NVIDIA Corporation\NVSMI"
$env:Path += ";$nvidiaSmiPath"
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$nvidiaSmiPath", "Machine")
```

After this, you can run `nvidia-smi` from any PowerShell window.

## What You Need to Do

### Step 1: Upgrade NVIDIA Drivers (REQUIRED)

Your current driver (353.30) is **8+ years old**. Upgrade to **475.14** for CUDA 11.4 support.

1. **Download Driver 475.14**:
   - Go to: https://www.nvidia.com/Download/index.aspx
   - Product Type: Tesla
   - Product Series: K-Series
   - Product: Tesla K80
   - OS: Windows 11 or Windows 10 64-bit
   - Look for: **Version 475.14** (587.34 MB, CUDA 11.4)
   - Released: July 9, 2024

2. **Install Driver**:
   - Run installer as Administrator
   - Choose "Custom (Advanced)" installation
   - Check "Perform clean installation" (recommended)
   - Restart when prompted

3. **Verify Installation**:
   ```powershell
   nvidia-smi  # Should show driver version 525+
   ```

### Step 2: Install NVIDIA Container Toolkit (for Docker GPU Access)

This is required for Docker containers to use your GPUs.

**Option A: Windows + WSL2** (Recommended if using WSL2)
```bash
# Inside WSL2 Ubuntu distribution:
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

**Test it works:**
```bash
docker run --rm --gpus all nvidia/cuda:11.8.0-base nvidia-smi
```

You should see all 4 K80 GPUs listed.

### Step 3: Enable GPU in docker-compose.yml

Edit `docker-compose.yml` and uncomment the GPU sections:

**For ai-toolkit service**, find and uncomment:
```yaml
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1  # Or count: 4 to use all GPUs
              capabilities: [gpu]
```

**For tabbyml service**, change:
```yaml
    command: ["serve", "--model", "StarCoder-1B", "--device", "cuda"]
```

And uncomment:
```yaml
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
```

Remove the line:
```yaml
      CUDA_VISIBLE_DEVICES: ""  # DELETE THIS LINE
```

### Step 4: Rebuild and Test

```powershell
# Stop existing containers
docker compose down

# Rebuild with new CUDA 11.8 image
docker compose up --build -d

# Check logs
docker compose logs -f ai-toolkit

# Test GPU access inside container
docker exec -it ai-toolkit nvidia-smi
```

## Tesla K80 Specifications

| Specification | Value |
|---------------|-------|
| **Architecture** | Maxwell (Compute Capability 3.7) |
| **VRAM** | 11.5 GB per GPU (46 GB total for 4 GPUs) |
| **CUDA Support** | CUDA 11.4 (driver 475.14) |
| **FP32 Performance** | 8.73 TFLOPS (per K80 dual-GPU card) |
| **Memory Bandwidth** | 480 GB/s |
| **Released** | 2014 |
| **Best For** | ML training, deep learning, scientific computing |

## Troubleshooting

### "CUDA driver version is insufficient"
- Driver version mismatch
- Solution: Upgrade to 525.60+ as described in Step 1

### "nvidia-smi: command not found"
- PATH not set correctly
- Solution: Run PATH fix from "Quick Fixes Applied" section

### "docker: Error response from daemon: could not select device driver"
- NVIDIA Container Toolkit not installed
- Solution: Follow Step 2 above

### Container starts but no GPU visible
- Check: `docker exec -it ai-toolkit nvidia-smi`
- If empty: Deploy resources not configured in docker-compose.yml
- Solution: Follow Step 3

## Performance Expectations

### With 4x Tesla K80 (GPU Mode Enabled)
- ✅ FastAPI: ~100-200ms response (LLM inference with local models)
- ✅ TabbyML: Real-time code completion (<50ms)
- ✅ Can run multiple AI models simultaneously
- ✅ Good for fine-tuning smaller models (up to 7B parameters with quantization)

### Without GPU (Current CPU Mode)
- ⚠️ FastAPI: Still fast (proxies to cloud APIs)
- ❌ TabbyML: Very slow local inference (seconds per completion)
- ❌ Cannot run local large models efficiently

## Next Steps After Fixes

1. ✅ Complete driver upgrade (Step 1)
2. ✅ Install Container Toolkit (Step 2)
3. ✅ Enable GPU in docker-compose (Step 3)
4. ✅ Test with: `docker run --rm --gpus all nvidia/cuda:11.8.0-base nvidia-smi`
5. 🚀 Deploy local LLM models (optional):
   - Llama 2 7B
   - CodeLlama 7B
   - StarCoder 7B
   - Mistral 7B

All these models will fit comfortably in your 11.5GB VRAM per GPU!

---

**Status**: Action Required  
**Priority**: High (driver upgrade needed)  
**Time to Complete**: ~30 minutes (including driver download)
