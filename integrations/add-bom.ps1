param(
    [string[]]$Files = @("AI-Toolkit-Auto.ps1", "Run-As-Admin.ps1")
)
foreach ($f in $Files) {
    $path = Join-Path $PSScriptRoot "..\$f"
    if (Test-Path $path) {
        $content = Get-Content -LiteralPath $path -Raw -ErrorAction SilentlyContinue
        if ($null -eq $content) { continue }
        # Check for BOM
        if ($content[0] -eq [char]0xFEFF) { Write-Output "$f already has BOM"; continue }
        # Write with BOM (UTF8 with BOM)
        $enc = [System.Text.UTF8Encoding]::new($true)
        [System.IO.File]::WriteAllText($path, $content, $enc)
        Write-Output "Added BOM to $f"
    } else {
        Write-Output "File not found: $path"
    }
}