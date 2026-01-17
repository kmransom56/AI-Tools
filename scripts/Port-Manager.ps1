# Port-Manager.ps1
# Windows PowerShell Port Management System
# Provides functions to find, register, and query available ports

param()

# Global port registry path
$script:PortRegistryPath = "$env:USERPROFILE\AI-Tools\port-registry.json"
$script:PortRegistryDir = Split-Path -Parent $script:PortRegistryPath

# Initialize port registry if not exists
function Initialize-PortRegistry {
    if (-not (Test-Path $script:PortRegistryDir)) {
        New-Item -ItemType Directory -Path $script:PortRegistryDir -Force | Out-Null
    }
    if (-not (Test-Path $script:PortRegistryPath)) {
        $registry = @{
            version = "1.0"
            createdAt = (Get-Date).ToString("O")
            registeredPorts = @{}
        }
        $registry | ConvertTo-Json | Set-Content -Path $script:PortRegistryPath -Encoding UTF8
    }
}

# Get the current port registry
function Get-PortRegistry {
    Initialize-PortRegistry
    try {
        $content = Get-Content -Path $script:PortRegistryPath -Raw -ErrorAction Stop
        return $content | ConvertFrom-Json
    }
    catch {
        Write-Error "Failed to read port registry: $_"
        return @{ registeredPorts = @{} }
    }
}

# Save the port registry
function Save-PortRegistry {
    param([Parameter(Mandatory = $true)] $Registry)
    try {
        $Registry | ConvertTo-Json -Depth 10 | Set-Content -Path $script:PortRegistryPath -Encoding UTF8
    }
    catch {
        Write-Error "Failed to save port registry: $_"
    }
}

# Get all currently used ports (via netstat and Get-NetTCPConnection)
function Get-UsedPorts {
    $usedPorts = @()
    
    # Method 1: PowerShell cmdlet (faster, works on Windows 8+)
    try {
        $tcpConnections = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue
        $usedPorts += $tcpConnections | Select-Object -ExpandProperty LocalPort -Unique
    }
    catch {
        Write-Verbose "Get-NetTCPConnection failed: $_"
    }
    
    # Method 2: netstat parsing (more reliable)
    try {
        $netstatOutput = netstat -ano 2>$null | Select-String "LISTENING"
        foreach ($line in $netstatOutput) {
            if ($line -match ":(\d+)\s+.*LISTENING") {
                $port = [int]$matches[1]
                if ($port -notin $usedPorts) {
                    $usedPorts += $port
                }
            }
        }
    }
    catch {
        Write-Verbose "netstat parsing failed: $_"
    }
    
    # Deduplicate and sort
    return ($usedPorts | Sort-Object -Unique)
}

# Get available port in the preferred range
function Get-AvailablePort {
    param(
        [Parameter(Mandatory = $true)] [string] $ApplicationName,
        [int] $PreferredPort = 11000,
        [int] $MinPort = 11000,
        [int] $MaxPort = 12000
    )
    
    $usedPorts = Get-UsedPorts
    
    # First, try the preferred port
    if ($PreferredPort -ge $MinPort -and $PreferredPort -le $MaxPort) {
        if ($PreferredPort -notin $usedPorts) {
            return $PreferredPort
        }
    }
    
    # Otherwise, find first available in range
    for ($port = $MinPort; $port -le $MaxPort; $port++) {
        if ($port -notin $usedPorts) {
            return $port
        }
    }
    
    throw "No available ports in range $MinPort-$MaxPort"
}

# Register a port for an application
function Register-Port {
    param(
        [Parameter(Mandatory = $true)] [int] $Port,
        [Parameter(Mandatory = $true)] [string] $ApplicationName,
        [string] $Description = ""
    )
    
    $registry = Get-PortRegistry
    $registry.registeredPorts[$ApplicationName] = @{
        port = $Port
        description = $Description
        registeredAt = (Get-Date).ToString("O")
    }
    Save-PortRegistry $registry
    Write-Verbose "Port $Port registered for $ApplicationName"
}

# Get a registered application's port
function Get-ApplicationPort {
    param([Parameter(Mandatory = $true)] [string] $ApplicationName)
    
    $registry = Get-PortRegistry
    if ($registry.registeredPorts.ContainsKey($ApplicationName)) {
        return $registry.registeredPorts[$ApplicationName].port
    }
    return $null
}

# List all registered ports
function Get-RegisteredPorts {
    $registry = Get-PortRegistry
    return $registry.registeredPorts
}

# Check if a specific port is available
function Test-PortAvailable {
    param([Parameter(Mandatory = $true)] [int] $Port)
    
    $usedPorts = Get-UsedPorts
    return ($Port -notin $usedPorts)
}

# Export functions for use in other scripts
Export-ModuleMember -Function @(
    'Get-AvailablePort',
    'Register-Port',
    'Get-ApplicationPort',
    'Get-RegisteredPorts',
    'Get-UsedPorts',
    'Test-PortAvailable',
    'Get-PortRegistry',
    'Save-PortRegistry',
    'Initialize-PortRegistry'
)

# Verbose output
Write-Verbose "Port Manager loaded. Registry: $script:PortRegistryPath"

