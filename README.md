
# AI Development Toolkit

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

Important security notes:
- Do **not** commit `.env` files or any files containing live secrets. This repo includes a local pre-commit hook to help detect secrets; run `scripts\install-git-hooks.ps1` to enable it.
- A GitHub Action (`.github/workflows/secret-scan.yml`) runs Gitleaks on pushes and pull requests and will block PRs if secrets are detected.
- If you find exposed keys in your working tree, rotate them immediately and store the new keys in a secure secret store (GitHub Secrets for CI, your vault of choice for self-hosted runners).

## Installation
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\Install-AI-Tools.ps1
