# AI Toolkit Helper Script
# Quick access to AI tools in the Docker container

param(
    [Parameter(Position=0)]
    [string]$Command = "help"
)

$containerName = "ai-toolkit"

switch ($Command.ToLower()) {
    "help" {
        Write-Host "`n=== AI Toolkit Helper ===" -ForegroundColor Cyan
        Write-Host "`nAvailable commands:" -ForegroundColor Yellow
        Write-Host "  .\ai.ps1 shell          - Open interactive bash shell"
        Write-Host "  .\ai.ps1 python         - Open Python REPL"
        Write-Host "  .\ai.ps1 sgpt <prompt>  - Run shell-gpt"
        Write-Host "  .\ai.ps1 status         - Check container status"
        Write-Host "  .\ai.ps1 restart        - Restart container"
        Write-Host "  .\ai.ps1 logs           - View container logs"
        Write-Host "  .\ai.ps1 packages       - List installed packages"
        Write-Host "`nExamples:" -ForegroundColor Yellow
        Write-Host '  .\ai.ps1 sgpt "explain Python decorators"'
        Write-Host '  .\ai.ps1 python -c "import openai; print(openai.__version__)"'
        Write-Host ""
    }
    "shell" {
        Write-Host "Opening interactive shell in AI toolkit container..." -ForegroundColor Green
        docker exec -it $containerName bash
    }
    "python" {
        Write-Host "Opening Python REPL..." -ForegroundColor Green
        docker exec -it $containerName python
    }
    "sgpt" {
        $prompt = $args -join " "
        if ($prompt) {
            docker exec -it $containerName sgpt $prompt
        } else {
            Write-Host "Usage: .\ai.ps1 sgpt <your prompt>" -ForegroundColor Yellow
        }
    }
    "status" {
        Write-Host "`nContainer Status:" -ForegroundColor Cyan
        docker ps --filter "name=$containerName" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        Write-Host "`nInstalled Packages:" -ForegroundColor Cyan
        docker exec $containerName pip list | Select-String -Pattern "openai|anthropic|transformers|langchain|shell-gpt"
    }
    "restart" {
        Write-Host "Restarting AI toolkit container..." -ForegroundColor Yellow
        docker restart $containerName
        Write-Host "Container restarted!" -ForegroundColor Green
    }
    "logs" {
        docker logs $containerName --tail 50 --follow
    }
    "packages" {
        Write-Host "`nInstalled Python Packages:" -ForegroundColor Cyan
        docker exec $containerName pip list
    }
    default {
        Write-Host "Unknown command: $Command" -ForegroundColor Red
        Write-Host "Run '.\ai.ps1 help' for available commands" -ForegroundColor Yellow
    }
}
