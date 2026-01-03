# BUILDING — AI Development Toolkit

This document contains platform-specific build and run instructions for the AI Development Toolkit. It's a Windows-first guide but includes Docker and local development instructions that are cross-platform.

## 🔧 Build & Run (Windows-first)
Follow these steps to get the application running locally using Docker or directly for development.

### cagent Web UI integration
We've added an optional integration that lets you browse and run `cagent` examples directly from the web UI (`/`):

- The UI lists examples detected under `cagent/examples/` in the repository.
- Examples are executed by the server using the `docker/cagent:latest` image, and **dry-run mode is enforced by default**.

### Enabling the integration (what changed)
To allow in-UI runs, the `ai-toolkit` service must be able to create containers (the cagent image will create or interact with other containers when executing examples):

1. Mount the Docker socket into the `ai-toolkit` container (this allows the app to control Docker on the host):

```yaml
services:
  ai-toolkit:
    volumes:
      - ./:/workspace:rw
      - /var/run/docker.sock:/var/run/docker.sock
```

2. The Docker image now includes the Python `docker` SDK so the FastAPI app can create/run cagent containers programmatically.

### Security notes (read before enabling) ⚠️
- **Mounting `/var/run/docker.sock` is high risk**: containers with socket access can escalate privileges and control host containers. Only enable this on trusted machines or disposable VMs.
- UI-triggered runs enforce `CAGENT_DRY_RUN=1` and reject attempts to disable it via the UI. They also reject `max_iterations > 10`.
- If you want to allow full runs (not recommended), restrict access to the web UI (vpn / dev machine) and review examples carefully.

---

(remaining content unchanged)
