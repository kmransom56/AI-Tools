param(
    [string]$Path = (Join-Path -Path $PSScriptRoot -ChildPath '..\AI-Toolkit-Auto.ps1'),
    [int]$LineNumber = 171
)
$lines = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -Force -ErrorAction Stop
$arr = $lines -split '\r?\n'
if ($LineNumber -lt 1 -or $LineNumber -gt $arr.Count) { Write-Output "Line number $LineNumber out of range for $Path"; exit 1 }
$line = $arr[$LineNumber - 1]
Write-Output ("Line {0}: {1}" -f $LineNumber, $line)
$chars = $line.ToCharArray()
for ($i=0; $i -lt $chars.Length; $i++) {
    $c = $chars[$i]
    Write-Output ('{0,3}: U+{1:X4} "{2}"' -f $i, [int]$c, $c)
}