# Sanitize root .env with diagnostics
param(
    [string]$Path = ".env"
)
if (-not (Test-Path $Path)) { Write-Error "$Path not found"; exit 2 }

$content = Get-Content -Raw -Path $Path

$keys = @('OPENAI_API_KEY','ANTHROPIC_API_KEY','GEMINI_API_KEY','DOCKER_PASSWORD','VLLM_API_KEY')
foreach ($k in $keys) {
    $rx = [regex]::new("(?m)^\s*" + [regex]::Escape($k) + "\s*=\s*(.*)$")
    $m = $rx.Match($content)
    if ($m.Success) {
        Write-Host "Found $k with value (truncated):" ($m.Groups[1].Value.Substring(0,[Math]::Min(20,$m.Groups[1].Value.Length)))
    } else {
        Write-Host "$k not found in $Path"
    }
}

# Ask for confirmation
Write-Host "\nProceed to replace values with placeholders? (Y/N)" -NoNewline
$ans = Read-Host
if ($ans -notin @('Y','y')) { Write-Host 'Aborting' ; exit 0 }

$backup = "$Path.bak.$((Get-Date).ToString('yyyyMMddHHmmss'))"
Copy-Item -Path $Path -Destination $backup -Force

# Do replacements
$content = [regex]::Replace($content, '(?m)^\s*OPENAI_API_KEY\s*=\s*.*$', 'OPENAI_API_KEY=sk-REDACTED')
$content = [regex]::Replace($content, '(?m)^\s*ANTHROPIC_API_KEY\s*=\s*.*$', 'ANTHROPIC_API_KEY=sk-ant-REDACTED')
$content = [regex]::Replace($content, '(?m)^\s*GEMINI_API_KEY\s*=\s*.*$', 'GEMINI_API_KEY=AIza-REDACTED')
$content = [regex]::Replace($content, '(?m)^\s*DOCKER_PASSWORD\s*=\s*.*$', 'DOCKER_PASSWORD=DOCKER_PAT_REDACTED')
$content = [regex]::Replace($content, '(?m)^\s*VLLM_API_KEY\s*=\s*.*$', 'VLLM_API_KEY=KGKKb7qY-REDACTED')

Set-Content -Path $Path -Value $content -NoNewline
Write-Host "Sanitized $Path and backed up to $backup" -ForegroundColor Green
