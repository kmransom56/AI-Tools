# PowerInfer Quick Start Guide

## Overview

PowerInfer is now integrated into your AI Toolkit! This guide will help you get it running on your RTX 3060.

## Status

✅ PowerInfer is **built** and ready  
✅ Bamboo-7B DPO model is **downloaded**  
✅ Server script is **configured**  
⏳ Ready to start!

## Quick Start (2 Steps)

### Step 1: Start PowerInfer Server

Open a **new PowerShell terminal** and run:

```powershell
cd "C:\Users\Keith Ransom\AI-Tools"
.\start-powerinfer-server.ps1
```

This will start the PowerInfer API server on `http://localhost:8081`.

**Expected output:**

```
🚀 Starting PowerInfer API Server...
Model: bamboo-7b-dpo-v0.1.Q4_0.gguf
Port: 8081
Threads: 8
VRAM Budget: 10GB
Context Size: 2048

✅ PowerInfer server binary found
✅ Model found

Starting PowerInfer server...
Access the API at: http://localhost:8081/v1
```

### Step 2: Start Web Server with PowerInfer Enabled

Open **another PowerShell terminal** and run:

```powershell
cd "C:\Users\Keith Ransom\AI-Tools"
.\start-with-powerinfer.ps1
```

This will:

1. Set environment variables (`POWERINFER_HOST`, `POWERINFER_MODEL`)
2. Start the web server with PowerInfer enabled

## Verify It's Working

1. Open your browser to `http://localhost:8000`
2. Check the status badges at the top - PowerInfer should now be **green** ✅
3. In the chat interface, select "PowerInfer (Local)" from the model dropdown
4. Send a message and get a response from your local LLM!

## Configuration Options

### Custom Parameters

You can customize the PowerInfer server with parameters:

```powershell
.\start-powerinfer-server.ps1 `
    -Port 8081 `
    -Threads 12 `
    -VramBudget 11 `
    -ContextSize 4096
```

**Parameters:**

- `-Port`: API server port (default: 8081)
- `-Threads`: CPU threads to use (default: 8)
- `-VramBudget`: VRAM budget in GB (default: 10)
- `-ContextSize`: Context window size (default: 2048)

### Skip PowerInfer or TurboSparse

```powershell
# Skip PowerInfer
.\start-with-powerinfer.ps1 -SkipPowerInfer

# Skip TurboSparse
.\start-with-powerinfer.ps1 -SkipTurboSparse

# Skip both (just start web server normally)
.\start-with-powerinfer.ps1 -SkipPowerInfer -SkipTurboSparse
```

## Troubleshooting

### PowerInfer shows as red/disabled

**Cause:** PowerInfer server is not running or environment variables are not set.

**Solution:**

1. Make sure PowerInfer server is running in a separate terminal
2. Restart the web server with `.\start-with-powerinfer.ps1`

### "Model not found" error

**Cause:** Model file doesn't exist or path is wrong.

**Solution:**

```powershell
# List available models
Get-ChildItem .\PowerInfer\models\*.gguf

# Use the exact filename
.\start-powerinfer-server.ps1 -Model "bamboo-7b-dpo-v0.1.Q4_0.gguf"
```

### Slow performance

**Solutions:**

1. Increase threads: `.\start-powerinfer-server.ps1 -Threads 12`
2. Increase VRAM budget: `.\start-powerinfer-server.ps1 -VramBudget 11`
3. Check GPU usage: `nvidia-smi`
4. Close other GPU applications

### Out of VRAM

**Solutions:**

1. Reduce VRAM budget: `.\start-powerinfer-server.ps1 -VramBudget 8`
2. Close other GPU applications
3. Use a smaller model

## Performance Expectations

On your RTX 3060 (12GB):

| Metric       | Expected Value |
| ------------ | -------------- |
| Speed        | 15-20 tokens/s |
| VRAM Usage   | 6-8 GB         |
| Latency      | <100ms         |
| Context Size | 2048 tokens    |

## Next Steps

1. **Test with different prompts** to see how it performs
2. **Adjust parameters** for optimal performance on your hardware
3. **Try other models** - download more from HuggingFace
4. **Integrate with other tools** - PowerInfer now works with all your AI toolkit features

## Environment Variables

The web app checks these environment variables:

```powershell
$env:POWERINFER_HOST = "http://localhost:8081"
$env:POWERINFER_MODEL = "bamboo-7b-dpo"
$env:TURBOSPARSE_HOST = "http://localhost:8082"  # Optional
$env:TURBOSPARSE_MODEL = "llama-7b"              # Optional
```

These are automatically set by `start-with-powerinfer.ps1`.

## For Tesla K80 Machine

When you clone this repo on your Tesla K80 machine:

1. The same scripts will work
2. You may want to increase VRAM budget (K80 has 24GB)
3. Adjust threads based on your CPU

```powershell
# Example for Tesla K80
.\start-powerinfer-server.ps1 -VramBudget 20 -Threads 16
```

---

**Ready to go!** 🚀

Start PowerInfer and enjoy fast, private, local LLM inference!
