# Fix-TabbyML-Auth.ps1
# Quick fix for TabbyML authentication token prompt

Write-Host "`n=== TabbyML Authentication Setup ===" -ForegroundColor Cyan

# Load port manager if available
$portManagerPath = Join-Path $PSScriptRoot "scripts\Port-Manager.ps1"
if (Test-Path $portManagerPath) {
    . $portManagerPath
}

# Run the setup script
$setupScript = Join-Path $PSScriptRoot "scripts\Setup-TabbyML-Auth.ps1"
if (Test-Path $setupScript) {
    . $setupScript
    Write-Host "`n✅ TabbyML authentication configured!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Restart TabbyML container: docker restart tabbyml" -ForegroundColor White
    Write-Host "2. Restart VS Code/Cursor to reload extensions" -ForegroundColor White
    Write-Host "3. The token is saved in: $env:USERPROFILE\.tabby\config.toml" -ForegroundColor Gray
} else {
    Write-Host "❌ Setup script not found at: $setupScript" -ForegroundColor Red
    Write-Host "Please run the full installation script: .\AI-Toolkit-Auto.ps1" -ForegroundColor Yellow
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
