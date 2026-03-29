#!/usr/bin/env bash
set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

LAB_DIR="$(cd "$(dirname "$0")" && pwd)"

echo -e "${BOLD}Setting up DevOps Lab...${NC}\n"

# Check Node.js
if ! command -v node &>/dev/null; then
  echo "Error: Node.js is required. Install it first."
  exit 1
fi

echo -e "  ${GREEN}✓${NC} Node.js $(node --version)"

# Check jq
if ! command -v jq &>/dev/null; then
  echo "  Installing jq..."
  sudo apt-get install -y jq >/dev/null 2>&1 || { echo "Error: Could not install jq. Install it manually."; exit 1; }
fi
echo -e "  ${GREEN}✓${NC} jq installed"

# Install npm dependencies
echo "  Installing dependencies..."
cd "$LAB_DIR" && npm install --silent
echo -e "  ${GREEN}✓${NC} npm dependencies installed"

# Download vendor libraries if missing
if [[ ! -f "$LAB_DIR/site/js/vendor/marked.min.js" ]]; then
  echo "  Downloading vendor libraries..."
  mkdir -p "$LAB_DIR/site/js/vendor" "$LAB_DIR/site/assets"
  curl -sL "https://cdn.jsdelivr.net/npm/marked@12.0.1/marked.min.js" -o "$LAB_DIR/site/js/vendor/marked.min.js"
  curl -sL "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/highlight.min.js" -o "$LAB_DIR/site/js/vendor/highlight.min.js"
  curl -sL "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/styles/github-dark.min.css" -o "$LAB_DIR/site/assets/highlight-github.css"
  echo -e "  ${GREEN}✓${NC} vendor libraries downloaded"
else
  echo -e "  ${GREEN}✓${NC} vendor libraries present"
fi

# Make lab-cli executable and create symlink
chmod +x "$LAB_DIR/lab-cli"
mkdir -p "$HOME/bin"
ln -sf "$LAB_DIR/lab-cli" "$HOME/bin/lab"
echo -e "  ${GREEN}✓${NC} lab CLI linked to ~/bin/lab"

# Initialize progress
if [[ ! -f "$LAB_DIR/progress.json" ]]; then
  echo '{"exercises":{},"started_at":null,"last_activity":null}' > "$LAB_DIR/progress.json"
fi

# Make all verify/reset scripts executable
find "$LAB_DIR/modules" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

echo -e "\n${GREEN}${BOLD}Setup complete!${NC}\n"
echo -e "Start the web server:  ${BLUE}lab start${NC}"
echo -e "                  or:  ${BLUE}cd $LAB_DIR && npm start${NC}"
echo -e "Then open:             ${BLUE}http://localhost:3333${NC}\n"
echo -e "CLI commands:          ${BLUE}lab help${NC}"
