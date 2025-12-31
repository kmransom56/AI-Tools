try {
    Start-Process 'C:\Users\south\AppData\Roaming\Sysinternals\Procmon.exe' -ArgumentList '/Terminate' -Verb RunAs -ErrorAction SilentlyContinue -Wait
} catch {
    Write-Verbose "Procmon termination attempt failed: $($_.Exception.Message)"
}
Start-Sleep -Milliseconds 500
$ts = Get-Date -Format yyyyMMdd-HHmmss
$pml = "C:\Users\south\AI-Tools\backups\procmon-cursor-filter-$ts.pml"
Write-Host "Starting Procmon -> $pml"
$args = @('/AcceptEula','/BackingFile',$pml,'/NoFilter')
Start-Process 'C:\Users\south\AppData\Roaming\Sysinternals\Procmon.exe' -ArgumentList $args -Verb RunAs
Start-Sleep -Seconds 1
Write-Host "Launching Cursor"
Start-Process -FilePath 'C:\Users\south\AppData\Local\Programs\Cursor\Cursor.exe'
Write-Host "Sleeping to capture events (10s)"
Start-Sleep -Seconds 10
Write-Host "Stopping Procmon"
Start-Process 'C:\Users\south\AppData\Roaming\Sysinternals\Procmon.exe' -ArgumentList '/Terminate' -Verb RunAs
Start-Sleep -Seconds 1
$csv = "C:\Users\south\AI-Tools\backups\procmon-cursor-filter-$ts.csv"
Write-Host "Converting PML to CSV -> $csv"
$args2 = @('/OpenLog',$pml,'/SaveAs',$csv)
Start-Process 'C:\Users\south\AppData\Roaming\Sysinternals\Procmon.exe' -ArgumentList $args2 -Wait
$filtered = "C:\Users\south\AI-Tools\backups\procmon-cursor-filter-$ts-filtered.csv"
Write-Host "Filtering for Cursor.exe -> $filtered"
Get-Content -Path $csv | Where-Object { $_ -match 'Cursor.exe' -or $_ -match 'Process Name' } | Set-Content -Path $filtered
$zip = "C:\Users\south\AI-Tools\backups\procmon-cursor-filter-$ts.zip"
Compress-Archive -Path $filtered -DestinationPath $zip -Force
Write-Host "Saved zip: $zip"
Write-Output $zip
