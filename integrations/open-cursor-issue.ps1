$issueTitle = 'Missing native addon cursor_proclist.node in Cursor v2.2.44'
$body = @'
Hi Cursor team,

I’m seeing a failure to load the native process-list addon on Windows in Cursor v2.2.44. The app shows MODULE_NOT_FOUND for cursor_proclist.node and process metrics are not available.

Missing file: C:\Users\south\AppData\Local\Programs\Cursor\resources\app\node_modules\cursor-proclist\build\Release\cursor_proclist.node

I tested reinstall and attempted a rebuild but the package has no native sources (no binding.gyp). I’ve prepared diagnostics (index.js.bak, package.json, environment info) and a zip is ready (C:\Users\south\AI-Tools\backups\cursor-support-20251230.zip). The installer binary is available on request.

Please advise on a prebuilt cursor_proclist.node or instructions to build it correctly.

Thanks,
—south
'@
$encTitle = [System.Uri]::EscapeDataString($issueTitle)
$encBody = [System.Uri]::EscapeDataString($body)
$url = "https://github.com/cursor/cursor/issues/new?title=$encTitle&body=$encBody"
Write-Host "Opening: $url"
Start-Process $url
