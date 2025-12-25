# Set-API-Keys.ps1
# Helper script to set API keys as environment variables

Write-Host "=== API Key Setup ===" -ForegroundColor Cyan
Write-Host "This script will set API keys for the current PowerShell session." -ForegroundColor Yellow
Write-Host "For permanent setup, use Windows System Properties > Environment Variables`n" -ForegroundColor Yellow

# Check if keys are already set
if ($env:OPENAI_API_KEY -and $env:ANTHROPIC_API_KEY -and $env:GEMINI_API_KEY) {
    Write-Host "API keys are already set in this session." -ForegroundColor Green
    Write-Host "OPENAI_API_KEY: $($env:OPENAI_API_KEY.Substring(0, [Math]::Min(20, $env:OPENAI_API_KEY.Length)))..." -ForegroundColor Gray
    Write-Host "ANTHROPIC_API_KEY: $($env:ANTHROPIC_API_KEY.Substring(0, [Math]::Min(20, $env:ANTHROPIC_API_KEY.Length)))..." -ForegroundColor Gray
    Write-Host "GEMINI_API_KEY: $($env:GEMINI_API_KEY.Substring(0, [Math]::Min(20, $env:GEMINI_API_KEY.Length)))..." -ForegroundColor Gray
    $useExisting = Read-Host "`nUse existing keys? (Y/N)"
    if ($useExisting -eq 'Y' -or $useExisting -eq 'y') {
        return
    }
}

# Prompt for API keys
Write-Host "`nEnter your API keys (press Enter to skip if already set):" -ForegroundColor Yellow

if (-not $env:OPENAI_API_KEY) {
    $openaiKey = Read-Host "OpenAI API Key" -AsSecureString
    $env:OPENAI_API_KEY = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($openaiKey)
    )
}

if (-not $env:ANTHROPIC_API_KEY) {
    $anthropicKey = Read-Host "Anthropic API Key" -AsSecureString
    $env:ANTHROPIC_API_KEY = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($anthropicKey)
    )
}

if (-not $env:GEMINI_API_KEY) {
    $geminiKey = Read-Host "Gemini API Key" -AsSecureString
    $env:GEMINI_API_KEY = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($geminiKey)
    )
}

Write-Host "`n✅ API keys set for this session!" -ForegroundColor Green
Write-Host "Note: These are only set for the current PowerShell session." -ForegroundColor Yellow
Write-Host "To set permanently, use Windows System Properties > Environment Variables`n" -ForegroundColor Yellow

