# AI Development Toolkit

[![PortManager - Normalize & Tests](https://github.com/kmransom56/AI-Tools/actions/workflows/portmanager-tests.yml/badge.svg)](https://github.com/kmransom56/AI-Tools/actions/workflows/portmanager-tests.yml)  
[![Docker Compose Validate](https://github.com/kmransom56/AI-Tools/actions/workflows/docker-compose-validate.yml/badge.svg)](https://github.com/kmransom56/AI-Tools/actions/workflows/docker-compose-validate.yml)

## Overview
This toolkit installs and configures multiple AI-powered development tools on Windows:
- Void (Open-source AI editor)
- TabbyML (Self-hosted AI assistant)
- Continue.dev (VS Code extension)
- Cursor IDE (AI-native IDE)
- GitHub Copilot
- OpenCode CLI
- ChatGPT CLI tools (Shell GPT, chatGPT-shell-cli, gpt-cli)

## Prerequisites
- Windows 10/11
- PowerShell (Run as Administrator)
- Docker Desktop installed
- Environment variables:
  - OPENAI_API_KEY
  - ANTHROPIC_API_KEY
  - GEMINI_API_KEY

## Installation
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\Install-AI-Tools.ps1
```

## Running on Windows ✅
For production/long-running deployments on Windows we recommend running the web service as a Windows service using **NSSM**. See `docs/RUNNING-WINDOWS.md` for a step-by-step guide and an installer script: `deploy/install-ai-toolkit-nssm.ps1`.

## Running locally (recommended)
- Copy `.env.example` to `.env` and fill in your API keys:
```powershell
Copy-Item .env.example .env
# Edit .env and add keys
notepad .env
```

- Example port suggestions (uncomment and set in `docker-compose.yml` if you want services exposed):
  - **ai-toolkit** (web UI / local API): `8000:8000` or `11500:11500` (local dev)
  - **tabbyml** (web UI): `3000:3000`

- To validate your compose file before building (CI also runs this):
```powershell
# Local validation
docker compose -f docker-compose.yml config
```

- To build and run:
```powershell
docker compose up --build
# or run detached
docker compose up --build -d
```

If you expose ports, ensure the mappings are set in `docker-compose.yml` (the file contains commented examples). The new CI job also validates `docker compose config` on PRs and pushes to `main` to catch these issues early.
