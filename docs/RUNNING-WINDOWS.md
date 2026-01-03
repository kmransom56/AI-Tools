# Running AI Toolkit on Windows

This document describes how to run the AI Toolkit web service on **Windows** as a service using **NSSM** (Non-Sucking Service Manager).

## Recommendation
- Use NSSM to register the Python/uvicorn process as a Windows service. This provides simple management (start/stop), automatic restarts, and log redirection.

## Install & run (Administrator PowerShell)
1. Copy repository files to a directory (example: `C:\opt\ai-toolkit`).
2. Ensure Python is installed and your application dependencies are installed (e.g., `pip install -r requirements.txt`).
3. Copy `.env.example` to `.env` and fill your API keys.
4. Run the installer script (this will install NSSM if missing and create the service):

```powershell
# Run in an elevated PowerShell prompt
cd path\to\AI-Tools\deploy
.\install-ai-toolkit-nssm.ps1 -Action install -InstallDir 'C:\opt\ai-toolkit' -ServiceName 'ai-toolkit' -Port 11500
```

- The script will try to install NSSM via Chocolatey if available, otherwise it will download and extract NSSM to `C:\tools\nssm`.
- If the primary release download (from `https://nssm.cc/release/`) fails, the installer will fall back to the Git mirror at `https://git.nssm.cc/nssm/nssm` as an alternate download source.
- Logs are written to `C:\opt\ai-toolkit\logs\stdout.log` and `stderr.log`.

## Uninstall
```powershell
.\install-ai-toolkit-nssm.ps1 -Action uninstall -ServiceName 'ai-toolkit'
```

## Notes
- The service runs the app via `python -m uvicorn ai_web_app:app --host 0.0.0.0 --port 11500` by default. Adjust the `-Port` parameter or pass `-PythonExe` if needed.
- For development, you can still use `docker compose up --build` and expose ports (see `docker-compose.yml` comments).
