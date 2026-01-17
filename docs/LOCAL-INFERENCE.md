# Local Inference (PowerInfer & TurboSparse)

This project now supports local LLMs via HTTP (OpenAI-compatible) or CLI runners for PowerInfer and TurboSparse. No internet API keys are required when using local backends.

## Configuration (environment variables)

Set any of the following in `.env` (or your environment):

```
# PowerInfer HTTP
POWERINFER_HOST=http://localhost:11434
POWERINFER_MODEL=meta-llama-3-8b-q4

# PowerInfer CLI
POWERINFER_CLI=powerinfer --model "C:\\models\\llama3.gguf" --prompt "{prompt}" --n-predict 256
POWERINFER_MODEL=meta-llama-3-8b-q4

# TurboSparse HTTP
TURBOSPARSE_HOST=http://localhost:11435
TURBOSPARSE_MODEL=meta-llama-3-8b-q4

# TurboSparse CLI
TURBOSPARSE_CLI=turbosparse --model "C:\\models\\llama3.gguf" --prompt "{prompt}" --max-tokens 256
TURBOSPARSE_MODEL=meta-llama-3-8b-q4
```

Rules:
- HTTP takes priority if both HOST and MODEL are set; otherwise CLI is used if CLI + MODEL are set.
- `{prompt}` placeholder in CLI templates is mandatory and will be replaced with the user message.

## FastAPI behavior
- `/api/models` will list `powerinfer` and/or `turbosparse` when configured (HTTP or CLI).
- `/api/chat` will route to PowerInfer/TurboSparse when `model` is `powerinfer` or `turbosparse`.
- `/api/health` reports whether each local backend is configured (HTTP or CLI).

## Expected HTTP interface
- OpenAI-compatible chat completions endpoint.
- The code auto-normalizes the base URL to `/v1/chat/completions` if you pass just the host.
- Response should include `choices[0].message.content` or `choices[0].text`.

## CLI runner expectations
- Provide a full command template with `{prompt}` placeholder.
- Output is read from STDOUT; nonzero exit codes or STDERR cause an error.
- Timeout defaults: HTTP 30s, CLI 60s.

## Docker Compose scaffold (template)
Add to `docker-compose.yml` if you have container images:

```yaml
  powerinfer:
    image: <your-powerinfer-image>
    container_name: powerinfer
    environment:
      - MODEL_PATH=/models/llama3.gguf
    volumes:
      - C:/models:/models:ro
    ports:
      - "11434:11434"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11434/v1/models"]
      interval: 30s
      timeout: 5s
      retries: 5

  turbosparse:
    image: <your-turbosparse-image>
    container_name: turbosparse
    environment:
      - MODEL_PATH=/models/llama3.gguf
    volumes:
      - C:/models:/models:ro
    ports:
      - "11435:11435"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11435/v1/models"]
      interval: 30s
      timeout: 5s
      retries: 5
```

Set corresponding app env vars:
```
POWERINFER_HOST=http://localhost:11434
POWERINFER_MODEL=meta-llama-3-8b-q4
TURBOSPARSE_HOST=http://localhost:11435
TURBOSPARSE_MODEL=meta-llama-3-8b-q4
```

## Testing
- `GET /api/models` – verify `powerinfer` and/or `turbosparse` appear.
- `POST /api/chat` with `model: powerinfer` (or `turbosparse`).
- `GET /api/health` – check local backend flags.

## Troubleshooting
- 4xx/5xx from HTTP backends: the server’s response text is surfaced in the error.
- CLI fails: return code or stderr is returned as error; ensure `{prompt}` is in the template.
- Timeouts: increase timeout in code if needed (default 30s HTTP, 60s CLI).
