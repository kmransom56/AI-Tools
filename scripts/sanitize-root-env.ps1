<#
Sanitize root .env by replacing sensitive values with placeholders and creating a timestamped backup.
Usage:
  pwsh -NoProfile -ExecutionPolicy Bypass -File scripts\sanitize-root-env.ps1 -Path .env
#>
param(
    [Parameter(Mandatory=$false)]
    [string]$Path = ".env"
)

if (-not (Test-Path $Path)) { Write-Error "$Path not found"; exit 2 }
$backup = "$Path.bak.$((Get-Date).ToString('yyyyMMddHHmmss'))"
Copy-Item -Path $Path -Destination $backup -Force

$content = Get-Content -Raw -Path $Path

# Replace known keys with placeholders (do not expose old values)
$replacements = @{
    'OPENAI_API_KEY\s*=\s*.*' = 'OPENAI_API_KEY=sk-REDACTED'
    'ANTHROPIC_API_KEY\s*=\s*.*' = 'ANTHROPIC_API_KEY=sk-ant-REDACTED'
    'GEMINI_API_KEY\s*=\s*.*' = 'GEMINI_API_KEY=AIza-REDACTED'
    'DOCKER_PASSWORD\s*=\s*.*' = 'DOCKER_PASSWORD=DOCKER_PAT_REDACTED'
    'VLLM_API_KEY\s*=\s*.*' = 'VLLM_API_KEY=KGKKb7qY-REDACTED'
}

foreach ($k in $replacements.Keys) {
    $content = [regex]::Replace($content, "(?m)^$k", $replacements[$k])
}

Set-Content -Path $Path -Value $content -NoNewline

Write-Host "Sanitized $Path and stored backup at $backup" -ForegroundColor Green
Write-Host "IMPORTANT: Rotate your API keys with the respective providers ASAP and store new keys in a secure vault." -ForegroundColor Yellow
