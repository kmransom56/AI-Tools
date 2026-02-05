# Self-hosted GPU workflow (vLLM smoke test)

This repository includes a workflow to perform a GPU smoke test for the vLLM model runner. Because hosted GitHub Actions runners do not provide NVIDIA GPUs, this workflow is intended for self-hosted runners that have GPU access.

Key points:

- Runner labels: the workflow targets runners with labels `self-hosted,gpu,nvidia`.
- Manual dispatch: the workflow is designed to be triggered manually (workflow_dispatch) to avoid unexpected runs.
- Safety: **Do not** enable model downloads on hosted runners. The workflow should rely on models pre-fetched on the self-hosted runner or use small, test-friendly models that are allowed in your environment.

How to run:

1. Ensure a self-hosted runner is registered with labels: `self-hosted,gpu,nvidia`.
2. Copy the example environment file to `.env` on the runner and set values (including `VLLM_API_KEY` and `VLLM_LOCAL_MODELS_DIR` if using local models):

```bash
cp powershell-signer/vllm_config.env.example powershell-signer/.env
# edit .env as needed (VLLM_API_KEY, VLLM_MODEL_NAME, VLLM_LOCAL_MODELS_DIR)
```

3. (Optional) Prefetch models on the runner using the included helper script:

```powershell
powershell -ExecutionPolicy Bypass -File powershell-signer/scripts/fetch-vllm-model.ps1 -ModelName "gpt2"
```

4. Trigger the workflow via the Actions UI and monitor the run on the self-hosted runner.

Security: ensure that any tokens (HUGGINGFACE_TOKEN, VLLM_API_KEY) are stored securely and not leaked in logs.
