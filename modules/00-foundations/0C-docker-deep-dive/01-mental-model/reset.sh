#!/usr/bin/env bash
set -euo pipefail

echo "Resetting: Exercise 0C-01 — Docker Mental Model"

# Stop and remove the lab-test container if it exists
if docker inspect lab-test &>/dev/null; then
  echo "  Stopping and removing lab-test container..."
  docker stop lab-test 2>/dev/null || true
  docker rm lab-test 2>/dev/null || true
fi

# Remove any exited alpine containers created during the exercise
echo "  Removing exited alpine containers..."
docker ps -a --filter ancestor=alpine:latest --filter status=exited --format "{{.ID}}" \
  | xargs -r docker rm 2>/dev/null || true

# Clean work directory
echo "  Cleaning work directory..."
rm -rf /tmp/devops-lab/0C-01
mkdir -p /tmp/devops-lab/0C-01

echo "  Done. Work directory reset to /tmp/devops-lab/0C-01/"
