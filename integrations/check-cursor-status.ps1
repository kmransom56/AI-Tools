# check-cursor-status.ps1
Write-Host '---- Cursor process status ----'
$procs = Get-Process -Name Cursor -ErrorAction SilentlyContinue
if ($procs) {
    $procs | Select-Object Id, ProcessName, @{n='StartTime';e={$_.StartTime}}, @{n='CPU(s)';e={$_.CPU}} | Format-Table -AutoSize
} else {
    Write-Host 'Cursor process not running'
}

Write-Host "\n---- Search Application events for Cursor or electron (last 24h) ----"
$events = Get-WinEvent -FilterHashtable @{LogName='Application'; StartTime=(Get-Date).AddHours(-24)} -ErrorAction SilentlyContinue | Where-Object { $_.Message -match 'Cursor|cursor|electron|Cursor.exe' } | Select-Object TimeCreated, ProviderName, Id, LevelDisplayName, Message -First 50
if ($events) {
    foreach ($e in $events) {
        Write-Host "---- Event: $($e.TimeCreated) $($e.ProviderName) [$($e.LevelDisplayName)] ID:$($e.Id)";
        Write-Host $e.Message; Write-Host ''
    }
} else {
    Write-Host 'No related events found in Application log (24h)'
}

Write-Host "\n---- CrashDumps for Cursor (if any) ----"
$crashDir = Join-Path $env:LOCALAPPDATA 'CrashDumps'
if (Test-Path $crashDir) {
    Get-ChildItem -Path $crashDir -Filter '*cursor*' -File -ErrorAction SilentlyContinue | Select-Object FullName, LastWriteTime | Format-Table -AutoSize
} else {
    Write-Host 'No CrashDumps directory'
}