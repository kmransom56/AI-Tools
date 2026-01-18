# Setup-TabbyML-Auth.ps1
# Configures TabbyML authentication token for local development

$logPath = "$env:USERPROFILE\AI-Tools\install-launch-log.txt"
Function Write-Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $message"
    "[$timestamp] - $message" | Out-File -Append -FilePath $logPath
}

Write-Log "[INFO] Setting up TabbyML authentication..."

# Generate a simple token for local development (32 character random string)
$tabbyToken = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})

# Save token to config file
$configDir = "$env:USERPROFILE\AI-Tools\config"
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Force -Path $configDir | Out-Null
}

$tokenFile = Join-Path $configDir "tabby-token.txt"
$tabbyToken | Set-Content -Path $tokenFile -Force
Write-Log "[OK] TabbyML token saved to $tokenFile"

# Create client-side config.toml
$tabbyConfigDir = "$env:USERPROFILE\.tabby"
if (-not (Test-Path $tabbyConfigDir)) {
    New-Item -ItemType Directory -Force -Path $tabbyConfigDir | Out-Null
}

# Get TabbyML port from registry or use default
$tabbyPort = 11080
$portRegistryPath = "$env:USERPROFILE\AI-Tools\port-registry.json"
if (Test-Path $portRegistryPath) {
    $registry = Get-Content $portRegistryPath -Raw | ConvertFrom-Json
    if ($registry.RegisteredPorts) {
        foreach ($port in $registry.RegisteredPorts.PSObject.Properties) {
            if ($port.Value.ApplicationName -eq "TabbyML") {
                $tabbyPort = [int]$port.Name
                break
            }
        }
    }
}

$configToml = @"
[server]
endpoint = "http://localhost:$tabbyPort"
token = "$tabbyToken"
"@

$configTomlPath = Join-Path $tabbyConfigDir "config.toml"
$configToml | Set-Content -Path $configTomlPath -Force
Write-Log "[OK] TabbyML client config created at $configTomlPath"

Write-Log "[OK] TabbyML authentication configured"
Write-Host "`nTabbyML Token: $tabbyToken" -ForegroundColor Green
Write-Host "Config file: $configTomlPath" -ForegroundColor Cyan
Write-Host "`nNote: Restart TabbyML container and VS Code/Cursor extensions to apply changes." -ForegroundColor Yellow

return $tabbyToken
