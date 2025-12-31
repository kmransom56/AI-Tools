# reinstall-cursor.ps1
# Back up Cursor user data, uninstall Cursor, download latest installer, and run installer (as normal user)
$log = "C:\Users\south\AI-Tools\logs\cursor-reinstall-$(Get-Date -Format yyyyMMdd-HHmmss).log"
New-Item -ItemType File -Force -Path $log | Out-Null
Function Log { param($m) "$((Get-Date).ToString('o')) - $m" | Tee-Object -FilePath $log -Append }

try {
    Log "Starting Cursor reinstall workflow"
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupDir = Join-Path $env:USERPROFILE "AI-Tools\backups\cursor-backup-$timestamp"
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    Log "Backup directory: $backupDir"

    # Backup user data
    $localCursor = Join-Path $env:LOCALAPPDATA 'Cursor'
    $appCursor = Join-Path $env:APPDATA 'Cursor'
    if (Test-Path $localCursor) {
        Log "Backing up LocalAppData Cursor -> $backupDir\LocalAppData"
        Copy-Item -Path $localCursor -Destination (Join-Path $backupDir 'LocalAppData') -Recurse -Force
    } else { Log "No LocalAppData Cursor folder found" }
    if (Test-Path $appCursor) {
        Log "Backing up AppData Cursor -> $backupDir\AppData"
        Copy-Item -Path $appCursor -Destination (Join-Path $backupDir 'AppData') -Recurse -Force
    } else { Log "No AppData Cursor folder found" }

    # Stop Cursor processes
    $procs = Get-Process -Name 'Cursor' -ErrorAction SilentlyContinue
    if ($procs) {
        Log "Stopping Cursor processes"
        $procs | Stop-Process -Force -ErrorAction SilentlyContinue
    } else {
        Log "No running Cursor processes"
    }

    # Run uninstaller if present
    $installDir = Join-Path $env:LOCALAPPDATA 'Programs\Cursor'
    $uninstaller = Join-Path $installDir 'unins000.exe'
    if (Test-Path $uninstaller) {
        Log "Found uninstaller: $uninstaller (will run elevated)"
        Start-Process -FilePath $uninstaller -Verb RunAs -Wait
        Log "Uninstaller finished"
    } else {
        Log "Uninstaller not found; removing install directory if present"
        if (Test-Path $installDir) {
            Remove-Item -Recurse -Force $installDir
            Log "Removed $installDir"
        } else { Log "Install dir not found: $installDir" }
    }

    # Clean leftover package dirs
    $pkgDir = Join-Path $env:LOCALAPPDATA 'Programs\Cursor\resources\app\node_modules\cursor-proclist'
    if (Test-Path $pkgDir) {
        Log "Removing leftover package directory: $pkgDir"
        Remove-Item -Recurse -Force $pkgDir
    }

    # Download latest installer
    $installer = Join-Path $env:USERPROFILE 'Downloads\CursorSetup.exe'
    Log "Downloading installer to $installer"
    Invoke-WebRequest -Uri "https://cursor.sh/install/windows" -OutFile $installer -UseBasicParsing -ErrorAction Stop
    Log "Downloaded installer"

    # Run installer as normal user (do NOT force elevation here to preserve update behavior)
    Log "Starting installer (may prompt for elevation if required by installer)"
    Start-Process -FilePath $installer -Verb Open -Wait
    Log "Installer process exited"

    # Post-install check
    $cursorExe = Join-Path $installDir 'Cursor.exe'
    if (Test-Path $cursorExe) {
        Log "Cursor seems installed at $cursorExe; starting app"
        Start-Process -FilePath $cursorExe
    } else {
        Log "Cursor exe not found at expected location: $cursorExe"
    }

    Log "Cursor reinstall workflow completed"
    Write-Output "Done. See log: $log"
} catch {
    Log "ERROR: $($_.Exception.Message)"
    throw
} finally {
    Log "Finished at $(Get-Date -Format o)"
}