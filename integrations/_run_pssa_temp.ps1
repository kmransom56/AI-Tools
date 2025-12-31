Import-Module PSScriptAnalyzer -ErrorAction Stop
$report = Invoke-ScriptAnalyzer -Path . -Recurse -Severity Warning,Information,Error -Force
$cols = $report | Select-Object Severity,RuleName,RuleId,ScriptName,Line,Message
$outfile = Join-Path -Path (Get-Location) -ChildPath ("backups\psscriptanalyzer-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv")
$cols | Export-Csv -Path $outfile -NoTypeInformation -Force -Encoding UTF8
Write-Output "Report: $outfile"