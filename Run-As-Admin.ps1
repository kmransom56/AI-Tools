# Wrapper script to run AI-Toolkit-Auto.ps1 as admin and keep window open
$scriptPath = Join-Path $PSScriptRoot "AI-Toolkit-Auto.ps1"
$setKeysPath = Join-Path $PSScriptRoot "Set-API-Keys.ps1"

# Detect PowerShell 7-preview or latest PowerShell 7
$pwsh7Preview = "C:\Program Files\PowerShell\7-preview\pwsh.exe"
$pwsh7 = "C:\Program Files\PowerShell\7\pwsh.exe"
$pwshPath = $null

if (Test-Path $pwsh7Preview) {
    $pwshPath = $pwsh7Preview
    Write-Host "Using PowerShell 7-preview" -ForegroundColor Cyan
} elseif (Test-Path $pwsh7) {
    $pwshPath = $pwsh7
    Write-Host "Using PowerShell 7" -ForegroundColor Cyan
} else {
    # Fall back to default PowerShell
    $pwshPath = "powershell"
    Write-Host "Using default PowerShell (PowerShell 7 recommended)" -ForegroundColor Yellow
}

if (-not (Test-Path $scriptPath)) {
    Write-Host "Error: AI-Toolkit-Auto.ps1 not found at: $scriptPath" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Check for API keys - if missing, try to set them
if (-not $env:OPENAI_API_KEY -or -not $env:ANTHROPIC_API_KEY -or -not $env:GEMINI_API_KEY) {
    Write-Host "WARNING: API keys not found in environment variables." -ForegroundColor Yellow
    Write-Host "`nYou have 3 options:" -ForegroundColor Cyan
    Write-Host "1. Set them now (temporary for this session)" -ForegroundColor White
    Write-Host "2. Set them permanently in Windows Environment Variables" -ForegroundColor White
    Write-Host "3. Create a .env file in this directory" -ForegroundColor White
    
    $choice = Read-Host "`nChoose option (1/2/3) or press Enter to continue anyway"
    
    if ($choice -eq "1" -and (Test-Path $setKeysPath)) {
        & $setKeysPath
    } elseif ($choice -eq "2") {
        Write-Host "`nTo set permanently:" -ForegroundColor Yellow
        Write-Host "1. Press Win+R, type: sysdm.cpl" -ForegroundColor White
        Write-Host "2. Go to 'Advanced' tab > 'Environment Variables'" -ForegroundColor White
        Write-Host "3. Add User variables: OPENAI_API_KEY, ANTHROPIC_API_KEY, GEMINI_API_KEY" -ForegroundColor White
        Write-Host "`nPress any key to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } elseif ($choice -eq "3") {
        Write-Host "Creating .env file template..." -ForegroundColor Yellow
        $envContent = @"
OPENAI_API_KEY=your_openai_key_here
ANTHROPIC_API_KEY=your_anthropic_key_here
GEMINI_API_KEY=your_gemini_key_here
"@
        Set-Content -Path (Join-Path $PSScriptRoot ".env") -Value $envContent
        Write-Host "✅ Created .env file. Please edit it with your API keys, then run this script again." -ForegroundColor Green
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 0
    }
}

# Check if running as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "`nRequesting administrator privileges..." -ForegroundColor Yellow
    Write-Host "Note: Environment variables may not carry over to elevated session." -ForegroundColor Yellow
    Write-Host "If API keys are missing, set them permanently in Windows Environment Variables.`n" -ForegroundColor Yellow
    
    # Build command with environment variables if they exist
    $args = "-NoExit -NoProfile -ExecutionPolicy Bypass"
    if ($env:OPENAI_API_KEY) { $args += " -Command `"`$env:OPENAI_API_KEY='$env:OPENAI_API_KEY'; " }
    if ($env:ANTHROPIC_API_KEY) { $args += "`$env:ANTHROPIC_API_KEY='$env:ANTHROPIC_API_KEY'; " }
    if ($env:GEMINI_API_KEY) { $args += "`$env:GEMINI_API_KEY='$env:GEMINI_API_KEY'; " }
    if ($env:OPENAI_API_KEY -or $env:ANTHROPIC_API_KEY -or $env:GEMINI_API_KEY) {
        $args += "& '$scriptPath'`""
    } else {
        $args += "-File `"$scriptPath`""
    }
    
    Start-Process $pwshPath -Verb RunAs -ArgumentList $args
} else {
    Write-Host "Running script with administrator privileges..." -ForegroundColor Green
    
    # If we're not already in PowerShell 7, relaunch in PowerShell 7-preview
    if ($PSVersionTable.PSVersion.Major -lt 7 -and $pwshPath -ne "powershell") {
        Write-Host "Relaunching in PowerShell 7-preview for better compatibility..." -ForegroundColor Yellow
        & $pwshPath -NoExit -NoProfile -ExecutionPolicy Bypass -File $scriptPath
    } else {
        & $scriptPath
    }
    
    Write-Host "`nScript execution completed." -ForegroundColor Cyan
    Write-Host "Press any key to close this window..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

