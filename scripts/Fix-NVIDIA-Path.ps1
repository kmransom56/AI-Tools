# Fix-NVIDIA-Path.ps1
# Adds NVIDIA tools to system PATH for easy access

# Requires Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator"
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "=== NVIDIA PATH Configuration ===" -ForegroundColor Cyan
Write-Host ""

# Find nvidia-smi.exe
$nvidiaSmiPath = "C:\Program Files\NVIDIA Corporation\NVSMI"
if (Test-Path (Join-Path $nvidiaSmiPath "nvidia-smi.exe")) {
    Write-Host "✓ Found nvidia-smi.exe at: $nvidiaSmiPath" -ForegroundColor Green
} else {
    Write-Host "✗ nvidia-smi.exe not found in expected location" -ForegroundColor Red
    Write-Host "  Searching system..." -ForegroundColor Yellow
    $found = Get-ChildItem "C:\Program Files\NVIDIA Corporation" -Recurse -Filter "nvidia-smi.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $nvidiaSmiPath = $found.DirectoryName
        Write-Host "✓ Found at: $nvidiaSmiPath" -ForegroundColor Green
    } else {
        Write-Error "nvidia-smi.exe not found anywhere. Please install NVIDIA drivers."
        pause
        exit 1
    }
}

# Check if already in PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($currentPath -like "*$nvidiaSmiPath*") {
    Write-Host "✓ NVIDIA tools already in system PATH" -ForegroundColor Green
} else {
    Write-Host "Adding NVIDIA tools to system PATH..." -ForegroundColor Yellow
    $newPath = $currentPath + ";$nvidiaSmiPath"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
    Write-Host "✓ Successfully added to system PATH" -ForegroundColor Green
    Write-Host "  You may need to restart PowerShell for changes to take effect" -ForegroundColor Yellow
}

# Update current session PATH
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine")

Write-Host ""
Write-Host "=== Testing nvidia-smi ===" -ForegroundColor Cyan
Write-Host ""

try {
    & nvidia-smi --query-gpu=index,name,driver_version,memory.total --format=csv
    Write-Host ""
    Write-Host "✓ nvidia-smi is working!" -ForegroundColor Green
} catch {
    Write-Host "✗ Error running nvidia-smi: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Driver Information ===" -ForegroundColor Cyan
$driverVersion = (& nvidia-smi --query-gpu=driver_version --format=csv,noheader | Select-Object -First 1).Trim()
$driverVersionNum = [version]$driverVersion

Write-Host "Current Driver: $driverVersion"
if ($driverVersionNum -lt [version]"450.80") {
    Write-Host "⚠ WARNING: Driver is too old!" -ForegroundColor Red
    Write-Host "  Minimum for CUDA 11.4: 450.80.02" -ForegroundColor Yellow
    Write-Host "  Recommended for Tesla K80: 475.14" -ForegroundColor Yellow
    Write-Host "  Download from: https://www.nvidia.com/Download/index.aspx" -ForegroundColor Cyan
} elseif ($driverVersionNum -ge [version]"475.14") {
    Write-Host "✓ Driver version is compatible with CUDA 11.4" -ForegroundColor Green
} else {
    Write-Host "✓ Driver version is acceptable (475.14 recommended for best results)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Done! Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
