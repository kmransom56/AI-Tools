# start-and-check-cursor.ps1
Write-Host 'Starting Cursor (non-elevated)'
Start-Process -FilePath 'C:\Users\south\AppData\Local\Programs\Cursor\Cursor.exe'
Start-Sleep -Seconds 6

Write-Host '\nProcess check:'
$procs = Get-Process -Name Cursor -ErrorAction SilentlyContinue
if ($procs) { $procs | Select-Object Id,ProcessName,@{n='StartTime';e={$_.StartTime}} | Format-Table -AutoSize } else { Write-Host 'Cursor process not running' }

$tmp = Join-Path $env:TEMP 'cursor_proclist_fallback.log'
if (Test-Path $tmp) { Write-Host "\nFallback log found at $tmp"; Get-Content -Path $tmp -Tail 50 } else { Write-Host "\nNo fallback log found at $tmp" }

Write-Host "\nRecent Application events (last 15 minutes) mentioning Cursor/electron:"
$ev = Get-WinEvent -FilterHashtable @{LogName='Application'; StartTime=(Get-Date).AddMinutes(-15)} -ErrorAction SilentlyContinue | Where-Object { $_.Message -match 'Cursor|cursor|Cursor.exe|cursor_proclist|electron' } | Select-Object TimeCreated, ProviderName, Id, LevelDisplayName, Message -First 50
if ($ev) { foreach ($e in $ev) { Write-Host "---- Event: $($e.TimeCreated) $($e.ProviderName) [$($e.LevelDisplayName)] ID:$($e.Id)"; Write-Host $e.Message; Write-Host '' } } else { Write-Host 'No recent related events found (15m)' }