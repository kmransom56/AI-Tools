Import-Module PSScriptAnalyzer -Force
$out = "C:\Users\south\AI-Tools\backups\psscriptanalyzer-report-$(Get-Date -Format yyyyMMdd-HHmmss)"
$csv = $out + '.csv'
Write-Host "Running Invoke-ScriptAnalyzer..."
$results = Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error,Warning,Information
$results | Select-Object Severity,RuleName,RuleId,ScriptName,Line,Message | Export-Csv -Path $csv -NoTypeInformation -Force
Write-Host "Saved report: $csv"
Write-Host "Total issues found: $($results.Count)"
# Summarize top rules
$summary = $results | Group-Object -Property RuleName | Sort-Object Count -Descending | Select-Object @{Name='RuleName';Expression={$_.Name}},@{Name='Count';Expression={$_.Count}} -First 20
Write-Host "Top rules:"; $summary | Format-Table -AutoSize
