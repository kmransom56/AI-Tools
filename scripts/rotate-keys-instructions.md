# Rotate exposed API keys (instructions)

This doc contains instructions to rotate the exposed keys found in your working tree. Rotating keys requires actions on each provider's website or console. After rotation, use the `scripts/update-secrets-in-runner.ps1` helper to update local `.env` files and back them up.

## Providers

### OpenAI
1. Go to https://platform.openai.com/account/api-keys
2. Revoke the existing key and create a new key.
3. Copy the new key and store it in a secure vault.

### Anthropic
1. Go to your Anthropic account dashboard and generate a new API key.
2. Revoke the old key if desired.

### Google (Gemini / API keys)
1. Visit Google Cloud Console -> APIs & Services -> Credentials.
2. Create a new API key or rotate as per your org policy.

### Docker Hub (Personal Access Token)
1. Go to https://hub.docker.com/settings/security
2. Revoke the existing PAT and create a new one.

## Update local runner and CI

- For self-hosted runners: store secrets in your vault and write them into the runner's `.env` (e.g., `powershell-signer/.env`) only on the runner using `scripts/update-secrets-in-runner.ps1`.
- For CI (GitHub Actions), create/update repository secrets: `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, `VLLM_API_KEY`, `DOCKER_PASSWORD`.

## Using the helper script

Run `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/update-secrets-in-runner.ps1 -OpenAI '<key>' -Anthropic '<key>' -Gemini '<key>' -Docker '<pat>' -Vllm '<token>'` on the runner or your local machine to update `.env` files in place (backups will be created automatically).

**Important**: Do not commit `.env` files with live secrets to git. Use secure storage and GitHub Secrets for CI.
