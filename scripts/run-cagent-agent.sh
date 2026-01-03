#!/usr/bin/env bash
set -euo pipefail

CONFIG=${1:-cagent/examples/golang_developer.yaml}
MODE=${2:---dry-run}
ARTDIR=artifacts
mkdir -p "$ARTDIR"
LOG="$ARTDIR/cagent-run-$(date -u +"%Y%m%dT%H%M%SZ").log"

echo "Running cagent with config: $CONFIG (mode: $MODE)"
if [ "$MODE" = "--live" ]; then
  docker run --rm -v "$PWD":/work -w /work docker/cagent:latest run "$CONFIG" 2>&1 | tee "$LOG" || true
else
  docker run --rm -v "$PWD":/work -w /work docker/cagent:latest run "$CONFIG" --dry-run 2>&1 | tee "$LOG" || true
fi

echo "Logs written to: $LOG"