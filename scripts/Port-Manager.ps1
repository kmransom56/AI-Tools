# Port-Manager.ps1
# System-wide port management and registry

$PortRegistryPath = "$env:USERPROFILE\AI-Tools\port-registry.json"
$PreferredRange = @{ Start = 11000; End = 12000 }
$MigrationRange = @{ Start = 3000; End = 8000 }

# Initialize port registry if it doesn't exist
function Initialize-PortRegistry {
    if (-not (Test-Path $PortRegistryPath)) {
        $registry = @{
            RegisteredPorts = @{}
            PortHistory = @()
            LastScan = $null
        }
        $registry | ConvertTo-Json -Depth 10 | Set-Content $PortRegistryPath
        Write-Host "Created new port registry at: $PortRegistryPath" -ForegroundColor Green
    }
}

# Load port registry
function Get-PortRegistry {
    Initialize-PortRegistry
    $content = Get-Content $PortRegistryPath -Raw
    return $content | ConvertFrom-Json
}

# Save port registry
function Save-PortRegistry {
    param([PSCustomObject]$Registry)
    $Registry | ConvertTo-Json -Depth 10 | Set-Content $PortRegistryPath
}

# Scan all ports (0-65535) and return in-use ports
function Get-UsedPorts {
    Write-Host "Scanning ports 0-65535 for active connections..." -ForegroundColor Cyan
    $usedPorts = @()
    
    # Get TCP connections
    $tcpConnections = Get-NetTCPConnection -ErrorAction SilentlyContinue | 
        Where-Object { $_.State -eq "Listen" } | 
        Select-Object -ExpandProperty LocalPort -Unique
    
    # Get UDP listeners (Windows doesn't show UDP listeners easily, so we check processes)
    $processes = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path }
    
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
    Write-Host "Found $($allPorts.Count) ports in use" -ForegroundColor Green
    return $allPorts
}

# Find available port in preferred range (11000-12000)
function Find-AvailablePort {
    param(
        [string]$ApplicationName,
        [int]$PreferredPort = 0
    )
    
    $registry = Get-PortRegistry
    $usedPorts = Get-UsedPorts
    
    # If preferred port is specified and available, use it
    if ($PreferredPort -ge $PreferredRange.Start -and $PreferredPort -le $PreferredRange.End) {
        if ($usedPorts -notcontains $PreferredPort -and $registry.RegisteredPorts.Keys -notcontains $PreferredPort.ToString()) {
            Register-Port -Port $PreferredPort -ApplicationName $ApplicationName
            return $PreferredPort
        }
    }
    
    # Find first available port in preferred range
    for ($port = $PreferredRange.Start; $port -le $PreferredRange.End; $port++) {
        if ($usedPorts -notcontains $port -and $registry.RegisteredPorts.Keys -notcontains $port.ToString()) {
            Register-Port -Port $port -ApplicationName $ApplicationName
            return $port
        }
    }
    
    Write-Host "WARNING: No available ports in range $($PreferredRange.Start)-$($PreferredRange.End)" -ForegroundColor Yellow
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
    Write-Host "Registered port $Port for $ApplicationName" -ForegroundColor Green
}

# Unregister a port
function Unregister-Port {
    param([int]$Port)
    
    $registry = Get-PortRegistry
    if ($registry.RegisteredPorts.ContainsKey($Port.ToString())) {
        $appName = $registry.RegisteredPorts[$Port.ToString()].ApplicationName
        $registry.RegisteredPorts.Remove($Port.ToString())
        
        $registry.PortHistory += @{
            Port = $Port
            ApplicationName = $appName
            Action = "Unregistered"
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        Save-PortRegistry -Registry $registry
        Write-Host "Unregistered port $Port" -ForegroundColor Yellow
    }
}

# Get applications using ports in migration range (3000-8000)
function Get-ApplicationsInMigrationRange {
    $usedPorts = Get-UsedPorts
    $migrationCandidates = @()
    
    foreach ($port in $usedPorts) {
        if ($port -ge $MigrationRange.Start -and $port -le $MigrationRange.End) {
            # Try to identify the application using this port
            $processInfo = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue |
                Select-Object -First 1 -ExpandProperty OwningProcess
            
            $appName = "Unknown"
            if ($processInfo) {
                try {
                    $process = Get-Process -Id $processInfo -ErrorAction SilentlyContinue
                    $appName = $process.ProcessName
                } catch {
                    $appName = "PID:$processInfo"
                }
            }
            
            $migrationCandidates += @{
                Port = $port
                Application = $appName
                ProcessId = $processInfo
            }
        }
    }
    
    return $migrationCandidates
}

# Migrate port from 3000-8000 range to 11000-12000 range
function Migrate-Port {
    param(
        [int]$OldPort,
        [string]$ApplicationName
    )
    
    Write-Host "Migrating port $OldPort to preferred range for $ApplicationName..." -ForegroundColor Cyan
    
    # Find new port
    $newPort = Find-AvailablePort -ApplicationName $ApplicationName
    
    if ($newPort) {
        # Register the migration
        $registry = Get-PortRegistry
        $registry.PortHistory += @{
            OldPort = $OldPort
            NewPort = $newPort
            ApplicationName = $ApplicationName
            Action = "Migrated"
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        # Mark old port as migrated
        if ($registry.RegisteredPorts.ContainsKey($OldPort.ToString())) {
            $registry.RegisteredPorts[$OldPort.ToString()].MigratedTo = $newPort
        }
        
        Save-PortRegistry -Registry $registry
        
        Write-Host "✅ Port migration: $OldPort -> $newPort" -ForegroundColor Green
        return $newPort
    } else {
        Write-Host "❌ Failed to find available port for migration" -ForegroundColor Red
        return $null
    }
}

# List all registered ports
function Show-PortRegistry {
    $registry = Get-PortRegistry
    $usedPorts = Get-UsedPorts
    
    Write-Host "`n=== Port Registry ===" -ForegroundColor Cyan
    Write-Host "Registered Ports:" -ForegroundColor Yellow
    
    if ($registry.RegisteredPorts.Count -eq 0) {
        Write-Host "  No ports registered" -ForegroundColor Gray
    } else {
        foreach ($port in ($registry.RegisteredPorts.Keys | Sort-Object { [int]$_ })) {
            $info = $registry.RegisteredPorts[$port]
            $inUse = if ($usedPorts -contains [int]$port) { " (IN USE)" } else { " (available)" }
            Write-Host "  Port $port : $($info.ApplicationName) - Registered: $($info.RegisteredAt)$inUse" -ForegroundColor White
        }
    }
    
    Write-Host "`nApplications in migration range ($($MigrationRange.Start)-$($MigrationRange.End)):" -ForegroundColor Yellow
    $migrationCandidates = Get-ApplicationsInMigrationRange
    if ($migrationCandidates.Count -eq 0) {
        Write-Host "  None found" -ForegroundColor Gray
    } else {
        foreach ($candidate in $migrationCandidates) {
            Write-Host "  Port $($candidate.Port) : $($candidate.Application) (PID: $($candidate.ProcessId))" -ForegroundColor White
        }
    }
}

# Update registry with current port scan
function Update-PortRegistry {
    $registry = Get-PortRegistry
    $registry.LastScan = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Save-PortRegistry -Registry $registry
    Write-Host "Port registry updated" -ForegroundColor Green
}

# Export functions for use in other scripts
Export-ModuleMember -Function @(
    'Find-AvailablePort',
    'Register-Port',
    'Unregister-Port',
    'Get-UsedPorts',
    'Get-ApplicationsInMigrationRange',
    'Migrate-Port',
    'Show-PortRegistry',
    'Update-PortRegistry',
    'Get-PortRegistry'
)

