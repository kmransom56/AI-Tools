<#
Pre-commit secret scanner (PowerShell)
- Scans staged changes for common secret patterns and blocks the commit if any are found.
- Designed for Windows / PowerShell users. Place in .githooks and run `git config core.hooksPath .githooks` to enable.
#>

$ErrorActionPreference = 'Stop'

# Patterns to detect (simple heuristics)
$patterns = @(
    'sk-[A-Za-z0-9\-_]{20,}',             # OpenAI project keys
    'sk-[A-Za-z0-9]{20,}',                 # OpenAI older keys
    'AIza[0-9A-Za-z\-_]{30,}',            # Google API keys
    'ghp_[A-Za-z0-9_]{36,}',               # GitHub personal access tokens
    'ghs_[A-Za-z0-9_]{36,}',
    'gho_[A-Za-z0-9_]{36,}',
    'dckr_pat_[A-Za-z0-9]{10,}',           # Docker PAT heuristics
    'VLLM_API_KEY',                        # local runner token
    'HUGGINGFACE_TOKEN',
    'DOCKER_PASSWORD',
    'ANTHROPIC_API_KEY',
    'GEMINI_API_KEY'
)

$regex = ($patterns -join '|')

# Get staged files
$staged = git diff --cached --name-only
if (-not $staged) { exit 0 }

$found = @()
foreach ($f in $staged) {
    # Skip binary files quickly
    if ((Get-Item -LiteralPath $f).Attributes -band [System.IO.FileAttributes]::Directory) { continue }

    # Test added/modified content in the index (staged content)
    $diff = git diff --cached --unified=0 -- $f 2>$null
    if ($diff -match $regex) {
        $matches = [regex]::Matches($diff, $regex)
        foreach ($m in $matches) { $found += [PSCustomObject]@{File=$f;Match=$m.Value} }
    }
    # Also block attempts to add .env files or files named *.env
    if ($f -match '\.env$' -or $f -match '\.env\.') {
        $found += [PSCustomObject]@{File=$f;Match='Attempt to add env file'}
    }
}

if ($found.Count -gt 0) {
    Write-Host "ERROR: Potential secrets detected in staged changes:" -ForegroundColor Red
    $found | ForEach-Object {
        Write-Host " - $($_.File): $($_.Match)"
    }

    Write-Host "\nCommit aborted. Remove secrets or use a secure secret store (GitHub Secrets, Windows Credential Manager, Vault)." -ForegroundColor Yellow
    Write-Host "To bypass (not recommended), unstage the file or edit it to remove secrets before committing." -ForegroundColor DarkYellow
    exit 1
}

exit 0