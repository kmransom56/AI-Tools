# BUILDING — AI Development Toolkit

This document contains platform-specific build and run instructions for the AI Development Toolkit. It's a Windows-first guide but includes Docker and local development instructions that are cross-platform.

## 🔧 Build & Run (Windows-first)
Follow these steps to get the application running locally using Docker or directly for development.

### 1) Setup & Prerequisites
- Install required system tools:
  - **Chocolatey** (optional but recommended on Windows)
  - **Docker Desktop** (ensure WSL2 backend enabled on Windows)
  - **Git**
  - **Python 3.11** (for local dev outside Docker)
- Copy environment template:

```powershell
# create a local .env from template and edit
copy .\env.template .env
# or set variables per session
$env:OPENAI_API_KEY = "sk-..."
```
- Run the installer (optional):

```powershell
# Starts installer steps (may prompt for Admin privileges)
.\AI-Toolkit-Auto.ps1
```

### 2) Run with Docker (recommended for most users)
- Build and start containers:

```powershell
docker compose up --build
# or for detached
docker compose up -d --build
```

- Watch logs for the `ai-toolkit` service:

```bash
docker compose logs -f ai-toolkit
```

- The web UI / API is available at http://localhost:8000 by default. For local development without Docker:

```bash
uvicorn ai_web_app:app --reload --port 8000
```

### 3) Run & Test cagent Examples (safety-first)
- Examples are in `cagent/examples/` and many expect environment variables and optional services.
- Use the provided wrappers which set `CAGENT_DRY_RUN=1` by default:
  - POSIX: `cagent/scripts/run-cagent-agent.sh`
  - PowerShell: `cagent/scripts/run-cagent-agent.ps1`
- To run a single example in dry-run:

```bash
# example (dry-run by default when using wrappers)
./cagent/scripts/run-cagent-agent.sh cagent/examples/rag/bm25.yaml
```

- To enable full runs (only after review): remove `CAGENT_DRY_RUN` or set it to `0` and ensure you reviewed the example, env vars, and `max_iterations`.
- **Important:** CI enforces `max_iterations <= 10` and warns/errors if `dry_run` is missing; adjust examples accordingly before enabling full runs.

### 4) CI & Validation
- The repo contains `.github/workflows/cagent-examples-validate.yml` which:
  - Lints YAMLs
  - Ensures `dry_run: true` or presence of `CAGENT_DRY_RUN` in wrappers
  - Enforces `max_iterations <= 10`
- To trigger validation manually, use the Actions UI or push a small commit to an examples branch; check logs for failing files and fix missing `dry_run` or large iteration counts.

### 5) Developer Workflow & Tests
- Run linters and quick checks locally before opening PRs:
  - YAML linting (your preferred linter / `yamllint`)
  - Run the examples-validation script (if present) locally or replicate GitHub Actions steps
- Add new examples to `cagent/examples/` and include metadata (example header, `dry_run`, recommended `max_iterations`).

## 🛠️ Troubleshooting
- SSH permission / `git push` errors:

```powershell
# Generate an Ed25519 SSH key and print the public key (replace email):
ssh-keygen -t ed25519 -C "kmransom52@gmail.com"
# Show the public key so you can copy it to GitHub
type $env:USERPROFILE\.ssh\id_ed25519.pub
# Test SSH auth
ssh -T git@github.com
```

- If you prefer HTTPS for one-off pushes:

```bash
git push https://github.com/kmransom56/AI-Tools.git --delete docs/readme-checklist-20260103
```

- Docker socket errors & risks: avoid mounting `/var/run/docker.sock` for untrusted examples; use a disposable VM or CI runner.
- Admin permissions on Windows: some installer steps require Administrator privileges (Chocolatey, NSSM service registration).
