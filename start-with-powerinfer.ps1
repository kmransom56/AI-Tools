# Start AI Toolkit with PowerInfer and TurboSparse enabled
# This script sets environment variables and starts the web server with local LLM support

param(
    [switch]$SkipPowerInfer,
    [switch]$SkipTurboSparse
)

$ErrorActionPreference = 'Stop'

Write-Host '🚀 Starting AI Toolkit with Local LLM Support' -ForegroundColor Cyan
Write-Host '=' * 60 -ForegroundColor Gray

# Set PowerInfer environment variables
if (-not $SkipPowerInfer) {
    Write-Host '⚙️  Configuring PowerInfer...' -ForegroundColor Yellow
    $env:POWERINFER_HOST = 'http://localhost:8081'
    $env:POWERINFER_MODEL = 'bamboo-7b-dpo'
    Write-Host "   POWERINFER_HOST: $env:POWERINFER_HOST" -ForegroundColor Green
    Write-Host "   POWERINFER_MODEL: $env:POWERINFER_MODEL" -ForegroundColor Green
}
else {
    Write-Host '⏭️  Skipping PowerInfer configuration' -ForegroundColor Gray
}

# Set TurboSparse environment variables (if you have it set up)
if (-not $SkipTurboSparse) {
    Write-Host '⚙️  Configuring TurboSparse...' -ForegroundColor Yellow
    $env:TURBOSPARSE_HOST = 'http://localhost:8082'
    $env:TURBOSPARSE_MODEL = 'llama-7b'
    Write-Host "   TURBOSPARSE_HOST: $env:TURBOSPARSE_HOST" -ForegroundColor Green
    Write-Host "   TURBOSPARSE_MODEL: $env:TURBOSPARSE_MODEL" -ForegroundColor Green
}
else {
    Write-Host '⏭️  Skipping TurboSparse configuration' -ForegroundColor Gray
}

Write-Host ''
Write-Host '=' * 60 -ForegroundColor Gray
Write-Host '✅ Environment configured!' -ForegroundColor Green
Write-Host ''
Write-Host '📝 Next steps:' -ForegroundColor Cyan
Write-Host '   1. Start PowerInfer server: .\start-powerinfer-server.ps1' -ForegroundColor White
Write-Host '   2. The web server will now show PowerInfer as enabled' -ForegroundColor White
Write-Host ''
Write-Host '🌐 Starting web server...' -ForegroundColor Cyan

# Start the web server
python .\run_dev_server.py
