# PowerShell helper to run the Golang developer cagent agent from the Docker cagent repo
# This script will clone the repo (if not already present) and execute the agent.

$repoRoot = Join-Path $PSScriptRoot "..\cagent_repo"

# Clone the Docker cagent repository if it doesn't exist
if (-not (Test-Path $repoRoot)) {
    Write-Host "Cloning Docker cagent repository..." -ForegroundColor Cyan
    git clone https://github.com/docker/cagent $repoRoot
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to clone the repository. Ensure Git is installed and reachable."
        return
    }
}

# Verify the agent file exists
$agentFile = Join-Path $repoRoot "golang_developer.yaml"
if (-not (Test-Path $agentFile)) {
    Write-Error "Agent file not found: $agentFile"
    return
}

# Run the agent using the cagent Docker image
Write-Host "Running Golang developer cagent agent..." -ForegroundColor Cyan

docker run --rm -v "${repoRoot}:C:/workspace" cagent:latest \
run C:/workspace/golang_developer.yaml

if ($LASTEXITCODE -eq 0) {
    Write-Host "Agent execution completed successfully." -ForegroundColor Green
}
else {
    Write-Error "Agent execution failed with exit code $LASTEXITCODE."
}
