<# run-cagent-agent.ps1 — Safe wrapper to run cagent examples (PowerShell)
   Defaults to a dry run by setting CAGENT_DRY_RUN=1 in the environment when using the docker image.
#>
param(
  [Parameter(Mandatory=$true)][string]$ExamplePath,
  [Parameter(Mandatory=$false)][string[]]$Args
)

if (Get-Command cagent -ErrorAction SilentlyContinue) {
  Write-Host "Using local cagent CLI (dry-run mode enforced by wrapper)."
  $env:CAGENT_DRY_RUN = '1'
  & cagent run $ExamplePath @Args
  exit $LASTEXITCODE
}

# Run with Docker image and mount socket
$Image = 'docker/cagent:latest'
Write-Host "Running via Docker image: $Image (dry-run mode enforced by wrapper)"
$pwd = (Get-Location).Path
docker run --rm -e CAGENT_DRY_RUN=1 -v /var/run/docker.sock:/var/run/docker.sock -v "${pwd}:/workspace" -w /workspace $Image run $ExamplePath @Args
