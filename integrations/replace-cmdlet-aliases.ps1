<#
Replaces common cmdlet aliases with full cmdlet names using PowerShell AST.
Usage: .\integrations\replace-cmdlet-aliases.ps1 -RootPath . -WhatIf

This script:
 - Scans all .ps1, .psm1, .psd1 files under -RootPath (defaults to repo root)
 - Uses the AST to find CommandAst nodes and replaces only the command token when it's a known alias
 - Creates a .bak backup of modified files
 - Prints a summary at the end
#>
param(
    [string]$RootPath = '.',
    [switch]$WhatIf
)

$aliasMap = @{
    'echo' = 'Write-Output'
    'cd'   = 'Set-Location'
    'ls'   = 'Get-ChildItem'
    'dir'  = 'Get-ChildItem'
    'rm'   = 'Remove-Item'
    'del'  = 'Remove-Item'
    'cp'   = 'Copy-Item'
    'mv'   = 'Move-Item'
    'pwd'  = 'Get-Location'
    'cat'  = 'Get-Content'
    'type' = 'Get-Content'
}

$files = Get-ChildItem -Path $RootPath -Recurse -File -Include *.ps1,*.psm1,*.psd1 -ErrorAction SilentlyContinue
if (-not $files) { Write-Output "No PowerShell files found under $RootPath"; exit 0 }

$modified = @()
foreach ($f in $files) {
    try {
        $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Stop
    } catch {
        Write-Verbose "Skipping unreadable file: $($f.FullName)"
        continue
    }

    # Parse AST (handle parse exceptions)
    $errors = $null
    try {
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($text, [ref]$errors, [ref]$null)
    } catch {
        Write-Verbose "Parser exception for $($f.FullName): $($_.Exception.Message) - skipping"
        continue
    }
    if ($errors) {
        Write-Verbose "Parsing errors in $($f.FullName) - skipping"
        continue
    }

    $edits = [System.Collections.Generic.List[PSObject]]::new()

    $cmds = $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.CommandAst] }, $true)
    foreach ($cmd in $cmds) {
        $name = $cmd.GetCommandName()
        if (-not $name) { continue }
        $lname = $name.ToLowerInvariant()
        if ($aliasMap.ContainsKey($lname)) {
            # Get the first command element's extent to replace the command token
            $first = $cmd.CommandElements | Select-Object -First 1
            if ($null -eq $first) { continue }
            $start = $first.Extent.StartOffset
            $end = $first.Extent.EndOffset
            # Ensure offsets valid
            if ($start -ge 0 -and $end -ge $start) {
                $edits.Add([PSCustomObject]@{Start=$start;End=$end;NewText=$aliasMap[$lname];OldText=$text.Substring($start, $end - $start + 1);Name=$name }) | Out-Null
            }
        }
    }

    if ($edits.Count -gt 0) {
        # Apply edits in reverse order to avoid shifting offsets
        $edits = $edits | Sort-Object -Property Start -Descending
        $sb = New-Object System.Text.StringBuilder $text
        foreach ($e in $edits) {
            if ($WhatIf) { Write-Output "Would replace in $($f.FullName): '$($e.OldText)' -> '$($e.NewText)'"; continue }
            $length = $e.End - $e.Start + 1
            $sb.Remove($e.Start, $length)
            $sb.Insert($e.Start, $e.NewText) | Out-Null
        }
        if (-not $WhatIf) {
            Copy-Item -LiteralPath $f.FullName -Destination ($f.FullName + '.bak') -Force
            [System.IO.File]::WriteAllText($f.FullName, $sb.ToString(), [System.Text.Encoding]::UTF8)
            Write-Output "Replaced $($edits.Count) alias(es) in $($f.FullName)"
            $modified += $f.FullName
        }
    }
}

if ($modified.Count -eq 0) { Write-Output "No alias usages replaced." } else { Write-Output "Modified files: $(($modified | Measure-Object).Count)" }

# Return modified files list for calling script
$modified | ForEach-Object { Write-Output $_ }
