# cagent (docker/cagent) Integration

This document describes how to run Docker's `cagent` alongside AI-Tools for local development and lightweight monitoring.

## Quick start (local)
- Start AI-Tools with `cagent` enabled:
  ```bash
  docker compose -f docker-compose.yml -f docker-compose.cagent.yml up -d --build
  ```
- Verify cagent is healthy:
  ```bash
  docker compose -f docker-compose.yml -f docker-compose.cagent.yml ps
  docker compose -f docker-compose.yml -f docker-compose.cagent.yml logs -f cagent
  ```

## Configuration
- Add the following to your `.env` (copy from `env.template`):
  - `CAGENT_BACKEND_URL` — optional backend URL (leave blank for local-only)
  - `CAGENT_TOKEN` — secret token used to authenticate with backend (do not commit)

## Security notes
- cagent requires read access to the Docker socket (`/var/run/docker.sock`) to inspect containers. This gives the container broad visibility into the host and should only be used in trusted environments.
- Prefer running cagent only in development or in controlled CI boxes. For production, use a secure deployment method and short-lived tokens.

## Troubleshooting
- If healthcheck fails, check `docker compose logs cagent` and ensure the Docker socket is accessible by the container.
- If you need custom configuration, mount `./cagent/config` into the container and follow upstream docs to configure settings.
