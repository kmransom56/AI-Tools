function Invoke-ToolAgent {
    <#
    .SYNOPSIS
        Wrapper around cagent agents for the AI‑Tools suite.
    .DESCRIPTION
        Calls the PowerShell helper `invoke_cagent.ps1` located in the `cagent_examples` folder.
        Allows other scripts (e.g., PortManager) to run any cagent agent and receive its output.
    .PARAMETER AgentFile
        Relative path to the agent YAML file inside `cagent_examples`.
    .PARAMETER Input
        Optional input string passed to the agent.
    .EXAMPLE
        Invoke-ToolAgent -AgentFile 'agent.yaml' -Input 'Hello world'
    #>
    param(
        [Parameter(Mandatory = $true)][string]$AgentFile,
        [string]$Input
    )
    $scriptPath = Join-Path $PSScriptRoot 'cagent_examples\invoke_cagent.ps1'
    if (-not (Test-Path $scriptPath)) {
        Write-Error "cagent helper script not found at $scriptPath"
        return
    }
    . $scriptPath   # dot‑source to load the function
    Invoke-CagentAgent -AgentFile $AgentFile -Input $Input
}

Export-ModuleMember -Function Invoke-ToolAgent
function Invoke-UIAgent {
    <#
    .SYNOPSIS
        High‑level wrapper intended for UI front‑ends.
    .DESCRIPTION
        Accepts a JSON payload from a UI component, extracts the `agent` and optional `input`
        fields, and forwards the request to `Invoke-ToolAgent`. Returns the raw output string
        which can be sent back to the UI.
    .PARAMETER Payload
        JSON string with keys `agent` (e.g., 'filesystem-agent.yaml') and optional `input`.
    .EXAMPLE
        $json = '{"agent":"filesystem-agent.yaml","input":"List files in C:\\temp"}'
        Invoke-UIAgent -Payload $json
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Payload
    )
    try {
        $obj = $Payload | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-Error "Invalid JSON payload: $_"
        return
    }
    $agentFile = $obj.agent
    $input = $obj.input
    Invoke-ToolAgent -AgentFile $agentFile -Input $input
}

Export-ModuleMember -Function Invoke-ToolAgent, Invoke-UIAgent
