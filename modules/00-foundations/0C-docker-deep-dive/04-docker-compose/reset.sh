#!/usr/bin/env bash
set -euo pipefail

echo "Resetting: Exercise 0C-04 — Docker Compose"

WORK_DIR="/tmp/devops-lab/0C-04"

# Bring down compose stack if running
if [[ -f "$WORK_DIR/docker-compose.yml" ]]; then
  echo "  Bringing down compose stack..."
  docker compose -f "$WORK_DIR/docker-compose.yml" down -v 2>/dev/null || true
fi

# Clean up any leftover containers from previous runs
docker ps -a --filter "name=0c-04" --format "{{.ID}}" | xargs -r docker rm -f 2>/dev/null || true

# Clean work directory
echo "  Cleaning work directory..."
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

echo "  Done. Work directory reset to $WORK_DIR/"
echo "  Your task: create $WORK_DIR/docker-compose.yml"
