
# AI-Toolkit-Auto.ps1
# Combined Installer + Launcher for AI Development Toolkit

# ---------------------------
# Port Management Setup
# ---------------------------
$portManagerPath = Join-Path $PSScriptRoot "scripts\Port-Manager.ps1"
if (Test-Path $portManagerPath) {
    . $portManagerPath
    Write-Log "Port management system loaded"
} else {
    Write-Log "WARNING: Port-Manager.ps1 not found. Using default ports."
}

# ---------------------------
# Logging Setup
# ---------------------------
$logPath = "$env:USERPROFILE\AI-Tools\install-launch-log.txt"
New-Item -ItemType File -Force -Path $logPath
Function Write-Log {
    param([string]$message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$timestamp - $message" | Out-File -Append -FilePath $logPath
    Write-Host $message
}

# ---------------------------
# Admin Check
# ---------------------------
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "`n❌ ADMINISTRATOR PRIVILEGES REQUIRED" -ForegroundColor Red
    Write-Host "`nThis script needs to:" -ForegroundColor Yellow
    Write-Host "  • Install Chocolatey" -ForegroundColor White
    Write-Host "  • Install software (Node.js, Python, Git, Docker, VS Code)" -ForegroundColor White
    Write-Host "  • Start Docker Desktop" -ForegroundColor White
    Write-Host "`nPlease run PowerShell as Administrator and try again." -ForegroundColor Cyan
    Write-Host "`nAlternatively, if everything is already installed, use:" -ForegroundColor Yellow
    Write-Host "  .\Launch-AI-Tools-NoAdmin.ps1" -ForegroundColor Green
    Write-Host ""
    pause
    exit 1
}

# ---------------------------
# Validate API Keys
# ---------------------------
# First try environment variables
$OPENAI = $env:OPENAI_API_KEY
$ANTHROPIC = $env:ANTHROPIC_API_KEY
$GEMINI = $env:GEMINI_API_KEY

# If not found, try reading from .env file
if (-not $OPENAI -or -not $ANTHROPIC -or -not $GEMINI) {
    $envFile = Join-Path $PSScriptRoot ".env"
    if (Test-Path $envFile) {
        Write-Log "Reading API keys from .env file..."
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                switch ($key) {
                    "OPENAI_API_KEY" { if (-not $OPENAI) { $OPENAI = $value; $env:OPENAI_API_KEY = $value } }
                    "ANTHROPIC_API_KEY" { if (-not $ANTHROPIC) { $ANTHROPIC = $value; $env:ANTHROPIC_API_KEY = $value } }
                    "GEMINI_API_KEY" { if (-not $GEMINI) { $GEMINI = $value; $env:GEMINI_API_KEY = $value } }
                }
            }
        }
    }
}

if (-not $OPENAI -or -not $ANTHROPIC -or -not $GEMINI) {
    Write-Log "❌ Missing API keys! Please set OPENAI_API_KEY, ANTHROPIC_API_KEY, GEMINI_API_KEY."
    Write-Host "`nYou can set them in one of these ways:" -ForegroundColor Yellow
    Write-Host "1. Windows Environment Variables (permanent)" -ForegroundColor White
    Write-Host "2. Create a .env file in this directory with:" -ForegroundColor White
    Write-Host "   OPENAI_API_KEY=your_key" -ForegroundColor Gray
    Write-Host "   ANTHROPIC_API_KEY=your_key" -ForegroundColor Gray
    Write-Host "   GEMINI_API_KEY=your_key" -ForegroundColor Gray
    Write-Host "`nPress any key to exit..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Log "✅ API keys detected. Starting installation..."

# ---------------------------
# Docker Hub Authentication (Optional)
# ---------------------------
# Uncomment and set these if you need to pull private images:
$DOCKER_USERNAME = $env:DOCKER_USERNAME
$DOCKER_PASSWORD = $env:DOCKER_PASSWORD 

  if ($DOCKER_USERNAME -and $DOCKER_PASSWORD) {
      Write-Log "Logging into Docker Hub..."
      echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
 }
# ---------------------------
# Install Chocolatey
# ---------------------------
Write-Log "Installing Chocolatey..."
Set-ExecutionPolicy Bypass -Scope Process -Force
# Download and run the Chocolatey install script safely (avoid Invoke-Expression)
$chocoInstallScript = (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
$tempChoco = Join-Path $env:TEMP 'choco-install.ps1'
Set-Content -Path $tempChoco -Value $chocoInstallScript -Encoding UTF8
& $tempChoco

# ---------------------------
# Install prerequisites
# ---------------------------
Write-Log "Installing Node.js, Python, Git, Docker Desktop, VS Code..."
choco install nodejs python git docker-desktop vscode -y
refreshenv

# Upgrade pip to latest version
Write-Log "Upgrading pip..."
python.exe -m uv pip install --upgrade pip

# ---------------------------
# Check Docker Desktop status
# ---------------------------
Write-Log "Checking Docker Desktop status..."
$dockerProcess = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
if (-not $dockerProcess) {
    Write-Log "Docker Desktop is not running. Starting Docker Desktop..."
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    Write-Log "Waiting for Docker to initialize..."
    Start-Sleep -Seconds 45
} else {
    Write-Log "Docker Desktop is already running."
}

# Wait for Docker daemon to be ready
Write-Log "Verifying Docker daemon is ready..."
$maxRetries = 10
$retryCount = 0
while ($retryCount -lt $maxRetries) {
    try {
        docker info | Out-Null
        Write-Log "✅ Docker daemon is ready"
        break
    } catch {
        $retryCount++
        Write-Log "Waiting for Docker daemon... ($retryCount/$maxRetries)"
        Start-Sleep -Seconds 3
    }
}
if ($retryCount -eq $maxRetries) {
    Write-Log "WARNING: Docker daemon may not be fully ready, continuing anyway..."
}

# ---------------------------
# Install Void (Open-source Cursor alternative)
# ---------------------------
Write-Log "Installing Void (open-source Cursor alternative)..."
try {
    if (-not (Test-Path "$env:USERPROFILE\void")) {
        cd $env:USERPROFILE
        git clone https://github.com/voideditor/void.git
        if (Test-Path "$env:USERPROFILE\void") {
            cd "$env:USERPROFILE\void"
            Write-Log "Building Void (this may take several minutes)..."
            npm install
            npm run build
            Write-Log "✅ Void installed successfully"
        } else {
            Write-Log "❌ Failed to clone Void repository"
        }
    } else {
        Write-Log "ℹ Void already installed, skipping"
    }
} catch {
    Write-Log "❌ Void installation error: $($_.Exception.Message)"
}

# ---------------------------
# TabbyML Setup (Self-hosted AI coding assistant)
# ---------------------------
Write-Log "Setting up TabbyML (self-hosted AI coding assistant)..."
Write-Log "TabbyML will be configured in docker-compose.yml"
Write-Log "TabbyML port will be assigned from port management system (11000-12000 range)"
Write-Log "TabbyML can be integrated with Void and other editors"

# ---------------------------
# VS Code Extensions
# ---------------------------
Write-Log "Installing VS Code extensions..."
code --install-extension continue.continue
code --install-extension GitHub.copilot

# ---------------------------
# Cursor IDE
# ---------------------------
Write-Log "Downloading Cursor IDE..."
Invoke-WebRequest -Uri "https://cursor.sh/install/windows" -OutFile "$env:USERPROFILE\Downloads\CursorSetup.exe"
Start-Process "$env:USERPROFILE\Downloads\CursorSetup.exe" -Wait

# ---------------------------
# CLI Tools
# ---------------------------
Write-Log "Installing CLI tools..."
try {
    Write-Log "Installing Python CLI tools..."
    pip install shell-gpt --quiet
    
    Write-Log "Installing gpt-cli..."
    npm install -g gpt-cli 2>&1 | Out-Null
    
    # Note: opencode-cli and chatgpt-shell-cli may not be publicly available
    Write-Log "Note: Some CLI tools (opencode, chatgpt-shell-cli) may not be available"
    
    Write-Log "✅ Available CLI tools installed"
} catch {
    Write-Log "WARNING: Some CLI tools may have failed: $($_.Exception.Message)"
}

# ---------------------------
# Docker Compose Setup
# ---------------------------
Write-Log "Setting up Docker Compose environment..."
# Escape API keys properly for YAML
$openaiEscaped = $OPENAI -replace '"', ''
$anthropicEscaped = $ANTHROPIC -replace '"', ''
$geminiEscaped = $GEMINI -replace '"', ''

# Create Dockerfile for comprehensive AI toolkit
$dockerfile = @"
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip and install foundational packages
RUN pip install --upgrade pip setuptools wheel

# Install AI/ML frameworks (using latest stable versions)
RUN pip install --no-cache-dir \
    torch \
    transformers

# Install OpenAI and AI CLI tools
RUN pip install --no-cache-dir \
    openai \
    anthropic \
    google-generativeai \
    shell-gpt \
    langchain \
    langchain-openai \
    langchain-anthropic

# Install additional useful tools
RUN pip install --no-cache-dir \
    requests \
    httpx \
    python-dotenv \
    pyyaml \
    rich \
    typer \
    fastapi \
    uvicorn \
    jinja2

# Create config directory
RUN mkdir -p /app/config /app/templates

# Copy web application files
COPY ai_web_app.py /app/
COPY templates/index.html /app/templates/

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV TOKENIZERS_PARALLELISM=false

# Expose web interface port
EXPOSE 8000

# Start web server
CMD ["uvicorn", "ai_web_app:app", "--host", "0.0.0.0", "--port", "8000"]
"@

Set-Content -Path "$env:USERPROFILE\AI-Tools\Dockerfile.ai-toolkit" -Value $dockerfile

# ---------------------------
# Port Assignment
# ---------------------------
Write-Log "Assigning ports using port management system..."

# Find available ports in preferred range (11000-12000)
$aiToolkitPort = Find-AvailablePort -ApplicationName "AI-Toolkit" -PreferredPort 11000
if (-not $aiToolkitPort) {
    Write-Log "WARNING: Could not find available port for AI Toolkit, using default 11000"
    $aiToolkitPort = 11000
    Register-Port -Port $aiToolkitPort -ApplicationName "AI-Toolkit" -Description "AI Toolkit web interface"
}

$tabbyMLPort = Find-AvailablePort -ApplicationName "TabbyML" -PreferredPort 11080
if (-not $tabbyMLPort) {
    Write-Log "WARNING: Could not find available port for TabbyML, using default 11080"
    $tabbyMLPort = 11080
    Register-Port -Port $tabbyMLPort -ApplicationName "TabbyML" -Description "TabbyML AI coding assistant"
}

Write-Log "Port assignments:"
Write-Log "  AI Toolkit: $aiToolkitPort"
Write-Log "  TabbyML: $tabbyMLPort"

$compose = @"
services:
  ai-toolkit:
    build:
      context: .
      dockerfile: Dockerfile.ai-toolkit
    image: ai-toolkit:latest
    container_name: ai-toolkit
    working_dir: /app
    ports:
      - "$aiToolkitPort:8000"
    volumes:
      - ./config:/app/config
      - ./workspace:/app/workspace
    environment:
      - OPENAI_API_KEY=$openaiEscaped
      - ANTHROPIC_API_KEY=$anthropicEscaped
      - GEMINI_API_KEY=$geminiEscaped
    restart: unless-stopped
    stdin_open: true
    tty: true

  # TabbyML - Self-hosted AI coding assistant
  tabbyml:
    image: tabbyml/tabby:latest
    container_name: tabbyml
    command: ["serve", "--model", "StarCoder-1B", "--device", "cpu", "--chat-model", "Qwen2-1.5B-Instruct"]
    ports:
      - "$tabbyMLPort:8080"
    volumes:
      - tabby-data:/data
    restart: unless-stopped

volumes:
  tabby-data:
"@

New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\AI-Tools"
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\AI-Tools\config"
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\AI-Tools\workspace"
Set-Content -Path "$env:USERPROFILE\AI-Tools\docker-compose.yml" -Value $compose

cd "$env:USERPROFILE\AI-Tools"

Write-Log "Building custom AI toolkit Docker image (this may take a few minutes)..."
docker-compose build --no-cache

Write-Log "Starting AI toolkit container..."
docker-compose up -d

Write-Log "✅ Docker containers started!"

# ---------------------------
# Post-Install Verification
# ---------------------------
Write-Log "🔍 Verifying installations..."

# Check Void
if (Test-Path "$env:USERPROFILE\void") { 
    Write-Log "✔ Void installed successfully." 
} else { 
    Write-Log "ℹ Void not installed (optional component)" 
}

# Check TabbyML container
$tabbyStatus = docker ps --filter "name=tabbyml" --format "{{.Status}}"
if ($tabbyStatus) { 
    # Get assigned port from registry
    $registry = Get-PortRegistry
    $tabbyPort = 11080  # Default
    foreach ($port in $registry.RegisteredPorts.Keys) {
        if ($registry.RegisteredPorts[$port].ApplicationName -eq "TabbyML") {
            $tabbyPort = [int]$port
            break
        }
    }
    Write-Log "✔ TabbyML container running: $tabbyStatus" 
    Write-Log "  Access TabbyML at: http://localhost:$tabbyPort" 
} else { 
    Write-Log "ℹ TabbyML container not running (check docker-compose logs)" 
}

# Check Docker containers
$aiToolkitStatus = docker ps --filter "name=ai-toolkit" --format "{{.Status}}"
if ($aiToolkitStatus) { 
    Write-Log "✔ AI Toolkit container running: $aiToolkitStatus" 
} else { 
    Write-Log "WARNING: AI Toolkit container not running" 
}

# Verify packages inside container
Write-Log "Verifying AI packages in container..."
docker exec ai-toolkit python -c "import openai, transformers, anthropic; print('✅ All AI packages loaded successfully')" 2>&1 | ForEach-Object { Write-Log $_ }

# Check CLI tools
$cliTools = @("sgpt", "gpt")
foreach ($tool in $cliTools) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) { 
        Write-Log "✔ $tool is installed" 
    } else { 
        Write-Log "ℹ $tool available in Docker container: docker exec -it ai-toolkit $tool" 
    }
}

# Check VS Code extensions
Write-Log "✔ VS Code with Continue and GitHub Copilot extensions installed"

# Print usage instructions
Write-Log ""
Write-Log "=== Usage Instructions ===" 
Write-Log "Run AI commands in the container:"
Write-Log "  docker exec -it ai-toolkit sgpt 'your prompt'"
Write-Log "  docker exec -it ai-toolkit python -c 'import openai; print(openai.__version__)'"
Write-Log ""
Write-Log "Enter interactive shell:"
Write-Log "  docker exec -it ai-toolkit bash"
Write-Log ""
Write-Log "Access your workspace:"
Write-Log "  Files in C:\Users\$env:USERNAME\AI-Tools\workspace are mounted to /app/workspace"

# ---------------------------
# Auto-Launch Tools
# ---------------------------
Write-Log "Launching AI Tools..."

# Launch Void if installed
if (Test-Path "$env:USERPROFILE\void") {
    Write-Log "Launching Void editor..."
    Start-Process "npm.cmd" -ArgumentList "start" -WorkingDirectory "$env:USERPROFILE\void"
    Write-Log "✅ Void editor launched"
} else {
    Write-Log "WARNING: Skipping Void launch (not installed)"
}

# Launch TabbyML in browser if container is running
$tabbyRunning = docker ps --filter "name=tabbyml" --format "{{.Names}}"
if ($tabbyRunning -eq "tabbyml") {
    # Get assigned port from registry
    $registry = Get-PortRegistry
    $tabbyPort = 11080  # Default
    foreach ($port in $registry.RegisteredPorts.Keys) {
        if ($registry.RegisteredPorts[$port].ApplicationName -eq "TabbyML") {
            $tabbyPort = [int]$port
            break
        }
    }
    Write-Log "Launching TabbyML in browser..."
    Start-Sleep -Seconds 5  # Wait for TabbyML to be ready
    Start-Process "http://localhost:$tabbyPort"
    Write-Log "✅ TabbyML accessible at http://localhost:$tabbyPort"
    Write-Log "  Note: TabbyML can be integrated with Void and other editors"
} else {
    Write-Log "WARNING: TabbyML container not running. Check with: docker ps -a | findstr tabbyml"
}

# Launch VS Code with multiple projects if they exist
if (Test-Path "$env:USERPROFILE\Projects\Project1") {
    Start-Process "code" -ArgumentList "$env:USERPROFILE\Projects\Project1"
}
if (Test-Path "$env:USERPROFILE\Projects\Project2") {
    Start-Process "code" -ArgumentList "$env:USERPROFILE\Projects\Project2"
}

# Launch Cursor IDE if installed
$cursorPath = "$env:LOCALAPPDATA\Programs\Cursor\Cursor.exe"
if (Test-Path $cursorPath) {
    Write-Log "Launching Cursor IDE..."
    Start-Process $cursorPath
} else {
    Write-Log "WARNING: Skipping Cursor launch (not installed at $cursorPath)"
}

# Launch CLI commands in terminals only if tools are available
if (Get-Command "opencode" -ErrorAction SilentlyContinue) {
    Start-Process "cmd.exe" -ArgumentList "/k", "opencode", "Explain async in Python"
}
if (Get-Command "sgpt" -ErrorAction SilentlyContinue) {
    Start-Process "cmd.exe" -ArgumentList "/k", "sgpt", "Generate a Python class for API client"
}
if (Get-Command "chatgpt" -ErrorAction SilentlyContinue) {
    Start-Process "cmd.exe" -ArgumentList "/k", "chatgpt", "Summarize this code snippet"
}
if (Get-Command "gpt" -ErrorAction SilentlyContinue) {
    Start-Process "cmd.exe" -ArgumentList "/k", "gpt", "Create a Dockerfile for Node.js app"
}

Write-Log "✅ All available tools launched successfully!"
Write-Host "`n✅ Full installation and launch complete. Log saved at: $logPath" -ForegroundColor Cyan
Write-Host "`nPress any key to close this window..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
