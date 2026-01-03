# AI Development Toolkit

[![PortManager - Normalize & Tests](https://github.com/kmransom56/AI-Tools/actions/workflows/portmanager-tests.yml/badge.svg)](https://github.com/kmransom56/AI-Tools/actions/workflows/portmanager-tests.yml)

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
