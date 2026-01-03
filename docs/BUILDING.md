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

### Quick launcher scripts
- `Launch-AI-Tools-NoAdmin.ps1` — use this when you already have Docker, Git, Python, and other prerequisites installed. The script checks Docker/Docker daemon, attempts to start or create containers (chooses `docker compose` or `docker-compose` as available), and can optionally launch editors like Cursor or Void. No admin permissions are required to run this script.

- `Run-As-Admin.ps1` — wrapper that requests elevation and runs `AI-Toolkit-Auto.ps1`. Use this to perform a full install (Chocolatey + required packages) or when you want the installer to configure system-level components.

Notes:
- If the launcher reports "Docker Compose client not found", ensure you have either Docker Compose v2 (the `docker compose` subcommand) or the `docker-compose` binary installed.
- Launcher scripts attempt to be safe and will check for required components before performing operations; review their output/logs under `%USERPROFILE%\AI-Tools`.

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

... (rest unchanged)
