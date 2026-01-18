# PowerInfer Setup Guide for Tesla K80 (Kepler Architecture)

## Hardware Overview

**Your Setup:**

- **2x Tesla K80** (Dual-GPU cards)
- **24GB VRAM per GPU** = **48GB total**
- **Architecture**: Kepler (GK210)
- **CUDA Compute Capability**: 3.7

## Important Notes for Kepler Architecture

### CUDA Compatibility

Tesla K80 uses **Kepler architecture (Compute Capability 3.7)**, which has some limitations:

1. **CUDA Version**: Maximum supported CUDA version is **11.8**
   - Newer CUDA versions (12.x) don't support Kepler
   - PowerInfer builds should target CUDA 11.8 or lower

2. **Performance Expectations**:
   - **Slower than RTX 3060** for inference (older architecture)
   - **But MUCH more VRAM** (48GB vs 12GB)
   - Can run **much larger models** (13B, 30B, even 70B quantized)
   - Better for **batch processing** than real-time chat

3. **Recommended Models for K80**:
   - **ProSparse Llama2-13B Q4** (~7GB) - Excellent fit
   - **Llama2-30B Q4** (~16GB) - Good fit
   - **Llama2-70B Q3** (~28GB) - Possible!
   - **Multiple models simultaneously** - You have the VRAM!

## PowerInfer Configuration for K80

### Recommended Settings

```powershell
# Start PowerInfer with K80-optimized settings
.\start-powerinfer-server.ps1 `
    -Port 8081 `
    -Threads 16 `
    -VramBudget 20 `
    -ContextSize 4096
```

**Parameter Explanations:**

- `-Threads 16`: Use more CPU threads (K80 is slower, CPU helps)
- `-VramBudget 20`: Conservative 20GB (leaves headroom)
- `-ContextSize 4096`: Larger context window (you have the VRAM!)

### Environment Variables

```powershell
# Set these in your PowerShell profile or startup script
$env:POWERINFER_HOST = "http://localhost:8081"
$env:POWERINFER_MODEL = "bamboo-7b-dpo"  # Or larger model!
$env:CUDA_VISIBLE_DEVICES = "0,1"  # Use both K80 GPUs
```

## Building PowerInfer for Kepler

### CUDA 11.8 Build

If you need to rebuild PowerInfer for K80:

```powershell
cd PowerInfer
mkdir build
cd build

# Configure with CUDA 11.8 and Kepler support
cmake .. `
    -DCMAKE_BUILD_TYPE=Release `
    -DLLAMA_CUBLAS=ON `
    -DCMAKE_CUDA_ARCHITECTURES=37 `
    -DCUDA_TOOLKIT_ROOT_DIR="C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8"

# Build
cmake --build . --config Release -j 16
```

**Key flags:**

- `-DCMAKE_CUDA_ARCHITECTURES=37`: Kepler compute capability
- Ensure CUDA 11.8 is installed (not 12.x)

## Performance Expectations

### Bamboo-7B DPO Q4 (~4GB)

| Metric      | RTX 3060    | Tesla K80 (2x) |
| ----------- | ----------- | -------------- |
| Speed       | 15-20 tok/s | **8-12 tok/s** |
| VRAM        | 6-8 GB      | 4-6 GB         |
| First Token | <5s         | **10-15s**     |
| Context     | 2048        | **4096+**      |

### ProSparse Llama2-13B Q4 (~7GB)

| Metric      | RTX 3060    | Tesla K80 (2x) |
| ----------- | ----------- | -------------- |
| Speed       | 10-15 tok/s | **5-8 tok/s**  |
| VRAM        | 9-11 GB     | 7-9 GB         |
| First Token | 5-10s       | **15-20s**     |
| Context     | 2048        | **4096+**      |

### Llama2-70B Q3 (~28GB) - K80 ONLY!

| Metric      | RTX 3060 | Tesla K80 (2x) |
| ----------- | -------- | -------------- |
| Speed       | ❌ OOM   | **2-4 tok/s**  |
| VRAM        | ❌ 12GB  | 28-32 GB       |
| First Token | ❌       | **30-60s**     |
| Context     | ❌       | **2048**       |

## Optimization Tips for K80

### 1. Use Larger Models

You have the VRAM - use it!

```powershell
# Download a larger model
.\download-powerinfer-models.ps1 -ModelName prosparse-13b

# Start with larger model
.\start-powerinfer-server.ps1 `
    -Model "prosparse-llama2-13b.q4.powerinfer.gguf" `
    -VramBudget 20 `
    -Threads 16
```

### 2. Batch Processing

K80s excel at batch processing rather than interactive chat:

```python
# Example: Batch process multiple prompts
prompts = [
    "Explain quantum computing",
    "Write a Python function for sorting",
    "Summarize the history of AI"
]

for prompt in prompts:
    response = call_powerinfer(host, prompt)
    print(f"Q: {prompt}\nA: {response}\n")
```

### 3. Multi-Model Setup

Run multiple models simultaneously:

```powershell
# Terminal 1: Smaller fast model for chat
.\start-powerinfer-server.ps1 -Port 8081 -Model "bamboo-7b-dpo.gguf" -VramBudget 8

# Terminal 2: Larger quality model for analysis
.\start-powerinfer-server.ps1 -Port 8082 -Model "prosparse-13b.gguf" -VramBudget 15
```

### 4. Increase Context Window

With 48GB, you can afford larger contexts:

```powershell
.\start-powerinfer-server.ps1 `
    -ContextSize 8192 `  # 8K context!
    -VramBudget 22
```

## Troubleshooting K80-Specific Issues

### Issue: "CUDA error: no kernel image available"

**Cause**: PowerInfer built for newer architecture (Ampere/Ada)

**Solution**: Rebuild with `-DCMAKE_CUDA_ARCHITECTURES=37`

### Issue: Slow performance

**Expected**: K80 is older, slower than modern GPUs

**Mitigations**:

1. Increase CPU threads: `-Threads 24`
2. Use quantized models (Q4, Q3)
3. Reduce context size if not needed
4. Enable CPU offloading for some layers

### Issue: Out of memory with 48GB available

**Cause**: Model + context + overhead exceeds VRAM

**Solution**:

```powershell
# Reduce VRAM budget to leave headroom
.\start-powerinfer-server.ps1 -VramBudget 18  # Instead of 20+
```

## Recommended Workflow for K80

### Development (Fast Iteration)

Use smaller model for quick testing:

```powershell
.\start-powerinfer-server.ps1 `
    -Model "bamboo-7b-dpo.gguf" `
    -VramBudget 8 `
    -Threads 12
```

### Production (Quality)

Use larger model for better results:

```powershell
.\start-powerinfer-server.ps1 `
    -Model "prosparse-llama2-13b.gguf" `
    -VramBudget 20 `
    -Threads 16 `
    -ContextSize 4096
```

### Batch Processing (Maximum Throughput)

Use largest model that fits:

```powershell
.\start-powerinfer-server.ps1 `
    -Model "llama2-70b-q3.gguf" `
    -VramBudget 40 `
    -Threads 24 `
    -ContextSize 2048
```

## Comparison: K80 vs RTX 3060

| Feature          | RTX 3060         | Tesla K80 (2x)             |
| ---------------- | ---------------- | -------------------------- |
| **Architecture** | Ampere           | Kepler                     |
| **VRAM**         | 12GB             | **48GB** ✅                |
| **Speed**        | **Fast** ✅      | Slower                     |
| **Max Model**    | 13B Q4           | **70B Q3** ✅              |
| **Context**      | 2048             | **8192+** ✅               |
| **Power**        | 170W             | 300W                       |
| **Best For**     | Interactive chat | **Large models, batch** ✅ |

## Next Steps

1. **Clone the repo** on your K80 machine
2. **Check CUDA version**: `nvcc --version` (should be ≤11.8)
3. **Test with current model**: `.\start-powerinfer-server.ps1`
4. **Download larger model**: `.\download-powerinfer-models.ps1 -ModelName prosparse-13b`
5. **Benchmark performance**: Compare 7B vs 13B vs larger models

## Key Takeaway

Your K80 setup is **perfect for running larger models** that won't fit on consumer GPUs. While it's slower per token, you can run models that are **4x larger** than what fits on an RTX 3060!

**Strategy**: Use RTX 3060 for fast interactive chat, use K80s for large model inference and batch processing.

---

**Ready to unleash 48GB of VRAM!** 🚀
