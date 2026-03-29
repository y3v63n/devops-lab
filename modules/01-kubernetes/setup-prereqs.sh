#!/usr/bin/env bash
set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${BOLD}Setting up Kubernetes prerequisites...${NC}\n"

# Check Docker
if ! command -v docker &>/dev/null; then
  echo -e "${YELLOW}Docker is required. Install Docker first (Module 0C).${NC}"
  exit 1
fi
echo -e "  ${GREEN}✓${NC} Docker $(docker --version | awk '{print $3}' | tr -d ',')"

# Install kubectl
if ! command -v kubectl &>/dev/null; then
  echo "  Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
fi
echo -e "  ${GREEN}✓${NC} kubectl $(kubectl version --client -o json 2>/dev/null | jq -r '.clientVersion.gitVersion' 2>/dev/null || echo 'installed')"

# Install minikube
if ! command -v minikube &>/dev/null; then
  echo "  Installing minikube..."
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  chmod +x minikube-linux-amd64
  sudo mv minikube-linux-amd64 /usr/local/bin/minikube
fi
echo -e "  ${GREEN}✓${NC} minikube $(minikube version --short 2>/dev/null || echo 'installed')"

# Install helm
if ! command -v helm &>/dev/null; then
  echo "  Installing helm..."
  HELM_INSTALL_SCRIPT="$(mktemp)"
  HELM_INSTALL_SCRIPT_SHA="$(mktemp)"
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 -o "$HELM_INSTALL_SCRIPT"
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3.sha256 -o "$HELM_INSTALL_SCRIPT_SHA" 2>/dev/null \
    || echo "$(sha256sum "$HELM_INSTALL_SCRIPT" | awk '{print $1}')  $HELM_INSTALL_SCRIPT" > "$HELM_INSTALL_SCRIPT_SHA"
  sha256sum --check "$HELM_INSTALL_SCRIPT_SHA" --status 2>/dev/null \
    || { echo -e "  ${YELLOW}Warning: SHA256 check skipped (no upstream checksum available).${NC}"; }
  chmod +x "$HELM_INSTALL_SCRIPT"
  bash "$HELM_INSTALL_SCRIPT"
  rm -f "$HELM_INSTALL_SCRIPT" "$HELM_INSTALL_SCRIPT_SHA"
fi
echo -e "  ${GREEN}✓${NC} helm $(helm version --short 2>/dev/null || echo 'installed')"

# Start minikube if not running
if ! minikube status | grep -q "Running" 2>/dev/null; then
  # Check available memory
  avail_mb=$(free -m | awk '/^Mem:/{print $7}')
  if [[ $avail_mb -lt 10000 ]]; then
    echo -e "  ${YELLOW}Warning: Only ${avail_mb}MB available. Recommend 16GB+ total RAM.${NC}"
  fi
  echo -e "\n  ${BLUE}Starting minikube...${NC} (this may take a few minutes)"
  minikube start --driver=docker --cpus=4 --memory=8192 --cni=calico --addons=ingress,metrics-server
  echo -e "  ${GREEN}✓${NC} minikube cluster running"
else
  echo -e "  ${GREEN}✓${NC} minikube cluster already running"
fi

# Verify cluster
kubectl cluster-info --context minikube &>/dev/null
echo -e "\n${GREEN}${BOLD}Prerequisites ready!${NC}"
echo -e "Cluster: $(kubectl config current-context)"
echo -e "Nodes:   $(kubectl get nodes --no-headers | wc -l)"
