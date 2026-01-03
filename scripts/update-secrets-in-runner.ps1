<#
Update secrets in repository .env files (root .env and powershell-signer/.env)
Backups are created before updating.

Usage (example):
  pwsh -NoProfile -ExecutionPolicy Bypass -File scripts\update-secrets-in-runner.ps1 -OpenAI 'sk-xxx' -Anthropic 'sk-ant-xxx' -Gemini 'AIza-xxx' -Docker 'new_docker_pat' -Vllm 'new_vllm_token'
#>
param(
    [string]$OpenAI,
    [string]$Anthropic,
    [string]$Gemini,
    [string]$Docker,
    [string]$Vllm,
    [string]$Paths = ".env,powershell-signer/.env"
)

$targets = $Paths -split ',' | ForEach-Object { $_.Trim() } | Where-Object { Test-Path $_ }
if ($targets.Count -eq 0) { Write-Error "No target .env files found"; exit 2 }

foreach ($t in $targets) {
    $backup = "$t.bak.rotate.$((Get-Date).ToString('yyyyMMddHHmmss'))"
    Copy-Item -Path $t -Destination $backup -Force
    $content = Get-Content -Raw -Path $t

    if ($OpenAI) { $content = [regex]::Replace($content, '(?m)^\s*OPENAI_API_KEY\s*=.*$', "OPENAI_API_KEY=$OpenAI") }
    if ($Anthropic) { $content = [regex]::Replace($content, '(?m)^\s*ANTHROPIC_API_KEY\s*=.*$', "ANTHROPIC_API_KEY=$Anthropic") }
    if ($Gemini) { $content = [regex]::Replace($content, '(?m)^\s*GEMINI_API_KEY\s*=.*$', "GEMINI_API_KEY=$Gemini") }
    if ($Docker) { $content = [regex]::Replace($content, '(?m)^\s*DOCKER_PASSWORD\s*=.*$', "DOCKER_PASSWORD=$Docker") }
    if ($Vllm) { $content = [regex]::Replace($content, '(?m)^\s*VLLM_API_KEY\s*=.*$', "VLLM_API_KEY=$Vllm") }

    Set-Content -Path $t -Value $content -Force
    Write-Host "Updated $t (backup at $backup)" -ForegroundColor Green
}
