# ensure-profile-portmanager.ps1
# Creates or updates the CurrentUserAllHosts PowerShell profile to import Port Manager

$path = $PROFILE.CurrentUserAllHosts
$dir = Split-Path -Parent $path
if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

if (-not (Test-Path $path)) {
    $profile_text = @'
# PowerShell profile (created by script)
# Port Manager Module
Import-Module $env:PORT_MANAGER_MODULE -Force
'@
    Set-Content -Path $path -Value $profile_text -Force
    Write-Host "Created profile file at $path"
} else {
    $content = Get-Content $path -Raw
    if ($content -notmatch 'PORT_MANAGER_MODULE') {
        Add-Content -Path $path -Value "`n# Port Manager Module`nImport-Module $env:PORT_MANAGER_MODULE -Force"
        Write-Host 'Appended import line to existing profile'
    } else {
        Write-Host 'Profile already contains port manager import'
    }
}

Write-Host '---- Final profile content ----'
Get-Content $path -Raw
