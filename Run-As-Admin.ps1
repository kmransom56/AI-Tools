# Wrapper script to run AI-Toolkit-Auto.ps1 as admin and keep window open
$scriptPath = Join-Path $PSScriptRoot "AI-Toolkit-Auto.ps1"
$setKeysPath = Join-Path $PSScriptRoot "Set-API-Keys.ps1"

# Detect PowerShell 7-preview or latest PowerShell 7
$pwsh7Preview = "C:\Program Files\PowerShell\7-preview\pwsh.exe"
$pwsh7 = "C:\Program Files\PowerShell\7\pwsh.exe"
$pwshPath = $null

if (Test-Path $pwsh7Preview) {
    $pwshPath = $pwsh7Preview
    Write-Output "Using PowerShell 7-preview"
} elseif (Test-Path $pwsh7) {
    $pwshPath = $pwsh7
    Write-Output "Using PowerShell 7"
} else {
    # Fall back to default PowerShell
    $pwshPath = "powershell"
    Write-Output "Using default PowerShell (PowerShell 7 recommended)"
}

if (-not (Test-Path $scriptPath)) {
    Write-Output "Error: AI-Toolkit-Auto.ps1 not found at: $scriptPath"
    Write-Output "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Check for API keys - if missing, try to set them
if (-not $env:OPENAI_API_KEY -or -not $env:ANTHROPIC_API_KEY -or -not $env:GEMINI_API_KEY) {
    Write-Output "WARNING: API keys not found in environment variables."
    Write-Output "`nYou have 3 options:"
    Write-Output "1. Set them now (temporary for this session)"
    Write-Output "2. Set them permanently in Windows Environment Variables"
    Write-Output "3. Create a .env file in this directory"

    $choice = Read-Host "`nChoose option (1/2/3) or press Enter to continue anyway"

    if ($choice -eq "1" -and (Test-Path $setKeysPath)) {
        & $setKeysPath
    } elseif ($choice -eq "2") {
        Write-Output "`nTo set permanently:"
        Write-Output "1. Press Win+R, type: sysdm.cpl"
        Write-Output "2. Go to 'Advanced' tab > 'Environment Variables'"
        Write-Output "3. Add User variables: OPENAI_API_KEY, ANTHROPIC_API_KEY, GEMINI_API_KEY"
        Write-Output "`nPress any key to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } elseif ($choice -eq "3") {
        Write-Output "Creating .env file template..."
        $envContent = @"
OPENAI_API_KEY=your_openai_key_here
ANTHROPIC_API_KEY=your_anthropic_key_here
GEMINI_API_KEY=your_gemini_key_here
"@
        Set-Content -Path (Join-Path $PSScriptRoot ".env") -Value $envContent
        Write-Output "✅ Created .env file. Please edit it with your API keys, then run this script again."
        Write-Output "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 0
    }
}

# Check if running as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Output "`nRequesting administrator privileges..."
    Write-Output "Note: Environment variables may not carry over to elevated session."
    Write-Output "If API keys are missing, set them permanently in Windows Environment Variables.`n"

    # Build command with environment variables if they exist
    $launchArgs = "-NoExit -NoProfile -ExecutionPolicy Bypass"
    if ($env:OPENAI_API_KEY) { $launchArgs += " -Command `"`$env:OPENAI_API_KEY='$env:OPENAI_API_KEY'; " }
    if ($env:ANTHROPIC_API_KEY) { $launchArgs += "`$env:ANTHROPIC_API_KEY='$env:ANTHROPIC_API_KEY'; " }
    if ($env:GEMINI_API_KEY) { $launchArgs += "`$env:GEMINI_API_KEY='$env:GEMINI_API_KEY'; " }
    if ($env:OPENAI_API_KEY -or $env:ANTHROPIC_API_KEY -or $env:GEMINI_API_KEY) {
        $launchArgs += "& '$scriptPath'`""
    } else {
        $launchArgs += "-File `"$scriptPath`""
    }

    Start-Process $pwshPath -Verb RunAs -ArgumentList $launchArgs
} else {
    Write-Output "Running script with administrator privileges..."

    # If we're not already in PowerShell 7, relaunch in PowerShell 7-preview
    if ($PSVersionTable.PSVersion.Major -lt 7 -and $pwshPath -ne "powershell") {
        Write-Output "Relaunching in PowerShell 7-preview for better compatibility..."
        & $pwshPath -NoExit -NoProfile -ExecutionPolicy Bypass -File $scriptPath
    } else {
        & $scriptPath
    }

    Write-Output "`nScript execution completed."
    Write-Output "Press any key to close this window..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

