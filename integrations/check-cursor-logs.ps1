# check-cursor-logs.ps1
$paths = @("$env:LOCALAPPDATA\Programs\Cursor","$env:LOCALAPPDATA\Cursor")
foreach ($p in $paths) {
    Write-Host "---- Searching in: $p"
    if (-not (Test-Path $p)) { Write-Host "Path not found: $p"; continue }
    $logs = Get-ChildItem -Path $p -Recurse -Include *.log -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 5
    if (-not $logs) { Write-Host 'No .log files found in this location'; continue }
    foreach ($f in $logs) {
        Write-Host "`n== Tail: $($f.FullName)`n  LastWrite: $($f.LastWriteTime)`n"
        try {
            Get-Content -Path $f.FullName -Tail 200 -ErrorAction Stop | ForEach-Object { Write-Host $_ }
        } catch {
            Write-Host "(Unable to read $($f.FullName): $($_.Exception.Message))"
        }
    }
}