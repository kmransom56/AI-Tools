# cagent — Dogfooding & examples

This directory contains examples and helper scripts to run cagent agents locally against the AI-Tools repository for dogfooding, experiments, and development.

Quick start
1. Copy env.template to .env and fill in API keys if you plan to use cloud providers:
```powershell
Copy-Item env.template .env
notepad .env
```

2. Run the Golang developer agent in dry-run mode (does not automatically commit):
```bash
./scripts/run-cagent-agent.sh cagent/examples/golang_developer.yaml
# or PowerShell
./scripts/run-cagent-agent.ps1 cagent/examples/golang_developer.yaml
```

3. Inspect `artifacts/` for agent logs and proposed patches. If acceptable, rerun with `--live` after carefully reviewing the security checklist.

Safety & best practices
- Default examples run in `dry_run: true` mode; this prevents automatic commits or PR creation.
- Do not store production API keys or GitHub tokens in `.env` when experimenting. Use short-lived tokens and Vault where possible.
- Prefer to run agents on an isolated development machine or dedicated CI runner.

Contributing
- Add more curated agent examples under `cagent/examples/` (Basic / Advanced / Multi-agent)
- Use `scripts/run-cagent-agent.*` wrappers for consistency and artifact capture

If you want me to add more examples (RAG-enabled agent, DMR-based local-model agent, or a multi-agent review pipeline), I can add them next.