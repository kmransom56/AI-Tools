# PowerShell helper to run cagent examples
# Requires Docker Desktop to be running.

$examplesDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== cagent single‑agent dry‑run ===" -ForegroundColor Cyan

# Dry‑run the simple agent (no API call)
docker run --rm -v "${examplesDir}:C:/workspace" cagent:latest \
run C:/workspace/agent.yaml --dry-run

Write-Host "`n=== Multi‑agent workflow execution ===" -ForegroundColor Cyan

# Execute the workflow with a sample input
$sampleInput = "Hello from PowerShell!"

docker run --rm -v "${examplesDir}:C:/workspace" cagent:latest \
run C:/workspace/workflow.yaml \
--var user_input="$sampleInput"

Write-Host "`nAll examples completed." -ForegroundColor Green
