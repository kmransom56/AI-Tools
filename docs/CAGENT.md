# cagent (docker/cagent) Integration

This document describes how to run Docker's `cagent` alongside AI-Tools for local development and lightweight monitoring, and how to dogfood with agent examples.

## Quick start (local)
- Start AI-Tools with `cagent` enabled (if inlined):
  ```bash
  docker compose up -d --build
  ```
  or, if you prefer the fragment file:
  ```bash
  docker compose -f docker-compose.yml -f docker-compose.cagent.yml up -d --build
  ```
- Verify cagent is healthy:
  ```bash
  docker compose ps
  docker compose logs -f cagent
  ```

## Dogfooding (run agents that work on the codebase)
- Example: run the Golang developer agent in dry-run mode (does not auto-commit):
  ```bash
  ./scripts/run-cagent-agent.sh cagent/examples/golang_developer.yaml
  # or for PowerShell
  ./scripts/run-cagent-agent.ps1 cagent/examples/golang_developer.yaml
  ```
- Artifacts and logs are written to `artifacts/` for review. If the agent proposes a patch, review it manually before running in live mode.

## CI: manual dogfood workflow
- There's a `workflow_dispatch` GitHub Action in `.github/workflows/cagent-dogfood.yml` for manual runs on a runner with Docker socket.
- The workflow runs the configured agent in `--dry-run` by default and uploads logs as an artifact.

## Configuration
- Add the following to your `.env` (copy from `env.template`):
  - `CAGENT_BACKEND_URL` — optional backend URL (leave blank for local-only)
  - `CAGENT_TOKEN` — secret token used to authenticate with backend (do not commit)

## Safety & Security notes
- cagent requires read access to `/var/run/docker.sock` — only enable in trusted environments.
- Agents default to `dry_run: true` and limited iterations in examples. Do not provide production GitHub tokens to agent runs unless you trust the runner.
- Prefer manual code review and human initiation for `--live` runs that can modify repository content.

## Troubleshooting
- If healthcheck fails, check `docker compose logs cagent` and confirm the Docker socket is accessible by the container.
- If the agent fails to start in CI, ensure the runner has Docker socket access; the workflow will skip if it does not.
