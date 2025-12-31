# fix-profile-oldpath.ps1
$p='C:\Users\south\OneDrive\Documents\PowerShell\profile.ps1'
if (-not (Test-Path $p)) { Write-Host "Profile file not found at $p"; exit 1 }
$bak = "$p.bak"
Copy-Item -Path $p -Destination $bak -Force
Write-Host "Backed up profile to $bak"
$old = [regex]::Escape("Import-Module 'C:\Users\Keith Ransom\AI-Tools\PortManager\PortManager.psm1' -Force")
(Get-Content $p -Raw) -replace $old, 'Import-Module $env:PORT_MANAGER_MODULE -Force' | Set-Content $p
Write-Host '--- Updated profile content ---'
Get-Content $p -Raw
