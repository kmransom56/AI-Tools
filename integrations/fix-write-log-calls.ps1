# Fix Write-ToolLog positional calls to use named parameter -Message
Get-ChildItem -Recurse -Include *.ps1 | ForEach-Object {
    $path = $_.FullName
    try {
        $text = Get-Content -LiteralPath $path -Raw -ErrorAction Stop
    } catch {
        Write-Output ("Skipping {0}: could not read" -f $path)
        return
    }
    # Skip the Write-ToolLog function declaration to avoid changing param block
    $lines = $text -split "\r?\n"
    $inFunction = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*Function\s+Write-ToolLog\b') { $inFunction = $true }
        if ($inFunction -and $lines[$i] -match '^\s*\}') { $inFunction = $false }
        if (-not $inFunction) {
            # Replace positional calls where Write-ToolLog is followed by a string literal
            $lines[$i] = $lines[$i] -replace '(^\s*)Write-ToolLog\s+"', '${1}Write-ToolLog -Message "'
            $lines[$i] = $lines[$i] -replace "(^\s*)Write-ToolLog\s+'", "${1}Write-ToolLog -Message '"
        }
    }
    $new = ($lines -join "`r`n")
    if ($new -ne $text) {
        Set-Content -LiteralPath $path -Value $new -Encoding UTF8
        Write-Output "Updated: $path"
    }
}
Write-Output 'Done.'
