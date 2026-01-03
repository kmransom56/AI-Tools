# AI Development Toolkit

Complete AI development environment with Docker-based tools and IDE integrations.

## 🎯 Objective
Provide a concise, Windows-first, Docker-based AI development toolkit that bundles model clients, common AI libraries, helper scripts, and IDE integrations so developers can quickly bootstrap, run, test, and dogfood AI workloads locally.

## ⚖️ Scope & Limitations
- **Windows-first**: primary workflows and scripts target Windows (PowerShell, NSSM, Chocolatey), but Docker-based components are cross-platform.
- **Not a production runtime**: the toolkit is designed for development, testing, and experimentation — not for deploying production services.
- **Installer constraints**: some installer steps (Chocolatey, NSSM) require Administrator privileges.
- **API keys required**: OpenAI, Anthropic, and Google credentials must be provided via environment variables or a `.env` file.
- **Port & resource conventions**: recommended port range for tools is 11000–12000; some components may require large memory/CPU resources.
- **Security implications**: some examples mount the Docker socket or access system-level tools — review and run in an isolated environment.

## 🔐 Security & Windows notes
- **Don’t commit secrets** (API keys, PFX files). Use environment variables, `.env` files excluded by `.gitignore`, or a secret manager.
- **Docker socket risks**: mounting `/var/run/docker.sock` gives container processes root-level access to the Docker host; only run untrusted examples in isolated VMs or CI runners.
- **Run examples in dry-run mode** (where available) before enabling full runs. Many imported examples default to `dry_run` or small `max_iterations` in CI validation.
- **Windows-specific steps**: the installer may need Admin privileges to modify PATH, install services with NSSM, or edit system services — test in a VM if unsure.

## ✅ Before you run examples (checklist)
Follow these short safety checks before running any imported cagent examples or other community-provided workflows:

1. **Confirm API keys** — ensure required keys (OpenAI, Anthropic, Gemini) are set via environment variables or a local `.env` (do not commit them).
2. **Start in dry-run** — prefer running examples with `dry_run: true` or using the provided wrappers (`cagent/scripts/run-cagent-agent.sh` / `run-cagent-agent.ps1`).
3. **Verify `CAGENT_DRY_RUN`** — if using wrappers, confirm `CAGENT_DRY_RUN=1` (POSIX) or the PowerShell wrapper sets it by default.
4. **Check `max_iterations`** — avoid large or unbounded iteration counts; CI enforces `max_iterations <= 10` by default.
5. **Avoid Docker socket for untrusted examples** — do not mount `/var/run/docker.sock` unless you trust the example; use a VM or ephemeral runner for risky runs.
6. **Run in isolation** — use a disposable VM, container, or CI runner when running examples that access system resources.
7. **Read `ORIGIN.md` & example header** — review the original source and any notes in `cagent/examples/ORIGIN.md` and each example's header for required env vars or caveats.
8. **Iterate cautiously** — start with minimal settings and inspect logs and outputs before increasing scale or enabling persistent side effects.

> **Tip:** We recommend always testing examples locally with `dry_run` and in an isolated environment before allowing any example to interact with your Docker host or cloud credentials.

## 🔧 Build & Run
Full build & run instructions have moved to a dedicated document:

- See `docs/BUILDING.md` for setup, Docker usage, cagent examples guidance, CI validation, developer workflow, and troubleshooting.

## 🚀 Quick Start

```powershell
# Run the automated installer
.\AI-Toolkit-Auto.ps1

# Use the AI helper script
.\ai.ps1 help
```

## 📦 What's Included

### Docker Container (ai-toolkit)
- **Python 3.11** with comprehensive AI/ML stack
- **OpenAI API** client
- **Anthropic Claude** API client
- **Google Gemini** API client
- **PyTorch 2.4.0** (CPU version)
- **Transformers 4.44.0** (Hugging Face)
- **LangChain** with OpenAI/Anthropic integrations
- **shell-gpt** (sgpt) CLI
- **chatgpt-cli** for terminal interactions

### IDE Tools
- **VS Code** with Continue and GitHub Copilot extensions
- **Cursor IDE** with AI assistance
- **Void Editor** (optional)

## 🔧 Usage

... (rest of file unchanged)