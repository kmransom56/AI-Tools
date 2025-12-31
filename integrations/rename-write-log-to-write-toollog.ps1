Get-ChildItem -Recurse -Include *.ps1 | ForEach-Object {
    $path = $_.FullName
    try { $text = Get-Content -LiteralPath $path -Raw -ErrorAction Stop } catch { Write-Output ("Skipping {0}: cannot read" -f $path); return }
    $new = $text -replace '\bFunction\s+Write-ToolLog\b', 'Function Write-ToolLog'
    # Replace invocations of Write-ToolLog with Write-ToolLog (word boundary)
    $new = $new -replace '\bWrite-Log\b', 'Write-ToolLog'
    if ($new -ne $text) {
        Set-Content -LiteralPath $path -Value $new -Encoding UTF8
        Write-Output ("Updated: {0}" -f $path)
    }
}
Write-Output 'Done.'
