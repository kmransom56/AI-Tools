# PowerInfer Setup and Build Script
# Clones, builds, and tests PowerInfer for Windows with CUDA support

param(
    [switch]$SkipBuild = $false,
    [switch]$SkipTest = $false
)

$ErrorActionPreference = "Stop"

Write-Host "`n🚀 PowerInfer Setup Script" -ForegroundColor Cyan
Write-Host "==========================`n" -ForegroundColor Cyan

# Check prerequisites
Write-Host "📋 Checking prerequisites..." -ForegroundColor Yellow

# Check CMake
try {
    $cmakeVersion = cmake --version | Select-String "version" | Out-String
    Write-Host "  ✅ CMake: $($cmakeVersion.Trim())" -ForegroundColor Green
}
catch {
    Write-Host "  ❌ CMake not found! Please install CMake 3.17+" -ForegroundColor Red
    exit 1
}

# Check Python
try {
    $pythonVersion = python --version 2>&1
    Write-Host "  ✅ Python: $pythonVersion" -ForegroundColor Green
}
catch {
    Write-Host "  ❌ Python not found! Please install Python 3.8+" -ForegroundColor Red
    exit 1
}

# Check CUDA
try {
    $nvccVersion = nvcc --version | Select-String "release" | Out-String
    Write-Host "  ✅ CUDA: $($nvccVersion.Trim())" -ForegroundColor Green
}
catch {
    Write-Host "  ⚠️  CUDA not found! Building without GPU support..." -ForegroundColor Yellow
    $cudaAvailable = $false
}

# Clone PowerInfer if not exists
if (-not (Test-Path ".\PowerInfer")) {
    Write-Host "`n📥 Cloning PowerInfer repository..." -ForegroundColor Yellow
    git clone https://github.com/SJTU-IPADS/PowerInfer.git
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to clone repository!" -ForegroundColor Red
        exit 1
    }
    Write-Host "  ✅ Repository cloned successfully" -ForegroundColor Green
}
else {
    Write-Host "`n✅ PowerInfer directory already exists" -ForegroundColor Green
}

# Change to PowerInfer directory
Set-Location PowerInfer

# Install Python dependencies
Write-Host "`n📦 Installing Python dependencies..." -ForegroundColor Yellow
pip install -r requirements.txt
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install Python dependencies!" -ForegroundColor Red
    exit 1
}
Write-Host "  ✅ Dependencies installed" -ForegroundColor Green

# Build PowerInfer
if (-not $SkipBuild) {
    Write-Host "`n🔨 Building PowerInfer..." -ForegroundColor Yellow
    
    # Clean previous build
    if (Test-Path ".\build") {
        Write-Host "  🧹 Cleaning previous build..." -ForegroundColor Gray
        Remove-Item -Recurse -Force .\build
    }
    
    # Configure with CMake
    Write-Host "  ⚙️  Configuring with CMake..." -ForegroundColor Gray
    if ($cudaAvailable -ne $false) {
        cmake -S . -B build -DLLAMA_CUBLAS=ON
    }
    else {
        cmake -S . -B build
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ CMake configuration failed!" -ForegroundColor Red
        exit 1
    }
    
    # Build
    Write-Host "  🔧 Building (this may take several minutes)..." -ForegroundColor Gray
    cmake --build build --config Release
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Build failed!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "  ✅ Build completed successfully" -ForegroundColor Green
}
else {
    Write-Host "`n⏭️  Skipping build (--SkipBuild specified)" -ForegroundColor Yellow
}

# Test the build
if (-not $SkipTest) {
    Write-Host "`n🧪 Testing PowerInfer build..." -ForegroundColor Yellow
    
    if (Test-Path ".\build\bin\Release\main.exe") {
        Write-Host "  ✅ main.exe found" -ForegroundColor Green
        
        # Test help command
        Write-Host "  🔍 Testing help command..." -ForegroundColor Gray
        .\build\bin\Release\main.exe --help | Select-Object -First 5
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ PowerInfer is working!" -ForegroundColor Green
        }
        else {
            Write-Host "  ⚠️  PowerInfer may have issues" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "  ❌ main.exe not found! Build may have failed." -ForegroundColor Red
    }
    
    if (Test-Path ".\build\bin\Release\server.exe") {
        Write-Host "  ✅ server.exe found" -ForegroundColor Green
    }
    else {
        Write-Host "  ❌ server.exe not found!" -ForegroundColor Red
    }
}
else {
    Write-Host "`n⏭️  Skipping tests (--SkipTest specified)" -ForegroundColor Yellow
}

# Summary
Write-Host "`n✅ PowerInfer Setup Complete!" -ForegroundColor Green
Write-Host "`n📍 Installation location:" -ForegroundColor Cyan
Write-Host "   $(Get-Location)" -ForegroundColor White

Write-Host "`n🚀 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Download a model:" -ForegroundColor White
Write-Host "      cd .." -ForegroundColor Gray
Write-Host "      .\download-powerinfer-models.ps1 -ModelName bamboo-dpo" -ForegroundColor Gray

Write-Host "`n   2. Test PowerInfer locally:" -ForegroundColor White
Write-Host "      cd PowerInfer" -ForegroundColor Gray
Write-Host "      .\build\bin\Release\main.exe -m ..\PowerInfer\models\bamboo-7b-dpo-v0.1.q4.powerinfer.gguf -n 128 -t 8 -p `"Hello!`" --vram-budget 10" -ForegroundColor Gray

Write-Host "`n   3. Start PowerInfer server:" -ForegroundColor White
Write-Host "      .\build\bin\Release\server.exe -m ..\PowerInfer\models\bamboo-7b-dpo-v0.1.q4.powerinfer.gguf --host 0.0.0.0 --port 8081 --vram-budget 10 -t 8" -ForegroundColor Gray

Write-Host "`n   4. Integrate with Open-WebUI (see POWERINFER-INTEGRATION.md)" -ForegroundColor White

Set-Location ..
