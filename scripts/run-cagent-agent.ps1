param(
  [string] $Config = 'cagent/examples/golang_developer.yaml',
  [switch] $Live
)

$ArtDir = Join-Path $PSScriptRoot '..\artifacts' -Resolve
if (-not (Test-Path $ArtDir)) { New-Item -ItemType Directory -Path $ArtDir | Out-Null }
$Log = Join-Path $ArtDir "cagent-run-$(Get-Date -Format s).log"

Write-Host "Running cagent with config: $Config (live: $($Live.IsPresent))"
if ($Live.IsPresent) {
  docker run --rm -v "$PWD":/work -w /work docker/cagent:latest run $Config 2>&1 | Tee-Object -FilePath $Log
} else {
  docker run --rm -v "$PWD":/work -w /work docker/cagent:latest run $Config --dry-run 2>&1 | Tee-Object -FilePath $Log
}

Write-Host "Logs written to: $Log"