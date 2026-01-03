# Run PortManager tests and write results to a log
# Usage: .\scripts\portmanager\run-portmanager-tests.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Log location
$artifacts = Join-Path $PSScriptRoot "..\..\artifacts"
if (-not (Test-Path $artifacts)) { New-Item -ItemType Directory -Path $artifacts -Force | Out-Null }
$logFile = Join-Path $artifacts ("portmanager-test-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))

function Log { param($m) Add-Content -Path $logFile -Value ("[{0}] {1}" -f (Get-Date -Format 'o'), $m) }

try {
    Log "Starting PortManager tests"

    $modulePath = Join-Path $PSScriptRoot "..\..\PortManager\PortManager.psm1"
    Log "Importing module: $modulePath"
    Import-Module $modulePath -Force -ErrorAction Stop
    Log "Module imported"

    Log "Checking Get-UsedPorts"
    $used = Get-UsedPorts
    Log ("Get-UsedPorts returned {0} ports" -f ($used | Measure-Object | Select-Object -ExpandProperty Count))

    Log "Checking Get-AvailablePort (auto-register) for 'test-app'"
    $port = Get-AvailablePort -ApplicationName 'test-app' -AutoRegister -ErrorAction Stop
    Log ("Get-AvailablePort returned: $port")

    Log "Show-PortRegistry output:" 
    $registry = Show-PortRegistry 2>&1 | Out-String
    Add-Content -Path $logFile -Value $registry

    Log "Verifying registration exists"
    $appPort = Get-ApplicationPort -ApplicationName 'test-app'
    if ($appPort) { Log ("Application 'test-app' registered at port: $appPort") } else { Log "Application 'test-app' not found in registry" }

    Log "SUCCESS"
    Start-Process notepad.exe -ArgumentList $logFile
    exit 0
} catch {
    Log ("ERROR: $($_.Exception.Message)")
    Log "StackTrace: $($_.Exception.StackTrace)"
    Start-Process notepad.exe -ArgumentList $logFile
    exit 1
}