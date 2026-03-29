#!/usr/bin/env bash
set -euo pipefail

echo "Resetting: Exercise 0C-02 — Dockerfile From Scratch"

# Stop and remove the container
if docker inspect lab-flask-app &>/dev/null; then
  echo "  Stopping and removing lab-flask-app container..."
  docker stop lab-flask-app 2>/dev/null || true
  docker rm lab-flask-app 2>/dev/null || true
fi

# Remove the image
if docker images lab-flask:latest --format "{{.ID}}" | grep -q .; then
  echo "  Removing lab-flask:latest image..."
  docker rmi lab-flask:latest 2>/dev/null || true
fi

# Recreate the work directory and app files
echo "  Recreating app files..."
rm -rf /tmp/devops-lab/0C-02
mkdir -p /tmp/devops-lab/0C-02/app

cat > /tmp/devops-lab/0C-02/app/app.py << 'PYEOF'
from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello, DevOps!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
PYEOF

cat > /tmp/devops-lab/0C-02/app/requirements.txt << 'EOF'
flask
EOF

echo "  Done. App files ready at /tmp/devops-lab/0C-02/app/"
echo "  Files created:"
echo "    /tmp/devops-lab/0C-02/app/app.py"
echo "    /tmp/devops-lab/0C-02/app/requirements.txt"
echo "  Your task: create /tmp/devops-lab/0C-02/app/Dockerfile"
