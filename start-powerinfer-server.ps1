# Start PowerInfer Server
# This script starts the PowerInfer API server for local LLM inference

param(
    [string]$Model = 'bamboo-7b-dpo-v0.1.Q4_0.gguf',
    [int]$Port = 8081,
    [int]$Threads = 8,
    [int]$VramBudget = 10,
    [int]$ContextSize = 2048
)

$ErrorActionPreference = 'Stop'

Write-Host '🚀 Starting PowerInfer API Server...' -ForegroundColor Cyan
Write-Host "Model: $Model" -ForegroundColor Yellow
Write-Host "Port: $Port" -ForegroundColor Yellow
Write-Host "Threads: $Threads" -ForegroundColor Yellow
Write-Host "VRAM Budget: ${VramBudget}GB" -ForegroundColor Yellow
Write-Host "Context Size: $ContextSize" -ForegroundColor Yellow
Write-Host ''

# Check if PowerInfer is built
$PowerInferBin = Join-Path $PSScriptRoot 'PowerInfer\build\bin\Release\server.exe'
if (-not (Test-Path $PowerInferBin)) {
    Write-Host "❌ PowerInfer server binary not found at: $PowerInferBin" -ForegroundColor Red
    Write-Host 'Run .\setup-powerinfer.ps1 to build PowerInfer' -ForegroundColor Yellow
    exit 1
}

# Check if model exists
$ModelPath = Join-Path $PSScriptRoot "PowerInfer\models\$Model"
if (-not (Test-Path $ModelPath)) {
    Write-Host "❌ Model not found at: $ModelPath" -ForegroundColor Red
    Write-Host 'Available models:' -ForegroundColor Yellow
    Get-ChildItem (Join-Path $PSScriptRoot 'PowerInfer\models') -Filter '*.gguf' | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Cyan
    }
    exit 1
}

Write-Host '✅ PowerInfer server binary found' -ForegroundColor Green
Write-Host '✅ Model found' -ForegroundColor Green
Write-Host ''

# Start the server
Write-Host 'Starting PowerInfer server...' -ForegroundColor Cyan
Write-Host "Access the API at: http://localhost:$Port/v1" -ForegroundColor Green
Write-Host 'Press Ctrl+C to stop the server' -ForegroundColor Yellow
Write-Host ''

# Run PowerInfer in server mode
& $PowerInferBin `
    --model $ModelPath `
    --threads $Threads `
    --vram-budget $VramBudget `
    --ctx-size $ContextSize `
    --port $Port `
    --host 0.0.0.0
