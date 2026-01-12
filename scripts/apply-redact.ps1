$path = '.env'
if (-not (Test-Path $path)) { Write-Error "$path not found"; exit 2 }
$orig = Get-Content -Raw $path
$backup = "$path.bak.manual.$((Get-Date).ToString('yyyyMMddHHmmss'))"
Copy-Item -Path $path -Destination $backup -Force

$new = $orig -replace '(?m)^\s*OPENAI_API_KEY\s*=.*$', 'OPENAI_API_KEY=sk-REDACTED'
$new = $new -replace '(?m)^\s*ANTHROPIC_API_KEY\s*=.*$', 'ANTHROPIC_API_KEY=sk-ant-REDACTED'
$new = $new -replace '(?m)^\s*GEMINI_API_KEY\s*=.*$', 'GEMINI_API_KEY=AIza-REDACTED'
$new = $new -replace '(?m)^\s*DOCKER_PASSWORD\s*=.*$', 'DOCKER_PASSWORD=DOCKER_PAT_REDACTED'
$new = $new -replace '(?m)^\s*VLLM_API_KEY\s*=.*$', 'VLLM_API_KEY=KGKKb7qY-REDACTED'
Set-Content -Path $path -Value $new -Force
Write-Host "Applied redaction and backed up original to $backup"
Get-Content $path | Select-String -Pattern 'OPENAI_API_KEY|ANTHROPIC_API_KEY|GEMINI_API_KEY|DOCKER_PASSWORD|VLLM_API_KEY' | ForEach-Object { Write-Host $_.Line }
