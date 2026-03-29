#!/usr/bin/env bash
set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

LAB_DIR="$(cd "$(dirname "$0")" && pwd)"

echo -e "${BOLD}Setting up DevOps Lab...${NC}\n"

# Install system packages (jq, curl, git)
echo "  Checking system packages..."
PKGS_NEEDED=""
command -v jq &>/dev/null || PKGS_NEEDED="$PKGS_NEEDED jq"
command -v curl &>/dev/null || PKGS_NEEDED="$PKGS_NEEDED curl"
command -v git &>/dev/null || PKGS_NEEDED="$PKGS_NEEDED git"
if [[ -n "$PKGS_NEEDED" ]]; then
  echo "  Installing:$PKGS_NEEDED"
  sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq >/dev/null 2>&1
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $PKGS_NEEDED >/dev/null 2>&1
fi
echo -e "  ${GREEN}✓${NC} System packages (jq, curl, git)"

# Install Node.js via nvm if not present
if ! command -v node &>/dev/null; then
  echo "  Installing Node.js via nvm..."
  export NVM_DIR="$HOME/.nvm"
  if [[ ! -d "$NVM_DIR" ]]; then
    NVM_SCRIPT=$(mktemp)
    curl -o "$NVM_SCRIPT" https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh
    bash "$NVM_SCRIPT"
    rm -f "$NVM_SCRIPT"
  fi
  # Load nvm
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  nvm install 22 >/dev/null 2>&1
  nvm use 22 >/dev/null 2>&1
fi
# Ensure nvm is loaded (for existing installs)
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
echo -e "  ${GREEN}✓${NC} Node.js $(node --version)"

# Install Docker if not present
if ! command -v docker &>/dev/null; then
  echo "  Installing Docker..."
  DOCKER_SCRIPT=$(mktemp)
  curl -fsSL https://get.docker.com -o "$DOCKER_SCRIPT"
  sh "$DOCKER_SCRIPT" >/dev/null 2>&1
  rm -f "$DOCKER_SCRIPT"
  sudo usermod -aG docker "$USER" 2>/dev/null || true
  echo -e "  ${GREEN}✓${NC} Docker installed (log out and back in for group permissions)"
else
  echo -e "  ${GREEN}✓${NC} Docker $(docker --version | awk '{print $3}' | tr -d ',')"
fi

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

# Ensure ~/bin is in PATH
if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
fi
export PATH="$HOME/bin:$PATH"

# Initialize progress
if [[ ! -f "$LAB_DIR/progress.json" ]]; then
  echo '{"exercises":{},"started_at":null,"last_activity":null}' > "$LAB_DIR/progress.json"
fi

# Make all verify/reset scripts executable
find "$LAB_DIR/modules" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

echo -e "\n${GREEN}${BOLD}Setup complete!${NC}\n"
echo -e "Run this to activate the lab CLI in your current shell:\n"
echo -e "  ${BLUE}source ~/.bashrc${NC}\n"
echo -e "Then start the web server:\n"
echo -e "  ${BLUE}lab start${NC}\n"
echo -e "Open:  ${BLUE}http://localhost:3333${NC}"
echo -e "CLI:   ${BLUE}lab help${NC}"
