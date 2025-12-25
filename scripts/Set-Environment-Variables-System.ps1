# Set-Environment-Variables-System.ps1
# Helper script to set API keys as persistent environment variables

Write-Host "=== Set Persistent Environment Variables ===" -ForegroundColor Cyan
Write-Host "This script will set API keys as Machine-level environment variables." -ForegroundColor Yellow
Write-Host "Machine-level variables apply only to your account (no admin required).`n" -ForegroundColor Yellow

# Check if keys are already set
$existingOpenAI = [System.Environment]::GetEnvironmentVariable('OPENAI_API_KEY', 'Machine')
$existingAnthropic = [System.Environment]::GetEnvironmentVariable('ANTHROPIC_API_KEY', 'Machine')
$existingGemini = [System.Environment]::GetEnvironmentVariable('GEMINI_API_KEY', 'Machine')

if ($existingOpenAI -or $existingAnthropic -or $existingGemini) {
    Write-Host "Current environment variables:" -ForegroundColor Cyan
    if ($existingOpenAI) { Write-Host "  OPENAI_API_KEY: $($existingOpenAI.Substring(0, [Math]::Min(20, $existingOpenAI.Length)))..." -ForegroundColor Gray }
    if ($existingAnthropic) { Write-Host "  ANTHROPIC_API_KEY: $($existingAnthropic.Substring(0, [Math]::Min(20, $existingAnthropic.Length)))..." -ForegroundColor Gray }
    if ($existingGemini) { Write-Host "  GEMINI_API_KEY: $($existingGemini.Substring(0, [Math]::Min(20, $existingGemini.Length)))..." -ForegroundColor Gray }
    
    $overwrite = Read-Host "`nOverwrite existing values? (Y/N)"
    if ($overwrite -ne 'Y' -and $overwrite -ne 'y') {
        Write-Host "Cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Try to read from .env file first
$envFile = Join-Path $PSScriptRoot ".env"
if (Test-Path $envFile) {
    Write-Host "`nReading API keys from .env file..." -ForegroundColor Cyan
    $envContent = Get-Content $envFile
    $openaiKey = $null
    $anthropicKey = $null
    $geminiKey = $null
    
    foreach ($line in $envContent) {
        if ($line -match '^\s*OPENAI_API_KEY\s*=\s*(.+)$') {
            $openaiKey = $matches[1].Trim('"', "'")
        } elseif ($line -match '^\s*ANTHROPIC_API_KEY\s*=\s*(.+)$') {
            $anthropicKey = $matches[1].Trim('"', "'")
        } elseif ($line -match '^\s*GEMINI_API_KEY\s*=\s*(.+)$') {
            $geminiKey = $matches[1].Trim('"', "'")
        }
    }
    
    if ($openaiKey -and $anthropicKey -and $geminiKey) {
        Write-Host "Found all API keys in .env file. Use them? (Y/N)" -ForegroundColor Yellow
        $useEnv = Read-Host
        if ($useEnv -eq 'Y' -or $useEnv -eq 'y') {
            [System.Environment]::SetEnvironmentVariable('OPENAI_API_KEY', $openaiKey, 'Machine')
            [System.Environment]::SetEnvironmentVariable('ANTHROPIC_API_KEY', $anthropicKey, 'Machine')
            [System.Environment]::SetEnvironmentVariable('GEMINI_API_KEY', $geminiKey, 'Machine')
            
            Write-Host "`n✅ Environment variables set from .env file!" -ForegroundColor Green
            Write-Host "Note: Restart PowerShell or run the following to use them in current session:" -ForegroundColor Yellow
            Write-Host "  `$env:OPENAI_API_KEY = [System.Environment]::GetEnvironmentVariable('OPENAI_API_KEY', 'Machine')" -ForegroundColor Gray
            Write-Host "  `$env:ANTHROPIC_API_KEY = [System.Environment]::GetEnvironmentVariable('ANTHROPIC_API_KEY', 'Machine')" -ForegroundColor Gray
            Write-Host "  `$env:GEMINI_API_KEY = [System.Environment]::GetEnvironmentVariable('GEMINI_API_KEY', 'Machine')" -ForegroundColor Gray
            exit 0
        }
    }
}

# Prompt for API keys
Write-Host "`nEnter your API keys:" -ForegroundColor Yellow

if (-not $openaiKey) {
    $openaiKey = Read-Host "OpenAI API Key" -AsSecureString
    $openaiKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($openaiKey)
    )
}

if (-not $anthropicKey) {
    $anthropicKey = Read-Host "Anthropic API Key" -AsSecureString
    $anthropicKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($anthropicKey)
    )
}

if (-not $geminiKey) {
    $geminiKey = Read-Host "Gemini API Key" -AsSecureString
    $geminiKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($geminiKey)
    )
}

# Set environment variables
[System.Environment]::SetEnvironmentVariable('OPENAI_API_KEY', $openaiKey, 'Machine')
[System.Environment]::SetEnvironmentVariable('ANTHROPIC_API_KEY', $anthropicKey, 'Machine')
[System.Environment]::SetEnvironmentVariable('GEMINI_API_KEY', $geminiKey, 'Machine')

Write-Host "`n✅ Environment variables set permanently!" -ForegroundColor Green
Write-Host "`nNote: Restart PowerShell or run the following to use them in current session:" -ForegroundColor Yellow
Write-Host "  `$env:OPENAI_API_KEY = [System.Environment]::GetEnvironmentVariable('OPENAI_API_KEY', 'Machine')" -ForegroundColor Gray
Write-Host "  `$env:ANTHROPIC_API_KEY = [System.Environment]::GetEnvironmentVariable('ANTHROPIC_API_KEY', 'Machine')" -ForegroundColor Gray
Write-Host "  `$env:GEMINI_API_KEY = [System.Environment]::GetEnvironmentVariable('GEMINI_API_KEY', 'Machine')" -ForegroundColor Gray

