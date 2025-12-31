Import-Module PSScriptAnalyzer -ErrorAction Stop
$report = Invoke-ScriptAnalyzer -Path . -Recurse -Severity Warning,Information,Error -ErrorAction SilentlyContinue
$outCsv = Join-Path -Path (Get-Location) -ChildPath ("backups\psscriptanalyzer-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv")
$outJson = Join-Path -Path (Get-Location) -ChildPath ("backups\psscriptanalyzer-summary-$(Get-Date -Format 'yyyyMMdd-HHmmss').json")
$report | Select-Object Severity,RuleName,RuleId,ScriptName,Line,Message | Export-Csv -Path $outCsv -NoTypeInformation -Force -Encoding UTF8
# Summary by Rule
$summary = $report | Group-Object RuleName | Sort-Object Count -Descending | Select-Object @{Name='Rule';Expression={$_.Name}},@{Name='Count';Expression={$_.Count}}
$summary | ConvertTo-Json | Out-File -FilePath $outJson -Encoding UTF8 -Force
Write-Output "CSV: $outCsv`nSummary: $outJson"