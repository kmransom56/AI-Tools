# Update-Port-Configurations.ps1
# Updates application configurations to use ports from registry

param(
    [switch]$MigrateAll,
    [switch]$DryRun
)

# Import port manager
. "$PSScriptRoot\Port-Manager.ps1"

Write-Host "=== Port Configuration Updater ===" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
}

# Get applications that need port migration
$migrationCandidates = Get-ApplicationsInMigrationRange

if ($migrationCandidates.Count -eq 0) {
    Write-Host "No applications found in migration range (3000-8000)" -ForegroundColor Green
    exit 0
}

Write-Host "`nFound $($migrationCandidates.Count) applications in migration range:" -ForegroundColor Yellow
foreach ($candidate in $migrationCandidates) {
    Write-Host "  Port $($candidate.Port) : $($candidate.Application)" -ForegroundColor White
}

if (-not $MigrateAll) {
    $confirm = Read-Host "`nMigrate these ports to 11000-12000 range? (Y/N)"
    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        Write-Host "Migration cancelled" -ForegroundColor Yellow
        exit 0
    }
}

# Update docker-compose.yml if it exists
$dockerComposePath = "$env:USERPROFILE\AI-Tools\docker-compose.yml"
if (Test-Path $dockerComposePath) {
    Write-Host "`nUpdating docker-compose.yml..." -ForegroundColor Cyan
    $composeContent = Get-Content $dockerComposePath -Raw
    
    # Update TabbyML port (8080 -> new port)
    if ($composeContent -match "tabbyml:" -and $composeContent -match "8080:8080") {
        $newPort = Find-AvailablePort -ApplicationName "TabbyML" -PreferredPort 11080
        if ($newPort) {
            if (-not $DryRun) {
                $composeContent = $composeContent -replace "8080:8080", "${newPort}:8080"
                $composeContent | Set-Content $dockerComposePath
                Write-Host "  Updated TabbyML port: 8080 -> $newPort" -ForegroundColor Green
            } else {
                Write-Host "  [DRY RUN] Would update TabbyML port: 8080 -> $newPort" -ForegroundColor Gray
            }
        }
    }
    
    # Update AI Toolkit port (8000 -> new port)
    if ($composeContent -match "8000:8000") {
        $newPort = Find-AvailablePort -ApplicationName "AI-Toolkit" -PreferredPort 11000
        if ($newPort) {
            if (-not $DryRun) {
                $composeContent = $composeContent -replace "8000:8000", "${newPort}:8000"
                $composeContent | Set-Content $dockerComposePath
                Write-Host "  Updated AI Toolkit port: 8000 -> $newPort" -ForegroundColor Green
            } else {
                Write-Host "  [DRY RUN] Would update AI Toolkit port: 8000 -> $newPort" -ForegroundColor Gray
            }
        }
    }
}

# Update other configuration files as needed
Write-Host "`nPort configuration update complete!" -ForegroundColor Green
Show-PortRegistry

