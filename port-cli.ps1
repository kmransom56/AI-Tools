# port-cli.ps1
# Command-line interface for port management
# Can be called from any tool or script

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('get', 'register', 'list', 'check', 'migrate')]
    [string]$Command,
    
    [string]$ApplicationName,
    [int]$Port = 0,
    [string]$Description = ""
)

# Import the module
$modulePath = Join-Path $PSScriptRoot "PortManager\PortManager.psm1"
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "PortManager module not found at: $modulePath"
    exit 1
}

switch ($Command) {
    'get' {
        if (-not $ApplicationName) {
            Write-Error "ApplicationName is required for 'get' command"
            exit 1
        }
        $port = Get-AvailablePort -ApplicationName $ApplicationName -PreferredPort $Port
        if ($port) {
            Write-Output $port
            exit 0
        } else {
            Write-Error "No available port found"
            exit 1
        }
    }
    
    'register' {
        if (-not $ApplicationName -or $Port -eq 0) {
            Write-Error "ApplicationName and Port are required for 'register' command"
            exit 1
        }
        Register-Port -Port $Port -ApplicationName $ApplicationName -Description $Description
        Write-Output "Registered port $Port for $ApplicationName"
        exit 0
    }
    
    'list' {
        $registry = Get-PortRegistry
        $registry.RegisteredPorts | ConvertTo-Json -Depth 10
        exit 0
    }
    
    'check' {
        if (-not $ApplicationName) {
            Write-Error "ApplicationName is required for 'check' command"
            exit 1
        }
        $port = Get-ApplicationPort -ApplicationName $ApplicationName
        if ($port) {
            Write-Output $port
            exit 0
        } else {
            Write-Error "No port registered for $ApplicationName"
            exit 1
        }
    }
    
    'migrate' {
        $usedPorts = Get-UsedPorts
        $migrationCandidates = $usedPorts | Where-Object { $_ -ge 3000 -and $_ -le 8000 }
        Write-Output ($migrationCandidates | ConvertTo-Json)
        exit 0
    }
}

