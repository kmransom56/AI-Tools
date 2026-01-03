# cagent examples — Run & dogfood instructions

✅ **Purpose:** Provide an easy, safe way to run the imported `cagent` examples locally for dogfooding and validation.

## Prerequisites
- Docker (desktop or engine) running and accessible from this machine.
- (Optional) `cagent` CLI installed locally (if so, wrappers will use local CLI first).

## Safety defaults
- Examples default to *dry-run* behavior where possible. Always review the YAML before running non-dry runs.
- Many examples are multi-agent, use external tools, or require a Docker socket. Run them in a safe environment.

## Run wrappers
- `cagent/scripts/run-cagent-agent.sh` — minimal POSIX shell wrapper that runs an example in a container (dry-run by default)
- `cagent/scripts/run-cagent-agent.ps1` — Windows PowerShell wrapper (dry-run by default)

Example usage (from repo root):

```bash
# Run an example in dry-run mode (default):
./cagent/scripts/run-cagent-agent.sh cagent/examples/tic-tac-toe.yaml

# Use the CLI directly if you have it installed (also defaults to dry-run):
# cagent run --dry-run cagent/examples/rag/hybrid.yaml
```

## Examples included
A curated subset of the upstream cagent examples has been imported under `cagent/examples/` (RAG, professional writing, demos, diagnostics, developer helpers, and more). See the directory for individual YAML files and usage notes.

## Notes
- Some examples require mounting the Docker socket or extra environment variables. See the example YAML for `toolsets` and `env` placeholders.
- If you want me to add extra example categories, or a Makefile / GitHub Actions job to run a safe dry-run matrix, tell me which examples to prioritize.

---
Imported from: https://github.com/docker/cagent/tree/main/examples
