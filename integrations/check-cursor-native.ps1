# check-cursor-native.ps1
$nodePath = 'C:\Users\south\AppData\Local\Programs\Cursor\resources\app\node_modules\cursor-proclist\build\Release\cursor_proclist.node'
Write-Host "Checking: $nodePath"
if (Test-Path $nodePath) { Write-Host "FOUND: $nodePath" -ForegroundColor Green } else { Write-Host "MISSING: $nodePath" -ForegroundColor Red }

$pkg = 'C:\Users\south\AppData\Local\Programs\Cursor\resources\app\node_modules\cursor-proclist'
if (Test-Path $pkg) {
    Write-Host "\nListing package directory: $pkg" -ForegroundColor Cyan
    Get-ChildItem -Path $pkg -Recurse | Select-Object FullName, Length | Format-Table -AutoSize
} else {
    Write-Host "Package dir not found: $pkg" -ForegroundColor Yellow
}