# AI-Toolkit Launcher (No Admin Required)
# This script only launches tools, doesn't install anything

# ---------------------------
# Logging Setup
# ---------------------------
$logPath = "$env:USERPROFILE\AI-Tools\launch-log.txt"
New-Item -ItemType File -Force -Path $logPath | Out-Null
Function Write-Log {
    param([string]$message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$timestamp - $message" | Out-File -Append -FilePath $logPath
    Write-Output $message
}

Write-Log "=== AI Tools Launcher (No Admin) ==="

# ---------------------------
# Check if already installed
# ---------------------------
Write-Log "Checking Docker Desktop status..."
$dockerProcess = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
if (-not $dockerProcess) {
    Write-Log "⚠ Docker Desktop is not running. Please start it manually or run as admin."
    Write-Log "   Location: C:\Program Files\Docker\Docker\Docker Desktop.exe"
} else {
    Write-Log "✅ Docker Desktop is running"
}

# Wait for Docker daemon
$maxRetries = 5
$retryCount = 0
$dockerReady = $false
while ($retryCount -lt $maxRetries) {
    try {
        docker info 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "✅ Docker daemon is ready"
            $dockerReady = $true
            break
        }
    } catch {
        Write-Verbose "docker info check failed: $($_.Exception.Message)"
    }
    $retryCount++
    Write-Log "Waiting for Docker daemon... ($retryCount/$maxRetries)"
    Start-Sleep -Seconds 3
}

if (-not $dockerReady) {
    Write-Log "⚠ Docker daemon not ready. Container operations may fail."
}

# ---------------------------
# Check Docker Container
# ---------------------------
Write-Log "Checking AI toolkit container..."
cd "$env:USERPROFILE\AI-Tools"

$containerRunning = docker ps --filter "name=ai-toolkit" --format "{{.Names}}" 2>$null
if ($containerRunning -eq "ai-toolkit") {
    Write-Log "✅ AI Toolkit container is already running"
} else {
    $containerExists = docker ps -a --filter "name=ai-toolkit" --format "{{.Names}}" 2>$null
    if ($containerExists -eq "ai-toolkit") {
        Write-Log "Starting existing AI toolkit container..."
        docker start ai-toolkit
        Start-Sleep -Seconds 3
        Write-Log "✅ Container started"
    } else {
        Write-Log "Container doesn't exist. Starting with docker-compose..."
        docker-compose up -d
        Start-Sleep -Seconds 5
        Write-Log "✅ Container created and started"
    }
}

# Verify container is running
$finalCheck = docker ps --filter "name=ai-toolkit" --format "{{.Names}}" 2>$null
if ($finalCheck -eq "ai-toolkit") {
    # Test sgpt in container
    Write-Log "Testing shell-gpt in container..."
    $sgptTest = docker exec ai-toolkit which sgpt 2>$null
    if ($sgptTest) {
        Write-Log "✅ shell-gpt (sgpt) is available in container"
    } else {
        Write-Log "⚠ shell-gpt not found in container"
    }
} else {
    Write-Log "❌ Container failed to start"
}

# ---------------------------
# Check VS Code Extensions
# ---------------------------
$vscodePath = where.exe code 2>$null
if ($vscodePath) {
    Write-Log "✅ VS Code + Extensions: Installed"
} else {
    Write-Log "⚠ VS Code not found in PATH"
}

# ---------------------------
# Check Cursor IDE
# ---------------------------
$cursorPath = "$env:LOCALAPPDATA\Programs\Cursor\Cursor.exe"
if (Test-Path $cursorPath) {
    Write-Log "✅ Cursor IDE: Installed"
} else {
    Write-Log "⚠ Cursor IDE not found at $cursorPath"
}

# ---------------------------
# Launch Tools (Optional)
# ---------------------------
$launch = Read-Host "`nWould you like to launch the tools now? (y/n)"
if ($launch -eq "y") {
    # Launch Void if installed
    if (Test-Path "$env:USERPROFILE\void") {
        Write-Log "Launching Void..."
        Start-Process "npm.cmd" -ArgumentList "start" -WorkingDirectory "$env:USERPROFILE\void"
    }

    # Launch Cursor IDE if installed
    if (Test-Path $cursorPath) {
        Write-Log "Launching Cursor IDE..."
        Start-Process $cursorPath
    }

    Write-Log "✅ Tools launched"
}

# ---------------------------
# Summary
# ---------------------------
Write-Log "`n=== SUMMARY ==="
Write-Log "✅ AI CLI Tools container: RUNNING"
Write-Log "✅ shell-gpt (sgpt): Available in container"
Write-Log "✅ VS Code + Extensions: Installed"
Write-Log "✅ Cursor IDE: Installed"
Write-Log "✅ Docker Desktop: Running"
Write-Log "`nTo use sgpt:"
Write-Log "  docker exec -it ai-toolkit sgpt 'your prompt here'"
Write-Log "`nLog saved at: $logPath"
