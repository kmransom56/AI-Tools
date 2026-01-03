<#
Normalize the on-disk Port Manager registry so the module won't throw 'The property "Count" cannot be found on this object.'

Usage:
  .\scripts\portmanager\normalize-port-registry.ps1 [-Path <path-to-registry>] [-WhatIf]

What the script does:
- Looks for likely registry files (user profile / AI-Tools)
- Makes a backup (artifacts/backups)
- Reads JSON and attempts to transform into normalized schema:
  {
    "RegisteredPorts": { "app-name": 11000, ... },
    "GeneratedPorts": [11000, ...],
    "Version": 1
  }
- Writes normalized file and prints summary/log
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$Path,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log { param($m) Write-Host "[normalize] $m" }

# Candidate locations (checked in order)
$defaultCandidates = @(
    (Join-Path $env:USERPROFILE 'AI-Tools\port-registry.json'),
    (Join-Path $env:USERPROFILE 'AI-Tools\PortManager\port-registry.json'),
    (Join-Path $env:USERPROFILE '.port-registry.json'),
    (Join-Path $PSScriptRoot '..\..\PortManager\port-registry.json')
) | Get-Unique

if (-not $Path) {
    $Path = $defaultCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $Path) {
        Write-Log "No registry file found in candidates. Provide a path with -Path."; exit 2
    }
}

if (-not (Test-Path $Path)) { Write-Log "Path $Path does not exist."; exit 2 }

$artifacts = Join-Path $PSScriptRoot "..\..\artifacts\backups"
if (-not (Test-Path $artifacts)) { New-Item -ItemType Directory -Path $artifacts -Force | Out-Null }
$backup = Join-Path $artifacts ("port-registry-backup-{0:yyyyMMdd-HHmmss}.json" -f (Get-Date))
Copy-Item -Path $Path -Destination $backup -Force
Write-Log "Backed up $Path -> $backup"

# Read JSON
$jsonText = Get-Content -Path $Path -Raw -ErrorAction Stop
try { $data = ConvertFrom-Json -InputObject $jsonText -ErrorAction Stop } catch { Write-Log "Failed to parse JSON: $($_.Exception.Message)"; exit 2 }

# Helper: build normalized structure
function Build-Normalized([psobject]$obj) {
    $normalized = [ordered]@{ RegisteredPorts = @{}; GeneratedPorts = @(); Version = 1 }

    if ($null -eq $obj) { return $normalized }

    # Case 1: object already has RegisteredPorts
    if ($obj -is [pscustomobject] -and $obj.PSObject.Properties.Name -contains 'RegisteredPorts') {
        # Ensure it's a dictionary
        $rp = $obj.RegisteredPorts
        if ($rp -is [array]) {
            foreach ($entry in $rp) {
                if ($entry -is [pscustomobject] -and $entry.ApplicationName -and $entry.Port) {
                    $normalized.RegisteredPorts[$entry.ApplicationName] = [int]$entry.Port
                }
            }
        } elseif ($rp -is [hashtable] -or $rp -is [pscustomobject]) {
            foreach ($n in $rp.psobject.properties) {
                $normalized.RegisteredPorts[$n.Name] = [int]$n.Value
            }
        }
        # carry GeneratedPorts if present
        if ($obj.GeneratedPorts) { $normalized.GeneratedPorts = @($obj.GeneratedPorts | ForEach-Object {[int]$_}) }
        return $normalized
    }

    # Case 2: registry is an array of records [{ApplicationName, Port}, ...]
    if ($obj -is [array]) {
        foreach ($entry in $obj) {
            if ($entry -is [pscustomobject] -and $entry.ApplicationName -and $entry.Port) {
                $normalized.RegisteredPorts[$entry.ApplicationName] = [int]$entry.Port
                $normalized.GeneratedPorts += [int]$entry.Port
            }
        }
        return $normalized
    }

    # Case 3: object is a hashtable/dictionary of names->ports
    if ($obj -is [pscustomobject] -or $obj -is [hashtable]) {
        foreach ($p in $obj.psobject.properties) {
            if ($p.Value -is [int] -or ($p.Value -as [int])) {
                # name -> port
                $normalized.RegisteredPorts[$p.Name] = [int]$p.Value
            } else {
                # if value is complex, skip
            }
        }
        return $normalized
    }

    # Fallback: unknown format -> leave empty
    return $normalized
}

$norm = Build-Normalized $data

# final sanity check: ensure no non-int ports
$bad = $norm.RegisteredPorts.GetEnumerator() | Where-Object { -not ($_ .Value -is [int]) }
if ($bad) { Write-Log "Normalization produced non-integer port(s); aborting"; exit 3 }

# Write normalized JSON (compact)
$out = $norm | ConvertTo-Json -Depth 5
if ($PSCmdlet.ShouldProcess($Path, "Normalize registry and write normalized file")) {
    if (-not $Force) { Write-Log "Writing normalized registry to $Path" }
    Set-Content -Path $Path -Value $out -Encoding UTF8
    Write-Log "Normalization complete. Registered ports: $($norm.RegisteredPorts.Keys -join ', ')"
}
