# setup-port-env.ps1
# Sets up environment variables for port management
# Run this to make port management available system-wide

# Get the actual script directory (handle both direct execution and via relative path)
$scriptDir = if ($PSScriptRoot) { 
    $PSScriptRoot 
} else { 
    Split-Path -Parent $MyInvocation.MyCommand.Path 
}

# If running from integrations folder, go up one level
if ((Split-Path -Leaf $scriptDir) -eq "integrations") {
    $baseDir = Split-Path -Parent $scriptDir
} else {
    $baseDir = $scriptDir
}

$portManagerPath = Join-Path $baseDir "PortManager\PortManager.psm1"
$portCliPath = Join-Path $baseDir "scripts\port-cli.ps1"

# Verify paths exist
if (-not (Test-Path $portManagerPath)) {
    Write-Error "Port Manager not found at: $portManagerPath"
    exit 1
}
if (-not (Test-Path $portCliPath)) {
    Write-Error "Port CLI not found at: $portCliPath"
    exit 1
}

# Add to PowerShell profile for automatic loading
$profilePath = $PROFILE.CurrentUserAllHosts
$profileDir = Split-Path $profilePath -Parent

if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# Add port manager to profile
$importLine = "Import-Module '$portManagerPath' -Force"
if (Test-Path $profilePath) {
    $profileContent = Get-Content $profilePath -Raw
    if ($profileContent -notmatch [regex]::Escape($importLine)) {
        Add-Content -Path $profilePath -Value "`n# Port Manager Module`n$importLine"
        Write-Host "Added Port Manager to PowerShell profile" -ForegroundColor Green
    }
} else {
    Set-Content -Path $profilePath -Value "# Port Manager Module`n$importLine"
    Write-Host "Created PowerShell profile with Port Manager" -ForegroundColor Green
}

# Set environment variables
[System.Environment]::SetEnvironmentVariable('PORT_MANAGER_MODULE', $portManagerPath, 'User')
[System.Environment]::SetEnvironmentVariable('PORT_CLI_PATH', $portCliPath, 'User')
[System.Environment]::SetEnvironmentVariable('PORT_REGISTRY_PATH', "$env:USERPROFILE\AI-Tools\port-registry.json", 'User')

Write-Host "`n✅ Port management environment variables set:" -ForegroundColor Green
Write-Host "  PORT_MANAGER_MODULE = $portManagerPath" -ForegroundColor Gray
Write-Host "  PORT_CLI_PATH = $portCliPath" -ForegroundColor Gray
Write-Host "  PORT_REGISTRY_PATH = $env:USERPROFILE\AI-Tools\port-registry.json" -ForegroundColor Gray

Write-Host "`nPort management is now available system-wide!" -ForegroundColor Cyan
Write-Host "Restart your terminal or run: Import-Module '$portManagerPath'" -ForegroundColor Yellow

