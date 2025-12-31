# dump-cursor-process-info.ps1
$procs = Get-Process | Where-Object { $_.ProcessName -match '^(?i:cursor)' } -ErrorAction SilentlyContinue
if ($procs) {
    foreach ($p in $procs) {
        Write-Host "Process: $($p.Id) $($p.ProcessName)";
        $p | Format-List *
        Write-Host ''
    }
} else {
    Write-Host 'No processes whose name starts with cursor found'
}

# Also show any processes where the Path contains Cursor
try {
    $all = Get-Process -ErrorAction SilentlyContinue
    $match = @()
    foreach ($p in $all) {
        try { if ($p.Path -and ($p.Path -match 'Cursor')) { $match += $p } } catch { Write-Verbose "Error checking process path: $($_.Exception.Message)" }
    }
    if ($match) { Write-Host 'Processes with Path containing Cursor:'; $match | Select-Object Id,ProcessName,Path | Format-Table -AutoSize } else { Write-Host 'No processes with Path containing Cursor found' }
} catch { Write-Host 'Error enumerating process paths' }