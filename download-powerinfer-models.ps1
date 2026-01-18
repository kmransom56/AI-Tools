# PowerInfer Model Download Script
# Downloads recommended models for local LLM inference

param(
    [string]$ModelName = 'bamboo-dpo',
    [string]$ModelsDir = '.\PowerInfer\models'
)

# Create models directory
New-Item -ItemType Directory -Force -Path $ModelsDir | Out-Null

Write-Host "`n🚀 PowerInfer Model Downloader" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

# Install huggingface-hub if not already installed
Write-Host '📦 Checking dependencies...' -ForegroundColor Yellow
pip install --quiet huggingface-hub

$models = @{
    'bamboo-dpo'    = @{
        repo = 'PowerInfer/Bamboo-DPO-v0.1-gguf'
        file = 'bamboo-7b-dpo-v0.1.Q4_0.gguf'
        size = '~4GB'
        desc = 'Bamboo-7B DPO Q4 (Recommended - Fast & High Quality)'
    }
    'bamboo-base'   = @{
        repo = 'PowerInfer/Bamboo-base-v0.1-gguf'
        file = 'bamboo-7b-v0.1.q4.powerinfer.gguf'
        size = '~4GB'
        desc = 'Bamboo-7B Base Q4 (Fast & Good Quality)'
    }
    'prosparse-7b'  = @{
        repo = 'SparseLLM/prosparse-llama-2-7b-gguf'
        file = 'prosparse-llama-2-7b.q4_0.gguf'
        size = '~3.5GB'
        desc = 'ProSparse Llama2-7B Q4 (Fastest - 90% Sparsity)'
    }
    'prosparse-13b' = @{
        repo = 'SparseLLM/prosparse-llama-2-13b-gguf'
        file = 'prosparse-llama-2-13b.q4_0.gguf'
        size = '~7GB'
        desc = 'ProSparse Llama2-13B Q4 (Larger - Better Reasoning)'
    }
}

if (-not $models.ContainsKey($ModelName)) {
    Write-Host "❌ Unknown model: $ModelName" -ForegroundColor Red
    Write-Host "`nAvailable models:" -ForegroundColor Yellow
    foreach ($key in $models.Keys) {
        $model = $models[$key]
        Write-Host "  • $key - $($model.desc) [$($model.size)]" -ForegroundColor White
    }
    exit 1
}

$selectedModel = $models[$ModelName]

Write-Host "📥 Downloading: $($selectedModel.desc)" -ForegroundColor Green
Write-Host "   Repository: $($selectedModel.repo)" -ForegroundColor Gray
Write-Host "   File: $($selectedModel.file)" -ForegroundColor Gray
Write-Host "   Size: $($selectedModel.size)" -ForegroundColor Gray
Write-Host "   Destination: $ModelsDir`n" -ForegroundColor Gray

# Download using Python
$pythonScript = @"
from huggingface_hub import hf_hub_download
import os

repo_id = '$($selectedModel.repo)'
filename = '$($selectedModel.file)'
local_dir = r'$ModelsDir'

print(f'Downloading {filename}...')
try:
    file_path = hf_hub_download(
        repo_id=repo_id,
        filename=filename,
        local_dir=local_dir,
        local_dir_use_symlinks=False
    )
    print(f'✅ Download complete: {file_path}')
except Exception as e:
    print(f'❌ Download failed: {e}')
    exit(1)
"@

$pythonScript | python -
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n⚠️  HuggingFace Hub download failed. Attempting direct download..." -ForegroundColor Yellow
    $directUrl = "https://huggingface.co/$($selectedModel.repo)/resolve/main/$($selectedModel.file)?download=true"
    $outputFile = "$ModelsDir\$($selectedModel.file)"
    
    try {
        Write-Host "   URL: $directUrl" -ForegroundColor Gray
        Invoke-WebRequest -Uri $directUrl -OutFile $outputFile -UseBasicParsing
        $LASTEXITCODE = 0
    }
    catch {
        Write-Host "❌ Direct download also failed: $_" -ForegroundColor Red
        exit 1
    }
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Model downloaded successfully!" -ForegroundColor Green
    Write-Host "`n📍 Model location:" -ForegroundColor Cyan
    Write-Host "   $ModelsDir\$($selectedModel.file)" -ForegroundColor White
    
    Write-Host "`n🚀 Next steps:" -ForegroundColor Cyan
    Write-Host '   1. Test the model locally:' -ForegroundColor White
    Write-Host '      cd PowerInfer' -ForegroundColor Gray
    Write-Host "      .\build\bin\main.exe -m ..\models\$($selectedModel.file) -n 128 -t 8 -p `"Hello!`" --vram-budget 10" -ForegroundColor Gray
    Write-Host "`n   2. Start PowerInfer server:" -ForegroundColor White
    Write-Host "      .\build\bin\server.exe -m ..\models\$($selectedModel.file) --host 0.0.0.0 --port 8081 --vram-budget 10 -t 8" -ForegroundColor Gray
    Write-Host "`n   3. Add to docker-compose.yml and integrate with Open-WebUI" -ForegroundColor White
}
else {
    Write-Host "`n❌ Download failed!" -ForegroundColor Red
    Write-Host '   Please check your internet connection and try again.' -ForegroundColor Yellow
    exit 1
}
