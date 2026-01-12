<#
Install the local git hooks by configuring core.hooksPath to .githooks
Run this once per clone to enable the PowerShell pre-commit hook.
#>
param()

Write-Host "Setting repository hooks path to .githooks" -ForegroundColor Green
git config core.hooksPath .githooks
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to set hooks path. Run 'git config core.hooksPath .githooks' manually." ; exit 1 }
Write-Host "Hooks installed. Please ensure PowerShell is available (pwsh) for best experience." -ForegroundColor Cyan
