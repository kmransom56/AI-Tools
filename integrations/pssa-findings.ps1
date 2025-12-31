$report = (Get-ChildItem -Path 'C:\Users\south\AI-Tools\backups' -Filter 'psscriptanalyzer-report-*.csv' | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
$data = Import-Csv -Path $report
$topRules = $data | Group-Object -Property RuleName | Sort-Object Count -Descending | Select-Object -First 10
Write-Host "Top rules (name -> count):"; $topRules | Format-Table -AutoSize
$rulesToInspect = @('PSAvoidUsingInvokeExpression','PSAvoidUsingEmptyCatchBlock','PSAvoidUsingPositionalParameters','PSAvoidUsingCmdletAliases','PSAvoidUsingWriteHost')
foreach ($r in $rulesToInspect) {
    $items = $data | Where-Object { $_.RuleName -eq $r }
    if ($items.Count -gt 0) {
        Write-Host "`nRule: $r (count: $($items.Count)) - top files:`n"
        $items | Group-Object -Property ScriptName | Sort-Object Count -Descending | Select-Object @{Name='ScriptName';Expression={$_.Name}},@{Name='Count';Expression={$_.Count}} -First 10 | Format-Table -AutoSize
    }
}
# Save a short JSON with top 20 rules and top 20 files
$summary = [PSCustomObject]@{
    Report = $report
    TopRules = $topRules | Select-Object @{Name='RuleName';Expression={$_.Name}},@{Name='Count';Expression={$_.Count}}
    TopFiles = ($data | Group-Object -Property ScriptName | Sort-Object Count -Descending | Select-Object @{Name='ScriptName';Expression={$_.Name}},@{Name='Count';Expression={$_.Count}} -First 20)
}
$summary | ConvertTo-Json -Depth 5 | Out-File -FilePath 'C:\Users\south\AI-Tools\backups\pssa-summary.json' -Force
Write-Host "Saved summary to C:\Users\south\AI-Tools\backups\pssa-summary.json"