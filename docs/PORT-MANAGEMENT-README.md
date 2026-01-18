# Port Management System

## Overview
The port management system ensures applications don't conflict by:
- Scanning all ports (0-65535) for active connections
- Assigning ports from preferred range (11000-12000)
- Migrating applications from 3000-8000 range to 11000-12000
- Maintaining a system-wide port registry

## Files
- `Port-Manager.ps1` - Core port management functions
- `Update-Port-Configurations.ps1` - Updates application configs with new ports
- `port-registry.json` - System-wide port registry (auto-created)

## Usage

### Show Port Registry
```powershell
. .\Port-Manager.ps1
Show-PortRegistry
```

### Find Available Port
```powershell
. .\Port-Manager.ps1
$port = Find-AvailablePort -ApplicationName "MyApp"
```

### Migrate Ports
```powershell
. .\Update-Port-Configurations.ps1 -MigrateAll
```

### Check Ports in Use
```powershell
. .\Port-Manager.ps1
$usedPorts = Get-UsedPorts
```

## Port Ranges
- **Preferred Range**: 11000-12000 (for new applications)
- **Migration Range**: 3000-8000 (applications to migrate)
- **Full Scan**: 0-65535 (all ports)

## Registry Location
`$env:USERPROFILE\AI-Tools\port-registry.json`

