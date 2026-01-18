# PowerInfer Quick Start Guide

## 🚀 Get Started in 3 Steps

### Step 1: Setup PowerInfer (15-20 minutes)

```powershell
# Run the automated setup script
.\setup-powerinfer.ps1
```

This will:

- ✅ Check prerequisites (CMake, Python, CUDA)
- ✅ Clone PowerInfer repository
- ✅ Install Python dependencies
- ✅ Build PowerInfer with CUDA support for your RTX 3060
- ✅ Test the build

### Step 2: Download a Model (30-60 minutes)

```powershell
# Download recommended model (Bamboo-7B DPO Q4 - ~4GB)
.\download-powerinfer-models.ps1 -ModelName bamboo-dpo
```

**Available Models:**

- `bamboo-dpo` - Bamboo-7B DPO Q4 (~4GB) - **Recommended**
- `bamboo-base` - Bamboo-7B Base Q4 (~4GB)
- `prosparse-7b` - ProSparse Llama2-7B Q4 (~3.5GB) - Fastest
- `prosparse-13b` - ProSparse Llama2-13B Q4 (~7GB) - Larger

### Step 3: Test Locally (5 minutes)

```powershell
cd PowerInfer

# Test inference
.\build\bin\Release\main.exe `
  -m ..\PowerInfer\models\bamboo-7b-dpo-v0.1.q4.powerinfer.gguf `
  -n 128 `
  -t 8 `
  -p "Write a short poem about AI" `
  --vram-budget 10
```

Expected output: Fast text generation at 15-20 tokens/s!

---

## 🐳 Docker Integration (Optional)

### Build and Start PowerInfer Container

```powershell
# Build the Docker image
docker-compose build powerinfer

# Start PowerInfer server
docker-compose up -d powerinfer

# Check logs
docker logs powerinfer -f
```

### Test the API

```powershell
# Test health endpoint
curl http://localhost:8081/health

# Test chat completion
curl http://localhost:8081/v1/chat/completions `
  -H "Content-Type: application/json" `
  -d '{
    "model": "bamboo-7b-dpo",
    "messages": [{"role": "user", "content": "Hello!"}],
    "temperature": 0.7,
    "max_tokens": 100
  }'
```

---

## 🌐 Integrate with Open-WebUI

### Option 1: Via Web Interface

1. Open http://localhost:3000
2. Go to **Settings** → **Connections**
3. Add new OpenAI API connection:
   - **Name**: PowerInfer Local
   - **API Base URL**: `http://powerinfer:8080/v1`
   - **API Key**: `not-needed`
   - **Model**: `bamboo-7b-dpo`
4. Save and test

### Option 2: Via Environment Variables

Already configured in docker-compose.yml! Just restart open-webui:

```powershell
docker-compose restart open-webui
```

---

## 📊 Performance Tuning

### VRAM Budget

Adjust based on your needs:

```powershell
# Conservative (8GB) - Best for multitasking
--vram-budget 8

# Balanced (10GB) - Recommended
--vram-budget 10

# Aggressive (11GB) - Maximum performance
--vram-budget 11
```

### Thread Count

Optimize for your CPU:

```powershell
# Check CPU cores
Get-WmiObject Win32_Processor | Select-Object NumberOfCores, NumberOfLogicalProcessors

# Use 50-75% of logical processors
-t 8  # For 16-thread CPU
```

### Context Size

Balance memory vs context:

```powershell
-c 2048  # 2K context (default, fast)
-c 4096  # 4K context (more memory)
-c 8192  # 8K context (requires more VRAM)
```

---

## 🔍 Monitoring

### Check GPU Usage

```powershell
# Watch GPU utilization
nvidia-smi -l 1

# Or in Docker
docker exec powerinfer nvidia-smi
```

### View Logs

```powershell
# PowerInfer logs
docker logs powerinfer -f

# Check for errors
docker logs powerinfer | Select-String "error"

# Check performance
docker logs powerinfer | Select-String "tokens/s"
```

---

## ❓ Troubleshooting

### Issue: Out of VRAM

**Solution:**

```powershell
# Reduce VRAM budget
--vram-budget 8

# Or use smaller model
.\download-powerinfer-models.ps1 -ModelName prosparse-7b
```

### Issue: Slow Performance

**Solutions:**

1. Increase thread count: `-t 12`
2. Check GPU is being used: `nvidia-smi`
3. Ensure model is quantized (Q4)
4. Close other GPU applications

### Issue: Server Won't Start

**Check:**

```powershell
# Verify model exists
Test-Path .\PowerInfer\models\bamboo-7b-dpo-v0.1.q4.powerinfer.gguf

# Check port availability
netstat -ano | findstr :8081

# View detailed logs
docker logs powerinfer
```

### Issue: Connection Refused from Open-WebUI

**Solutions:**

1. Verify PowerInfer is running: `docker ps | findstr powerinfer`
2. Test API directly: `curl http://localhost:8081/health`
3. Check network: `docker network ls`
4. Restart both containers:
   ```powershell
   docker-compose restart powerinfer open-webui
   ```

---

## 📈 Expected Performance

### On Dual RTX 3060 (12GB each)

| Model                   | Speed       | VRAM Usage | Quality   |
| ----------------------- | ----------- | ---------- | --------- |
| Bamboo-7B DPO Q4        | 15-20 tok/s | 6-8GB      | Excellent |
| ProSparse Llama2-7B Q4  | 20-25 tok/s | 5-7GB      | Good      |
| ProSparse Llama2-13B Q4 | 10-15 tok/s | 9-11GB     | Better    |

---

## 🎯 Usage Recommendations

### Use PowerInfer For:

- ✅ Fast responses (15-20 tok/s)
- ✅ Privacy-sensitive data
- ✅ High-volume requests
- ✅ Development/testing
- ✅ Offline usage

### Use Cloud LLMs For:

- 🌐 Latest models (GPT-4, Claude 3.5)
- 🌐 Very large models (>70B)
- 🌐 Specialized capabilities
- 🌐 Occasional usage

### Hybrid Approach (Best!)

Use PowerInfer as default, fallback to cloud for complex tasks.

---

## 📚 Additional Resources

- **Full Integration Guide**: `POWERINFER-INTEGRATION.md`
- **PowerInfer GitHub**: https://github.com/SJTU-IPADS/PowerInfer
- **Model Hub**: https://huggingface.co/PowerInfer
- **Performance Tips**: https://github.com/SJTU-IPADS/PowerInfer/blob/main/docs/token_generation_performance_tips.md

---

## ✅ Success Checklist

- [ ] PowerInfer built successfully
- [ ] Model downloaded (Bamboo-7B DPO recommended)
- [ ] Local inference test passed
- [ ] PowerInfer server running
- [ ] API endpoint responding
- [ ] Integrated with Open-WebUI
- [ ] Performance optimized (15-20 tok/s)
- [ ] Monitoring configured

---

**Need Help?** Check `POWERINFER-INTEGRATION.md` for detailed troubleshooting and advanced configuration.
