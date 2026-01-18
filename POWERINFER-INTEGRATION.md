# PowerInfer Integration Plan

## Overview

PowerInfer is a high-speed LLM inference engine optimized for consumer-grade GPUs that can serve as a local alternative to cloud LLMs in your open-webui setup.

### Key Features

- **11x faster** than llama.cpp on RTX 4090 with Falcon-40B
- **Hybrid CPU/GPU** inference using activation locality
- **Low VRAM usage** through hot/cold neuron separation
- **Compatible** with open-webui via OpenAI-compatible API server
- **Optimized for RTX 3060** - your current hardware!

### Performance on RTX 4090 (Reference)

- Falcon-40B FP16: 13-29 tokens/s
- Llama2-70B: Up to 3x speedup vs llama.cpp
- Supports INT4 quantization for lower VRAM usage

## Architecture

```
┌─────────────────┐
│   Open-WebUI    │ (Port 3000)
│  (User Interface)│
└────────┬────────┘
         │ HTTP API
         ▼
┌─────────────────┐
│  PowerInfer     │ (Port 8081)
│  Server (API)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  PowerInfer     │
│  Engine (GPU)   │
│  RTX 3060 x2    │
└─────────────────┘
```

## Implementation Steps

### Phase 1: Build PowerInfer

1. **Clone and Build PowerInfer**

   ```bash
   # Clone repository
   git clone https://github.com/SJTU-IPADS/PowerInfer
   cd PowerInfer
   pip install -r requirements.txt

   # Build with CUDA support for RTX 3060
   cmake -S . -B build -DLLAMA_CUBLAS=ON
   cmake --build build --config Release
   ```

2. **Download Optimized Models**

   Recommended models for RTX 3060 (12GB VRAM each):
   - **Bamboo-7B** (Fast, good quality)
     - Base: https://huggingface.co/PowerInfer/Bamboo-base-v0.1-gguf
     - DPO: https://huggingface.co/PowerInfer/Bamboo-DPO-v0.1-gguf
   - **ProSparse Llama2-7B** (90% sparsity, fast)
     - https://huggingface.co/SparseLLM/prosparse-llama-2-7b
   - **ProSparse Llama2-13B** (Larger, still efficient)
     - https://huggingface.co/SparseLLM/prosparse-llama-2-13b

### Phase 2: Docker Integration

Create a PowerInfer service in docker-compose.yml:

```yaml
powerinfer:
  build:
    context: ./PowerInfer
    dockerfile: Dockerfile.powerinfer
  container_name: powerinfer
  ports:
    - "8081:8080" # API server port
  volumes:
    - ./PowerInfer/models:/models
    - ./PowerInfer/build:/app/build
  environment:
    - MODEL_PATH=/models/bamboo-7b-v0.1.q4.powerinfer.gguf
    - VRAM_BUDGET=10 # GB per GPU
    - THREADS=8
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: all
            capabilities: [gpu]
  command: >
    /app/build/bin/server
    -m /models/bamboo-7b-v0.1.q4.powerinfer.gguf
    --host 0.0.0.0
    --port 8080
    --vram-budget 10
    -t 8
    -c 2048
  restart: unless-stopped
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 60s
```

### Phase 3: Dockerfile Creation

Create `PowerInfer/Dockerfile.powerinfer`:

```dockerfile
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    python3 \
    python3-pip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy PowerInfer source
COPY . /app

# Install Python dependencies
RUN pip3 install -r requirements.txt

# Build PowerInfer with CUDA support
RUN cmake -S . -B build -DLLAMA_CUBLAS=ON && \
    cmake --build build --config Release

# Expose API port
EXPOSE 8080

# Default command (will be overridden by docker-compose)
CMD ["/app/build/bin/server", "--help"]
```

### Phase 4: Model Download Script

Create `PowerInfer/download_models.ps1`:

```powershell
# Download recommended models for PowerInfer

$modelsDir = ".\models"
New-Item -ItemType Directory -Force -Path $modelsDir

Write-Host "Downloading Bamboo-7B DPO (Recommended)..." -ForegroundColor Green
# Using huggingface-cli for faster downloads
pip install huggingface-hub

# Download Bamboo-7B DPO Q4
python -c "from huggingface_hub import hf_hub_download; hf_hub_download(repo_id='PowerInfer/Bamboo-DPO-v0.1-gguf', filename='bamboo-7b-dpo-v0.1.q4.powerinfer.gguf', local_dir='$modelsDir')"

Write-Host "Model downloaded successfully!" -ForegroundColor Green
Write-Host "Location: $modelsDir\bamboo-7b-dpo-v0.1.q4.powerinfer.gguf"
```

### Phase 5: Open-WebUI Configuration

Configure open-webui to use PowerInfer as an OpenAI-compatible endpoint:

1. **Access Open-WebUI Admin Panel**
   - Navigate to http://localhost:3000
   - Go to Settings → Connections

2. **Add PowerInfer as OpenAI API**
   - API Base URL: `http://powerinfer:8080/v1`
   - API Key: `not-needed` (PowerInfer doesn't require auth)
   - Model: `bamboo-7b-dpo` (or your chosen model)

3. **Alternative: Environment Variables**

   Add to docker-compose.yml open-webui service:

   ```yaml
   environment:
     - OPENAI_API_BASE_URLS=http://host.docker.internal:8000/v1;http://powerinfer:8080/v1
     - OPENAI_API_KEYS=sk-xxx;not-needed
   ```

## Performance Optimization

### VRAM Budget Configuration

For dual RTX 3060 (12GB each):

- **Conservative (8GB per GPU)**: Best for multitasking

  ```bash
  --vram-budget 8
  ```

- **Balanced (10GB per GPU)**: Recommended

  ```bash
  --vram-budget 10
  ```

- **Aggressive (11GB per GPU)**: Maximum performance
  ```bash
  --vram-budget 11
  ```

### Thread Configuration

For optimal CPU performance:

```bash
-t 8  # Use 8 threads (adjust based on your CPU)
```

### Context Length

Adjust based on your needs:

```bash
-c 2048  # 2K context (default)
-c 4096  # 4K context (more memory)
-c 8192  # 8K context (requires more VRAM)
```

## Model Recommendations

### For RTX 3060 (12GB VRAM)

1. **Best Overall: Bamboo-7B DPO Q4**
   - Size: ~4GB
   - Speed: ~15-20 tokens/s (estimated)
   - Quality: Excellent for general tasks
   - VRAM: ~6-8GB

2. **Fastest: ProSparse Llama2-7B Q4**
   - Size: ~3.5GB
   - Speed: ~20-25 tokens/s (estimated)
   - Quality: Good, 90% sparsity
   - VRAM: ~5-7GB

3. **Larger Model: ProSparse Llama2-13B Q4**
   - Size: ~7GB
   - Speed: ~10-15 tokens/s (estimated)
   - Quality: Better reasoning
   - VRAM: ~9-11GB

## Testing and Validation

### 1. Test PowerInfer Binary

```bash
cd PowerInfer
./build/bin/main -m ./models/bamboo-7b-dpo-v0.1.q4.powerinfer.gguf \
  -n 128 -t 8 -p "Once upon a time" --vram-budget 10
```

### 2. Test PowerInfer Server

```bash
./build/bin/server -m ./models/bamboo-7b-dpo-v0.1.q4.powerinfer.gguf \
  --host 0.0.0.0 --port 8081 --vram-budget 10 -t 8
```

### 3. Test API Endpoint

```powershell
curl http://localhost:8081/v1/chat/completions `
  -H "Content-Type: application/json" `
  -d '{
    "model": "bamboo-7b-dpo",
    "messages": [{"role": "user", "content": "Hello!"}],
    "temperature": 0.7
  }'
```

### 4. Test in Open-WebUI

- Open http://localhost:3000
- Select PowerInfer model from dropdown
- Send a test message
- Verify response speed and quality

## Monitoring and Troubleshooting

### Check GPU Usage

```bash
docker exec powerinfer nvidia-smi
```

### View PowerInfer Logs

```bash
docker logs powerinfer -f
```

### Performance Metrics

```bash
# Check token generation speed
docker logs powerinfer | grep "tokens/s"
```

### Common Issues

1. **Out of VRAM**
   - Reduce `--vram-budget` value
   - Use smaller model or Q4 quantization
   - Close other GPU applications

2. **Slow Performance**
   - Increase thread count `-t`
   - Check GPU utilization with `nvidia-smi`
   - Ensure model is properly quantized

3. **Connection Refused**
   - Verify PowerInfer server is running
   - Check port mapping in docker-compose
   - Ensure firewall allows port 8081

## Comparison: PowerInfer vs Cloud LLMs

### Advantages of PowerInfer

✅ **Privacy**: All data stays local  
✅ **Cost**: No API fees after initial setup  
✅ **Speed**: 11x faster than llama.cpp  
✅ **Latency**: No network delays  
✅ **Availability**: Works offline

### When to Use Cloud LLMs

- Need latest models (GPT-4, Claude 3.5)
- Require very large models (>70B parameters)
- Occasional usage (cost-effective)
- Need specific capabilities (vision, function calling)

### Hybrid Approach (Recommended)

Use PowerInfer for:

- Fast responses
- Privacy-sensitive data
- High-volume requests
- Development/testing

Use Cloud LLMs for:

- Complex reasoning tasks
- Latest model capabilities
- Specialized tasks
- Fallback when local is unavailable

## Next Steps

1. ✅ Build PowerInfer with CUDA support
2. ✅ Download recommended model (Bamboo-7B DPO Q4)
3. ✅ Create Dockerfile and docker-compose configuration
4. ✅ Test PowerInfer server locally
5. ✅ Integrate with Open-WebUI
6. ✅ Configure model selection in UI
7. ✅ Performance testing and optimization
8. ✅ Set up monitoring and logging

## Resources

- **PowerInfer GitHub**: https://github.com/SJTU-IPADS/PowerInfer
- **PowerInfer Paper**: https://ipads.se.sjtu.edu.cn/_media/publications/powerinfer-20231219.pdf
- **Model Hub**: https://huggingface.co/PowerInfer
- **ReLU Models**: https://huggingface.co/SparseLLM
- **Performance Tips**: https://github.com/SJTU-IPADS/PowerInfer/blob/main/docs/token_generation_performance_tips.md

## Estimated Timeline

- **Setup**: 1-2 hours
- **Model Download**: 30-60 minutes (depending on internet speed)
- **Testing**: 30 minutes
- **Integration**: 30 minutes
- **Total**: 3-4 hours

## Expected Results

With dual RTX 3060 (12GB each):

- **Bamboo-7B Q4**: 15-20 tokens/s
- **ProSparse Llama2-7B Q4**: 20-25 tokens/s
- **ProSparse Llama2-13B Q4**: 10-15 tokens/s

This provides a fast, private, and cost-effective alternative to cloud LLMs for most tasks!
