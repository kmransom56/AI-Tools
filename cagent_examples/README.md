# cagent_examples

This folder contains ready‑to‑run **cagent** examples that demonstrate how to use the `cagent:latest` Docker image.

## Files

| File               | Purpose                                                      |
| ------------------ | ------------------------------------------------------------ |
| `agent.yaml`       | Simple single‑agent that greets the user.                    |
| `planner.yaml`     | Planner agent used in the multi‑agent workflow.              |
| `executor.yaml`    | Echo executor agent used by the workflow.                    |
| `workflow.yaml`    | Chains the planner and executor together.                    |
| `run_examples.ps1` | PowerShell helper script that runs the examples with Docker. |

## How to run the examples

1. **Prerequisites** – Docker Desktop must be installed and running.
2. Open a PowerShell terminal in the `cagent_examples` directory:
   ```powershell
   cd "C:\Users\Keith Ransom\AI-Tools\cagent_examples"
   .\run_examples.ps1
   ```
3. The script will:
   - Show a dry‑run of the single‑agent example.
   - Execute the multi‑agent workflow with a sample input.
   - Print the outputs to the console.

Feel free to edit the YAML files to try different models, instructions, or tools.
