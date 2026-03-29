#!/usr/bin/env bash
set -euo pipefail

echo "Resetting: Exercise 0C-03 — Docker Networking"

# Remove containers
for name in net-ping net-pong; do
  if docker inspect "$name" &>/dev/null; then
    echo "  Removing container: $name"
    docker stop "$name" 2>/dev/null || true
    docker rm "$name" 2>/dev/null || true
  fi
done

# Remove network
if docker network inspect lab-net &>/dev/null; then
  echo "  Removing network: lab-net"
  docker network rm lab-net 2>/dev/null || true
fi

# Clean work directory
echo "  Cleaning work directory..."
rm -rf /tmp/devops-lab/0C-03
mkdir -p /tmp/devops-lab/0C-03

echo "  Done. Work directory reset to /tmp/devops-lab/0C-03/"
