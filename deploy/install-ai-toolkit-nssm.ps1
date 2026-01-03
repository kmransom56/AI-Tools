<#
Install or uninstall the ai-toolkit service on Windows using NSSM (Non-Sucking Service Manager).

Usage (run as Administrator):
  # Install
  .\install-ai-toolkit-nssm.ps1 -Action install -InstallDir 'C:\opt\ai-toolkit' -ServiceName 'ai-toolkit' -Port 11500

  # Uninstall
  .\install-ai-toolkit-nssm.ps1 -Action uninstall -ServiceName 'ai-toolkit'

Notes:
- Prefers Chocolatey to install NSSM if available; otherwise downloads NSSM release and extracts it under C:\tools\nssm
- Attempts to auto-detect Python; you can pass -PythonExe to override.
- Logs are written to: $InstallDir\logs\stdout.log and stderr.log
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('install','uninstall')]
    [string] $Action,

    [string] $ServiceName = 'ai-toolkit',

    [string] $InstallDir = 'C:\opt\ai-toolkit',

    [int] $Port = 11500,

    [string] $PythonExe,

    [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    if (-not $isAdmin) { throw "This script must be run as Administrator." }
}

function Ensure-NSSM {
    # Returns path to nssm.exe
    $nssm = Get-Command nssm -ErrorAction SilentlyContinue
    if ($nssm) { return $nssm.Path }

    # Check common install location
    $candidate = 'C:\tools\nssm\nssm.exe'
    if (Test-Path $candidate) { return $candidate }

    # Try Chocolatey
    $choco = Get-Command choco -ErrorAction SilentlyContinue
    if ($choco) {
        Write-Host "Installing NSSM via Chocolatey..."
        choco install nssm -y | Out-Null
        # typical choco path
        $chocoPath = "$env:ProgramData\chocolatey\bin\nssm.exe"
        if (Test-Path $chocoPath) { return $chocoPath }
    }

    # Download NSSM release and extract
    $tmp = Join-Path $env:TEMP "nssm-zip-$(Get-Random)"
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    $nssmZip = Join-Path $tmp 'nssm.zip'
    $url = 'https://nssm.cc/release/nssm-2.24.zip'
    Write-Host "Downloading NSSM from $url"
    try {
        Invoke-WebRequest -Uri $url -OutFile $nssmZip -UseBasicParsing -ErrorAction Stop
    } catch {
        throw "Failed to download NSSM from $url: $($_.Exception.Message)"
    }
    Expand-Archive -Path $nssmZip -DestinationPath $tmp -Force
    # Find nssm.exe in extracted tree
    $found = Get-ChildItem -Path $tmp -Filter nssm.exe -Recurse -File | Select-Object -First 1
    if (-not $found) { throw "nssm.exe not found in archive" }
    $dest = 'C:\tools\nssm'
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    Copy-Item -Path $found.FullName -Destination (Join-Path $dest 'nssm.exe') -Force
    return (Join-Path $dest 'nssm.exe')
}

function Get-PythonExe {
    param($Override)
    if ($Override) { return $Override }
    $cmd = Get-Command python -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Path }
    $py = Get-Command py -ErrorAction SilentlyContinue
    if ($py) { return $py.Path }
    throw "Python executable not found. Provide -PythonExe to override."
}

Assert-Admin

if ($Action -eq 'install') {
    $nssmExe = Ensure-NSSM
    Write-Host "Using NSSM: $nssmExe"

    $python = Get-PythonExe -Override $PythonExe
    Write-Host "Using Python: $python"

    # Prepare install dir
    if (-not (Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null }
    $logDir = Join-Path $InstallDir 'logs'
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

    $args = "-m uvicorn ai_web_app:app --host 0.0.0.0 --port $Port"

    Write-Host "Installing service '$ServiceName' (Exec: $python $args)"
    & $nssmExe install $ServiceName $python $args
    & $nssmExe set $ServiceName AppDirectory $InstallDir
    & $nssmExe set $ServiceName AppStdout (Join-Path $logDir 'stdout.log')
    & $nssmExe set $ServiceName AppStderr (Join-Path $logDir 'stderr.log')
    & $nssmExe set $ServiceName AppRotateFiles 1
    & $nssmExe set $ServiceName Description "AI Toolkit web service"

    # Optionally set environment file path
    $envFile = Join-Path $InstallDir '.env'
    if (Test-Path $envFile) {
        & $nssmExe set $ServiceName AppEnvironmentExtra "DOTENV=$envFile"
        Write-Host "Note: environment file found at $envFile (not automatically parsed by NSSM). Configure app to read it or set env via NSSM AppEnvironmentExtra."
    }

    Write-Host "Starting service $ServiceName"
    & $nssmExe start $ServiceName
    Write-Host "Service installed and started. Check logs under: $logDir"
}

if ($Action -eq 'uninstall') {
    $nssmExe = Ensure-NSSM
    Write-Host "Uninstalling service '$ServiceName' using NSSM: $nssmExe"
    try {
        & $nssmExe stop $ServiceName -ErrorAction SilentlyContinue
    } catch {}
    & $nssmExe remove $ServiceName confirm
    Write-Host "Service removed."
}
