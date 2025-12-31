# run-cursor-wait.ps1
$exe = 'C:\Users\south\AppData\Local\Programs\Cursor\Cursor.exe'
if (Test-Path $exe) {
    Write-Host "Running: $exe (this will wait until the app exits)"
    try {
        $p = Start-Process -FilePath $exe -PassThru -Wait -ErrorAction Stop
        Write-Host "Process exited with ExitCode: $($p.ExitCode)"
    } catch {
        Write-Host "Failed to start or process exited immediately: $($_.Exception.Message)"
    }
} else { Write-Host "Cursor exe not found at $exe" }