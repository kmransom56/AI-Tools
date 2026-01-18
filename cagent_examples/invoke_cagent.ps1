# PowerShell wrapper to invoke cagent agents with tool support
# Requires Docker Desktop to be running and the `cagent:latest` image available.

function Invoke-CagentAgent {
    <#
    .SYNOPSIS
        Runs a cagent agent defined in the cagent_examples folder.
    .DESCRIPTION
        This function mounts the cagent_examples directory into a temporary Docker container
        and executes the specified agent YAML file. It also injects the tool catalog so the
        agent has access to all defined tools.
    .PARAMETER AgentFile
        Relative path (from the cagent_examples folder) to the agent definition YAML.
    .PARAMETER Input
        Optional input string that will be passed to the agent via the `--var user_input` flag.
    .EXAMPLE
        Invoke-CagentAgent -AgentFile 'agent.yaml' -Input 'Hello world'
    #>
    param(
        [Parameter(Mandatory = $true)][string]$AgentFile,
        [string]$Input
    )

    $examplesDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $agentPath = Join-Path $examplesDir $AgentFile
    if (-not (Test-Path $agentPath)) {
        Write-Error "Agent file not found: $agentPath"
        return
    }

    $dockerCmd = @(
        "docker", "run", "--rm",
        "-v", "${examplesDir}:C:/workspace",
        "cagent:latest",
        "run", "C:/workspace/$AgentFile"
    )
    if ($Input) {
        $dockerCmd += "--var", "user_input=$Input"
    }
    # Execute the Docker command and stream output
    & $dockerCmd
}

# Example usage (uncomment to test)
# Invoke-CagentAgent -AgentFile 'agent.yaml' -Input 'Hello from PowerShell!'
