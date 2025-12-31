# prepare-cursor-support.ps1
$outDir = 'C:\Users\south\AI-Tools\backups\cursor-support-20251230'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$diag = Join-Path $outDir 'diagnostics.txt'

# Gather environment
$node = (try { node -v } catch { 'node not found' })
$npm = (try { npm -v } catch { 'npm not found' })
$py = (try { python --version } catch { 'python not found' })
$os = (Get-CimInstance -ClassName CIM_OperatingSystem | Select-Object Caption, Version, BuildNumber | Out-String).Trim()
$installer = (Get-ChildItem -Path $env:USERPROFILE\Downloads -Filter '*Cursor*Setup*.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1 | ForEach-Object { $_.FullName }) -join ''

$pkgJson = 'C:\Users\south\AppData\Local\Programs\Cursor\resources\app\node_modules\cursor-proclist\package.json'
$pkgContent = if (Test-Path $pkgJson) { Get-Content $pkgJson -Raw } else { 'package.json not found' }
$indexBak = 'C:\Users\south\AppData\Local\Programs\Cursor\resources\app\node_modules\cursor-proclist\index.js.bak'
$indexBakContent = if (Test-Path $indexBak) { Get-Content $indexBak -Raw } else { 'index.js.bak not found' }

# Compose diagnostics
$diagLines = @()
$diagLines += "Cursor support diagnostics - generated on $(Get-Date -Format o)"
$diagLines += ''
$diagLines += 'System:'
$diagLines += $os
$diagLines += ''
$diagLines += "Node: $node"
$diagLines += "npm: $npm"
$diagLines += "Python: $py"
$diagLines += ''
$diagLines += "Cursor installer found (not included in zip): $installer"
$diagLines += "Missing native addon path: C:\Users\south\AppData\Local\Programs\Cursor\resources\app\node_modules\cursor-proclist\build\Release\cursor_proclist.node"
$diagLines += ''
$diagLines += "cursor-proclist package.json:"; $diagLines += $pkgContent
$diagLines += ''
$diagLines += 'index.js.bak contents (first 2000 chars):'
$firstPart = if ($indexBakContent.Length -gt 2000) { $indexBakContent.Substring(0,2000) + '...[truncated]' } else { $indexBakContent }
$diagLines += $firstPart
$diagLines += ''
$diagLines += 'Actions taken:'
$diagLines += '- Uninstalled and reinstalled Cursor (per-user installer).'
$diagLines += '- Attempted automated download; added fallback stub in cursor-proclist/index.js to avoid crashes.'
$diagLines += '- Installed VS Build Tools and attempted a local rebuild but cursor-proclist has no native sources (no binding.gyp).'
$diagLines += "- Backup of user data: C:\Users\south\AI-Tools\backups\cursor-backup-20251230-181233"
$diagLines += ''
$diagLines += 'Recommended next step: provide prebuilt cursor_proclist.node for v2.2.44 or include in release.'
Set-Content -Path $diag -Value $diagLines -Force

# Copy index.js.bak if present
if (Test-Path $indexBak) { Copy-Item -Path $indexBak -Destination $outDir -Force }
# Create small note about installer availability (not included)
Set-Content -Path (Join-Path $outDir 'installer-available.txt') -Value "Installer available on request: $installer" -Force

# Zip the artifacts
$zip = 'C:\Users\south\AI-Tools\backups\cursor-support-20251230.zip'
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $outDir '*') -DestinationPath $zip
Write-Output "Prepared diagnostics zip: $zip"

# Open Cursor support/contact page
Start-Process 'https://cursor.com/contact'

# Prepare GitHub issue draft (cursor-dev/cursor) and open new issue page with prefilled title/body
$issueTitle = 'Missing native addon cursor_proclist.node in Cursor v2.2.44'
$body = @"
Hi Cursor team,

I’m seeing a failure to load the native process-list addon on Windows in Cursor v2.2.44. The app shows MODULE_NOT_FOUND for cursor_proclist.node and process metrics are not available.

Missing file: C:\Users\south\AppData\Local\Programs\Cursor\resources\app\node_modules\cursor-proclist\build\Release\cursor_proclist.node

I tested reinstall and attempted a rebuild but the package has no native sources (no binding.gyp). I’ve prepared diagnostics (index.js.bak, package.json, environment info) and a zip is ready. The installer binary is available on request.

Please advise on a prebuilt cursor_proclist.node or instructions to build it correctly.

Thanks,
—south
"@
$encTitle = [Uri]::EscapeDataString($issueTitle)
$encBody = [Uri]::EscapeDataString($body)
$repoUrl = "https://github.com/cursor-dev/cursor/issues/new?title=$encTitle&body=$encBody"
Start-Process $repoUrl
Write-Output 'Opened support contact page and drafted GitHub issue (cursor-dev/cursor). Please review and submit.'
