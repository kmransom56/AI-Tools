# find-msbuild.ps1
$paths = @(
    'C:\Program Files\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe',
    'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe',
    'C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe'
)
foreach ($p in $paths) {
    if (Test-Path $p) { Write-Host "Found MSBuild at $p"; exit 0 }
}
$vswhere = "$env:ProgramFiles(x86)\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vswhere) {
    $inst = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath 2>$null
    if ($inst) {
        $ms = Join-Path $inst 'MSBuild\Current\Bin\MSBuild.exe'
        if (Test-Path $ms) { Write-Host "Found MSBuild via vswhere: $ms"; exit 0 }
    }
}
Write-Host 'MSBuild not found'
