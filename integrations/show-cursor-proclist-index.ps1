$pkg='C:\Users\south\AppData\Local\Programs\Cursor\resources\app\node_modules\cursor-proclist'
if (Test-Path $pkg) {
    $index = Join-Path $pkg 'index.js'
    if (Test-Path $index) { Get-Content $index -Raw | Write-Host } else { Write-Host 'index.js not found' }
} else { Write-Host 'Package dir not found' }