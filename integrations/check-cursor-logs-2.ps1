# check-cursor-logs-2.ps1
$roots = @($env:LOCALAPPDATA, $env:APPDATA)
foreach ($root in $roots) {
    Write-Host "---- Searching under: $root for 'logs' directories"
    try {
        $dirs = Get-ChildItem -Path $root -Recurse -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'logs|log' }
    } catch {
        $errMsg = $_.Exception.Message
        Write-Host ("(Search failed under {0}: {1})" -f $root, $errMsg)
        continue
    }
    if (-not $dirs) { Write-Host "No 'logs' directories found under $root"; continue }
    foreach ($d in $dirs) {
        Write-Host "Found logs dir: $($d.FullName)";
        $files = Get-ChildItem -Path $d.FullName -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 5
        foreach ($f in $files) {
            Write-Host "\n== Tail: $($f.FullName)`n  LastWrite: $($f.LastWriteTime)`n";
            try { Get-Content -Path $f.FullName -Tail 200 -ErrorAction Stop | ForEach-Object { Write-Host $_ } } catch { Write-Host "(Unable to read $($f.FullName): $($_.Exception.Message))" }
        }
    }
}

Write-Host "\n---- Checking Application event log for recent Cursor/Electron related errors (last 6 hours)"
try {
    $events = Get-WinEvent -FilterHashtable @{LogName='Application'; StartTime=(Get-Date).AddHours(-6)} -ErrorAction SilentlyContinue | Where-Object { $_.Message -match 'Cursor|cursor' -or $_.Message -match 'electron' -or $_.ProviderName -match 'Application Error' } | Select-Object TimeCreated, ProviderName, Id, LevelDisplayName, Message -First 30
    if ($events) { $events | ForEach-Object { Write-Host "---- Event: $($_.TimeCreated) $($_.ProviderName) [$($_.LevelDisplayName)] ID:$($_.Id)`n$($_.Message)`n" } } else { Write-Host 'No recent related events found in Application log' }
} catch {
    Write-Host "(Failed to query event log: $($_.Exception.Message))"
}