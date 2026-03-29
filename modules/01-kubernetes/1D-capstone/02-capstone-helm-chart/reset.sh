#!/usr/bin/env bash
set -euo pipefail

echo "Resetting: Exercise 1D-02 — Capstone Helm Chart"

WORK_DIR="/tmp/devops-lab/1D-02"

# ── Helm release ───────────────────────────────────────────────────────────────
echo "  Uninstalling blockchain-monitor Helm release (if present)..."
helm uninstall blockchain-monitor -n monitoring 2>/dev/null || true

# ── Kubernetes namespace ───────────────────────────────────────────────────────
echo "  Deleting monitoring namespace (if present)..."
kubectl delete namespace monitoring 2>/dev/null || true
kubectl wait --for=delete namespace/monitoring --timeout=60s 2>/dev/null || true

# ── Port-forwards ──────────────────────────────────────────────────────────────
echo "  Killing any active port-forwards on port 3000..."
pkill -f "port-forward.*3000" 2>/dev/null || true

# ── Work directory ─────────────────────────────────────────────────────────────
echo "  Cleaning work directory..."
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

echo ""
echo "  Done. Work directory reset to $WORK_DIR/"
echo "  Start fresh with:"
echo "    cd $WORK_DIR && helm create blockchain-monitor"
