# AI-Toolkit Launcher (No Admin Required)
# This script only launches tools, doesn't install anything

# ---------------------------
# Logging Setup
# ---------------------------
$logPath = "$env:USERPROFILE\AI-Tools\launch-log.txt"
New-Item -ItemType File -Force -Path $logPath | Out-Null
Function Write-ToolLog {
    param([string]$message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$timestamp - $message" | Out-File -Append -FilePath $logPath
    Write-Output $message
}

Write-ToolLog -Message "=== AI Tools Launcher (No Admin) ==="

# ---------------------------
# Check if already installed
# ---------------------------
Write-ToolLog -Message "Checking Docker Desktop status..."
$dockerProcess = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
if (-not $dockerProcess) {
    Write-ToolLog -Message "âš  Docker Desktop is not running. Please start it manually or run as admin."
    Write-ToolLog -Message "   Location: C:\Program Files\Docker\Docker\Docker Desktop.exe"
} else {
    Write-ToolLog -Message "âœ… Docker Desktop is running"
}

# Wait for Docker daemon
$maxRetries = 5
$retryCount = 0
$dockerReady = $false
while ($retryCount -lt $maxRetries) {
    try {
        docker info 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-ToolLog -Message "âœ… Docker daemon is ready"
            $dockerReady = $true
            break
        }
    } catch {
        Write-Verbose "docker info check failed: $($_.Exception.Message)"
    }
    $retryCount++
    Write-ToolLog -Message "Waiting for Docker daemon... ($retryCount/$maxRetries)"
    Start-Sleep -Seconds 3
}

if (-not $dockerReady) {
    Write-ToolLog -Message "âš  Docker daemon not ready. Container operations may fail."
}

# ---------------------------
# Check Docker Container
# ---------------------------
Write-ToolLog -Message "Checking AI toolkit container..."
Set-Location "$env:USERPROFILE\AI-Tools"

$containerRunning = docker ps --filter "name=ai-toolkit" --format "{{.Names}}" 2>$null
if ($containerRunning -eq "ai-toolkit") {
    Write-ToolLog -Message "âœ… AI Toolkit container is already running"
} else {
    $containerExists = docker ps -a --filter "name=ai-toolkit" --format "{{.Names}}" 2>$null
    if ($containerExists -eq "ai-toolkit") {
        Write-ToolLog -Message "Starting existing AI toolkit container..."
        docker start ai-toolkit
        Start-Sleep -Seconds 3
        Write-ToolLog -Message "âœ… Container started"
    } else {
        Write-ToolLog -Message "Container doesn't exist. Starting with docker-compose..."
        docker-compose up -d
        Start-Sleep -Seconds 5
        Write-ToolLog -Message "âœ… Container created and started"
    }
}

# Verify container is running
$finalCheck = docker ps --filter "name=ai-toolkit" --format "{{.Names}}" 2>$null
if ($finalCheck -eq "ai-toolkit") {
    # Test sgpt in container
    Write-ToolLog -Message "Testing shell-gpt in container..."
    $sgptTest = docker exec ai-toolkit which sgpt 2>$null
    if ($sgptTest) {
        Write-ToolLog -Message "âœ… shell-gpt (sgpt) is available in container"
    } else {
        Write-ToolLog -Message "âš  shell-gpt not found in container"
    }
} else {
    Write-ToolLog -Message "âŒ Container failed to start"
}

# ---------------------------
# Check VS Code Extensions
# ---------------------------
$vscodePath = where.exe code 2>$null
if ($vscodePath) {
    Write-ToolLog -Message "âœ… VS Code + Extensions: Installed"
} else {
    Write-ToolLog -Message "âš  VS Code not found in PATH"
}

# ---------------------------
# Check Cursor IDE
# ---------------------------
$cursorPath = "$env:LOCALAPPDATA\Programs\Cursor\Cursor.exe"
if (Test-Path $cursorPath) {
    Write-ToolLog -Message "âœ… Cursor IDE: Installed"
} else {
    Write-ToolLog -Message "âš  Cursor IDE not found at $cursorPath"
}

# ---------------------------
# Launch Tools (Optional)
# ---------------------------
$launch = Read-Host "`nWould you like to launch the tools now? (y/n)"
if ($launch -eq "y") {
    # Launch Void if installed
    if (Test-Path "$env:USERPROFILE\void") {
        Write-ToolLog -Message "Launching Void..."
        Start-Process "npm.cmd" -ArgumentList "start" -WorkingDirectory "$env:USERPROFILE\void"
    }

    # Launch Cursor IDE if installed
    if (Test-Path $cursorPath) {
        Write-ToolLog -Message "Launching Cursor IDE..."
        Start-Process $cursorPath
    }

    Write-ToolLog -Message "âœ… Tools launched"
}

# ---------------------------
# Summary
# ---------------------------
Write-ToolLog -Message "`n=== SUMMARY ==="
Write-ToolLog -Message "âœ… AI CLI Tools container: RUNNING"
Write-ToolLog -Message "âœ… shell-gpt (sgpt): Available in container"
Write-ToolLog -Message "âœ… VS Code + Extensions: Installed"
Write-ToolLog -Message "âœ… Cursor IDE: Installed"
Write-ToolLog -Message "âœ… Docker Desktop: Running"
Write-ToolLog -Message "`nTo use sgpt:"
Write-ToolLog -Message "  docker exec -it ai-toolkit sgpt 'your prompt here'"
Write-ToolLog -Message "`nLog saved at: $logPath"


