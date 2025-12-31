$out = "C:\Users\south\AI-Tools\backups\psscriptanalyzer-report-$(Get-Date -Format yyyyMMdd-HHmmss)"
$csv = $out + '.csv'
Write-Output "Running PSScriptAnalyzer across repository (this may take a few minutes)..."
$results = Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error,Warning,Information -IncludeRuleId
$results | Select-Object Severity,RuleName,RuleId,ScriptName,Line,Message | Export-Csv -Path $csv -NoTypeInformation -Force
Write-Output "Saved report: $csv"
Write-Output "Found $($results.Count) issues"
