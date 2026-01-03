#!/usr/bin/env bash
set -euo pipefail

# run-cagent-agent.sh — Safe wrapper to run cagent examples
# Defaults to a dry run: sets CAGENT_DRY_RUN=1 when running the docker image

show_usage() {
  cat <<'USAGE'
Usage: ./cagent/scripts/run-cagent-agent.sh <example.yaml> [--] [extra args...]

Runs a cagent example using local `cagent` CLI if available, otherwise runs the docker image
in a container (with the host docker socket mounted). By default the wrapper sets
CAGENT_DRY_RUN=1 to avoid performing any destructive actions.

Examples:
  ./cagent/scripts/run-cagent-agent.sh cagent/examples/tic-tac-toe.yaml
  ./cagent/scripts/run-cagent-agent.sh cagent/examples/rag/hybrid.yaml -- -c demo

To perform a real run, either edit the YAML to remove dry-run flags or run the CLI directly.
USAGE
}

if [ "$#" -lt 1 ]; then
  show_usage
  exit 1
fi

EXAMPLE="$1"
shift || true

# Prefer local CLI if available
if command -v cagent >/dev/null 2>&1; then
  echo "Using local cagent CLI (dry-run mode enforced by wrapper)."
  export CAGENT_DRY_RUN=1
  cagent run "$EXAMPLE" "$@"
  exit $?
fi

# Otherwise run via docker image (mount docker socket)
IMAGE="docker/cagent:latest"

echo "Running via Docker image: $IMAGE (dry-run mode enforced by wrapper)"
# mount current repo to /workspace and the docker socket
# CAGENT_DRY_RUN env var will be set inside container
docker run --rm -e CAGENT_DRY_RUN=1 -v /var/run/docker.sock:/var/run/docker.sock -v "$(pwd):/workspace" -w /workspace "$IMAGE" run "$EXAMPLE" "$@"