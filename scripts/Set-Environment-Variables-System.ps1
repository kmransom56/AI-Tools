
# Set-API-Keys.ps1
# Helper script to set API keys as environment variables

Write-Host "=== API Key Setup ===" -ForegroundColor Cyan
Write-Host "This script will set API keys as environment variables." -ForegroundColor Yellow

# Check if keys are already set in session or system
$openai = $env:OPENAI_API_KEY
$anthropic = $env:ANTHROPIC_API_KEY
$gemini = $env:GEMINI_API_KEY

# Fallback to checking User level if session is empty
if (-not $openai) { $openai = [Environment]::GetEnvironmentVariable("OPENAI_API_KEY", "User") }
if (-not $anthropic) { $anthropic = [Environment]::GetEnvironmentVariable("ANTHROPIC_API_KEY", "User") }
if (-not $gemini) { $gemini = [Environment]::GetEnvironmentVariable("GEMINI_API_KEY", "User") }

if ($openai -and $anthropic -and $gemini) {
    Write-Host "`nAPI keys detected!" -ForegroundColor Green
    Write-Host "OPENAI_API_KEY: $($openai.Substring(0, [Math]::Min(20, $openai.Length)))..." -ForegroundColor Gray
    Write-Host "ANTHROPIC_API_KEY: $($anthropic.Substring(0, [Math]::Min(20, $anthropic.Length)))..." -ForegroundColor Gray
    Write-Host "GEMINI_API_KEY: $($gemini.Substring(0, [Math]::Min(20, $gemini.Length)))..." -ForegroundColor Gray
    
    $useExisting = Read-Host "`nUse existing keys? (Y/N)"
    if ($useExisting -eq 'Y' -or $useExisting -eq 'y') {
        # Ensure session variables are set if they were only at User level
        $env:OPENAI_API_KEY = $openai
        $env:ANTHROPIC_API_KEY = $anthropic
        $env:GEMINI_API_KEY = $gemini
        return
    }
}

# Prompt for API keys
Write-Host "`nEnter your API keys (press Enter to skip current value):" -ForegroundColor Yellow

function Get-APIKey {
    param([string]$Name, [string]$CurrentValue)
    $prompt = if ($CurrentValue) { "$Name (Leave blank to keep current):" } else { "$Name:" }
    $key = Read-Host $prompt -AsSecureString
    if ($key.Length -eq 0) {
        return $CurrentValue
    }
    return [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($key)
    )
}

$newOpenAI = Get-APIKey "OpenAI API Key" $openai
$newAnthropic = Get-APIKey "Anthropic API Key" $anthropic
$newGemini = Get-APIKey "Gemini API Key" $gemini

# Ask for persistence
$makePermanent = Read-Host "`nSet these keys permanently for the current user? (Y/N)"

if ($makePermanent -eq 'Y' -or $makePermanent -eq 'y') {
    [Environment]::SetEnvironmentVariable("OPENAI_API_KEY", $newOpenAI, "User")
    [Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $newAnthropic, "User")
    [Environment]::SetEnvironmentVariable("GEMINI_API_KEY", $newGemini, "User")
    Write-Host "✅ Keys saved permanently at User level." -ForegroundColor Green
}

# Set in current session
$env:OPENAI_API_KEY = $newOpenAI
$env:ANTHROPIC_API_KEY = $newAnthropic
$env:GEMINI_API_KEY = $newGemini

Write-Host "✅ API keys set for the current session!" -ForegroundColor Green
if ($makePermanent -ne 'Y' -and $makePermanent -ne 'y') {
    Write-Host "Note: These are only set for the current PowerShell session." -ForegroundColor Yellow
}


