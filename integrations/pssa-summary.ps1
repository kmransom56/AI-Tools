$report = (Get-ChildItem -Path 'C:\Users\south\AI-Tools\backups' -Filter 'psscriptanalyzer-report-*.csv' | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
Write-Host "Report file: $report"
$data = Import-Csv -Path $report
Write-Host "Issue counts by severity:"
$data | Group-Object -Property Severity | Select-Object Name, Count | Format-Table -AutoSize
Write-Host "`nTop files with most issues:"
$data | Group-Object -Property ScriptName | Where-Object { $_.Name -and $_.Name -ne '' } | Sort-Object Count -Descending | Select-Object @{Name='ScriptName';Expression={$_.Name}},@{Name='Count';Expression={$_.Count}} -First 20 | Format-Table -AutoSize
