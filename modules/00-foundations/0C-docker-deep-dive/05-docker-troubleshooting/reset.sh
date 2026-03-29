#!/usr/bin/env bash
set -euo pipefail

echo "Resetting: Exercise 0C-05 — Docker Troubleshooting"

WORK_DIR="/tmp/devops-lab/0C-05"

# Bring down any running compose stack
if [[ -f "$WORK_DIR/docker-compose.yml" ]]; then
  echo "  Bringing down compose stack..."
  docker compose -f "$WORK_DIR/docker-compose.yml" down -v 2>/dev/null || true
fi

# Clean up any leftover containers
docker ps -a --filter "name=0c-05" --format "{{.ID}}" | xargs -r docker rm -f 2>/dev/null || true

# Recreate work directory
echo "  Recreating broken exercise files..."
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR/api"

# Create the API entrypoint script that requires API_SECRET
cat > "$WORK_DIR/api/entrypoint.sh" << 'ENTRYEOF'
#!/bin/sh
set -e

if [ -z "$API_SECRET" ]; then
  echo "ERROR: Required environment variable API_SECRET is not set" >&2
  echo "Set API_SECRET in your docker-compose.yml environment section" >&2
  exit 1
fi

echo "API_SECRET is set, starting server..."
# Run a simple HTTP server as a stand-in for a real API
exec python3 -m http.server 8080
ENTRYEOF
chmod +x "$WORK_DIR/api/entrypoint.sh"

# Create a simple Dockerfile for the API service
cat > "$WORK_DIR/api/Dockerfile" << 'DFEOF'
FROM python:3.12-slim
WORKDIR /app
COPY entrypoint.sh .
ENTRYPOINT ["/app/entrypoint.sh"]
DFEOF

# Create the BROKEN docker-compose.yml
cat > "$WORK_DIR/docker-compose.yml" << 'COMPOSEEOF'
# This compose file has THREE deliberate bugs. Find and fix them all.
services:

  # Bug 1: The app listens on port 8080, but we're mapping host port 80.
  # Symptom: curl localhost:80 works but the verify script checks 8080.
  web:
    image: python:3.12-slim
    command: python -m http.server 8080
    ports:
      - "80:8080"
    networks:
      - app-net

  # Bug 2: The entrypoint script requires API_SECRET env var but it's missing.
  # Symptom: container exits immediately with an error message.
  api:
    build:
      context: ./api
    # environment:
    #   API_SECRET: ???    <-- this section is commented out / missing
    networks:
      - app-net

  # Bug 3: This image tag does not exist on Docker Hub.
  # Symptom: docker compose up fails to pull the image.
  db:
    image: postgres:99.0
    environment:
      POSTGRES_PASSWORD: secret
    networks:
      - app-net

networks:
  app-net:
COMPOSEEOF

echo "  Done. Broken compose setup ready at $WORK_DIR/"
echo ""
echo "  The setup has 3 bugs:"
echo "    1. web: wrong port mapping"
echo "    2. api: missing required environment variable"
echo "    3. db: non-existent image tag"
echo ""
echo "  Start with: cd $WORK_DIR && docker compose up -d"
echo "  Then diagnose and fix the issues."
