# download-and-run-cursor.ps1
$url = 'https://cursor.com/install/windows'
$out = Join-Path $env:USERPROFILE 'Downloads\CursorSetup.exe'
Write-Host "Downloading $url -> $out"
try {
    Write-Host 'Attempting download with browser UA'
    Invoke-WebRequest -Uri $url -OutFile $out -MaximumRedirection 20 -UseBasicParsing -Headers @{ 'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' } -ErrorAction Stop
    Write-Host "Download complete"
} catch {
    Write-Host "Primary download failed: $($_.Exception.Message)"
    Write-Host 'Falling back to BITS transfer (Start-BitsTransfer)'
    try {
        Start-BitsTransfer -Source $url -Destination $out -ErrorAction Stop
        Write-Host 'BITS transfer complete'
    } catch {
        Write-Host "BITS transfer failed: $($_.Exception.Message)"
        throw
    }
}

try {
    Write-Host "Starting installer (may prompt for elevation)."
    Start-Process -FilePath $out -Verb Open -Wait
    Write-Host "Installer exited (if interactive)."
} catch {
    Write-Host "Failed to start installer: $($_.Exception.Message)"
    throw
}