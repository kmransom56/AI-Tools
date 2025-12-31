# PortManager.psm1
# PowerShell Module for System-Wide Port Management
# Can be imported by any PowerShell script or tool

$script:PortRegistryPath = "$env:USERPROFILE\AI-Tools\port-registry.json"
$script:PreferredRange = @{ Start = 11000; End = 12000 }
$script:MigrationRange = @{ Start = 3000; End = 8000 }

# Initialize port registry if it doesn't exist
function Initialize-PortRegistry {
    if (-not (Test-Path $script:PortRegistryPath)) {
        $registryDir = Split-Path $script:PortRegistryPath -Parent
        if (-not (Test-Path $registryDir)) {
            New-Item -ItemType Directory -Path $registryDir -Force | Out-Null
        }
        $registry = @{
            RegisteredPorts = @{}
            PortHistory = @()
            LastScan = $null
        }
        $registry | ConvertTo-Json -Depth 10 | Set-Content $script:PortRegistryPath
    }
}

# Load port registry
function Get-PortRegistry {
    Initialize-PortRegistry
    $content = Get-Content $script:PortRegistryPath -Raw
    return $content | ConvertFrom-Json
}

# Save port registry
function Save-PortRegistry {
    param([PSCustomObject]$Registry)
    $Registry | ConvertTo-Json -Depth 10 | Set-Content $script:PortRegistryPath
}

# Scan all ports (0-65535) and return in-use ports
function Get-UsedPorts {
    $usedPorts = @()
    
    # Get TCP connections
    $tcpConnections = Get-NetTCPConnection -ErrorAction SilentlyContinue | 
        Where-Object { $_.State -eq "Listen" } | 
        Select-Object -ExpandProperty LocalPort -Unique
    
    # Check common ports from netstat
    $netstatOutput = netstat -ano | Select-String "LISTENING"
    foreach ($line in $netstatOutput) {
        if ($line -match ':\s*(\d+)\s+.*LISTENING') {
            $port = [int]$matches[1]
            if ($port -ge 0 -and $port -le 65535) {
                $usedPorts += $port
            }
        }
    }
    
    # Combine and deduplicate
    $allPorts = ($tcpConnections + $usedPorts) | Sort-Object -Unique
    return $allPorts
}

# Find available port in preferred range (11000-12000)
function Get-AvailablePort {
    param(
        [string]$ApplicationName,
        [int]$PreferredPort = 0
    )
    
    $registry = Get-PortRegistry
    $usedPorts = Get-UsedPorts
    
    # If preferred port is specified and available, use it
    if ($PreferredPort -ge $script:PreferredRange.Start -and $PreferredPort -le $script:PreferredRange.End) {
        if ($usedPorts -notcontains $PreferredPort -and $registry.RegisteredPorts.Keys -notcontains $PreferredPort.ToString()) {
            Register-Port -Port $PreferredPort -ApplicationName $ApplicationName
            return $PreferredPort
        }
    }
    
    # Find first available port in preferred range
    for ($port = $script:PreferredRange.Start; $port -le $script:PreferredRange.End; $port++) {
        if ($usedPorts -notcontains $port -and $registry.RegisteredPorts.Keys -notcontains $port.ToString()) {
            Register-Port -Port $port -ApplicationName $ApplicationName
            return $port
        }
    }
    
    return $null
}

# Register a port in the system-wide registry
function Register-Port {
    param(
        [int]$Port,
        [string]$ApplicationName,
        [string]$Description = ""
    )
    
    $registry = Get-PortRegistry
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $registry.RegisteredPorts[$Port.ToString()] = @{
        ApplicationName = $ApplicationName
        Description = $Description
        RegisteredAt = $timestamp
        LastUsed = $timestamp
    }
    
    $registry.PortHistory += @{
        Port = $Port
        ApplicationName = $ApplicationName
        Action = "Registered"
        Timestamp = $timestamp
    }
    
    Save-PortRegistry -Registry $registry
    return $Port
}

# Get port for an application
function Get-ApplicationPort {
    param([string]$ApplicationName)
    
    $registry = Get-PortRegistry
    foreach ($port in $registry.RegisteredPorts.Keys) {
        if ($registry.RegisteredPorts[$port].ApplicationName -eq $ApplicationName) {
            return [int]$port
        }
    }
    return $null
}

# Export functions
Export-ModuleMember -Function @(
    'Get-AvailablePort',
    'Register-Port',
    'Get-UsedPorts',
    'Get-ApplicationPort',
    'Get-PortRegistry',
    'Save-PortRegistry'
)

