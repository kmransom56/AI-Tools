# Scan all local and remote branches for secret patterns
$patterns = @('sk-','AIza','ghp_','gho_','ghs_','dckr_pat_','VLLM_API_KEY','HUGGINGFACE_TOKEN','DOCKER_PASSWORD','CA_SERVER_PASSWORD')
$refs = git for-each-ref --format='%(refname:short)' refs/heads refs/remotes | Where-Object { $_ -ne '' }
$found = @()
foreach ($r in $refs) {
    Write-Host "Checking ref: $r"
    foreach ($p in $patterns) {
        try {
            $res = git grep -n --heading -e $p $r 2>$null
            if ($res) { $found += $res }
        } catch { }
    }
}

if ($found.Count -eq 0) { Write-Host "No matches found across branches/refs for common secret patterns"; exit 0 }
Write-Host "Matches found:" -ForegroundColor Yellow
$found | ForEach-Object { Write-Host $_ }
exit 0
