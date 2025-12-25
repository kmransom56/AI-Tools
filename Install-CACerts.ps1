# Install-CACerts.ps1
# This script installs the root and intermediate CA certificates to the local machine's certificate store.
# This is necessary to establish trust for the custom certificates used in this project.

# ---------------------------
# Admin Check
# ---------------------------
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
  Write-Warning "This script must be run as an Administrator to install system-wide certificates."
  exit 1
}

# ---------------------------
# Install Root CA Certificate
# ---------------------------
try {
  Write-Host "Importing Root CA certificate (real_root.crt)..."
  Import-Certificate -FilePath ".\real_root.crt" -CertStoreLocation "Cert:\LocalMachine\Root" -ErrorAction Stop
  Write-Host "Root CA certificate imported successfully." -ForegroundColor Green
} catch {
  Write-Error "Failed to import Root CA certificate: $_"
  exit 1
}

# ---------------------------
# Install Intermediate CA Certificate
# ---------------------------
try {
  Write-Host "Importing Intermediate CA certificate (real_intermediate.crt)..."
  Import-Certificate -FilePath ".\real_intermediate.crt" -CertStoreLocation "Cert:\LocalMachine\CA" -ErrorAction Stop
  Write-Host "Intermediate CA certificate imported successfully." -ForegroundColor Green
} catch {
  Write-Error "Failed to import Intermediate CA certificate: $_"
  exit 1
}

Write-Host "CA certificates have been installed. Please try the operation that was failing before."
