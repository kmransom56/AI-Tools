# find-old-profile-paths.ps1
# Search PowerShell profile files and OneDrive PowerShell folder for hard-coded old user path
$profiles=@($PROFILE.AllUsersAllHosts,$PROFILE.AllUsersCurrentHost,$PROFILE.CurrentUserAllHosts,$PROFILE.CurrentUserCurrentHost)
foreach ($p in $profiles) {
    Write-Host "---- PROFILE: $p"
    if (Test-Path $p) {
        $matches = Select-String -Path $p -Pattern 'Keith Ransom','C:\\Users\\Keith' -SimpleMatch -ErrorAction SilentlyContinue
        foreach ($m in $matches) {
            Write-Host ('Match in {0}:' -f $p)
            Write-Host $m.Line
            Write-Host ''
        }
    } else {
        Write-Host "Not found: $p"
    }
}
$one = Join-Path $env:USERPROFILE 'OneDrive\Documents\PowerShell'
if (Test-Path $one) {
    Write-Host "---- Searching OneDrive folder: $one"
    Get-ChildItem $one -Filter *.ps1 -File -ErrorAction SilentlyContinue | ForEach-Object {
        $matches = Select-String -Path $_.FullName -Pattern 'Keith Ransom','C:\\Users\\Keith' -SimpleMatch -ErrorAction SilentlyContinue
        foreach ($m in $matches) {
            Write-Host ('Match in {0}:' -f $_.FullName)
            Write-Host $m.Line
            Write-Host ''
        }
    }
} else {
    Write-Host "OneDrive folder not found: $one"
}