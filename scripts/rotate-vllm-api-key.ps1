<#
Rotate the VLLM_API_KEY value in the self-hosted runner .env (powershell-signer/.env)
- Generates a strong random token, backs up the current .env, and writes the new token.
- Prints the new value for secure storage (copy it to your vault)

Usage:
  .\rotate-vllm-api-key.ps1 -Path powershell-signer/.env
#>
param(
    [Parameter(Mandatory=$false)]
    [string]$Path = "powershell-signer/.env",
    [Parameter(Mandatory=$false)]
    [switch]$Print
)

if (-not (Test-Path $Path)) { Write-Error "$Path not found"; exit 2 }

# Generate a cryptographically strong token (URL-safe base64, 32 bytes -> 43 chars)
$bytes = New-Object 'System.Byte[]' 32
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$token = [System.Convert]::ToBase64String($bytes)
# Make URL-safe and strip padding
$token = $token.TrimEnd('=') -replace '\+', '-' -replace '/', '_'

$backup = "$Path.bak.$((Get-Date).ToString('yyyyMMddHHmmss'))"
Copy-Item -Path $Path -Destination $backup -Force

# Replace or append the VLLM_API_KEY entry
$content = Get-Content -Raw -Path $Path
if ($content -match "(?m)^VLLM_API_KEY\s*=.*$") {
    $newContent = ([regex]::Replace($content, "(?m)^VLLM_API_KEY\s*=.*$", "VLLM_API_KEY=$token"))
} else {
    $newContent = $content.TrimEnd() + "`r`nVLLM_API_KEY=$token`r`n"
}
Set-Content -Path $Path -Value $newContent -NoNewline

Write-Host "VLLM_API_KEY rotated and saved in $Path (backup at $backup)" -ForegroundColor Green
if ($Print) { Write-Host "New token: $token" -ForegroundColor Yellow }
Write-Host "Important: store the new token in a secure vault and update any self-hosted runner .env files." -ForegroundColor Cyan
