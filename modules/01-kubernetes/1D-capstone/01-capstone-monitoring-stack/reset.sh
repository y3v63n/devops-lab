#!/usr/bin/env bash
set -euo pipefail

echo "Resetting: Exercise 1D-01 — Capstone Monitoring Stack"

WORK_DIR="/tmp/devops-lab/1D-01"

# ── Helm releases ──────────────────────────────────────────────────────────────
echo "  Removing Helm releases from monitoring namespace..."
helm uninstall grafana    -n monitoring 2>/dev/null || true
helm uninstall prometheus -n monitoring 2>/dev/null || true

# ── Kubernetes resources ───────────────────────────────────────────────────────
echo "  Removing health-checker resources..."
kubectl delete deployment  health-checker        -n monitoring 2>/dev/null || true
kubectl delete service     health-checker        -n monitoring 2>/dev/null || true
kubectl delete configmap   health-checker-config -n monitoring 2>/dev/null || true

# ── Namespace (optional — remove to start fully clean) ────────────────────────
echo "  Deleting monitoring namespace..."
kubectl delete namespace monitoring 2>/dev/null || true

# Wait for namespace termination (up to 60s) so re-create works cleanly
echo "  Waiting for namespace to terminate..."
kubectl wait --for=delete namespace/monitoring --timeout=60s 2>/dev/null || true

# ── Port-forward cleanup ───────────────────────────────────────────────────────
echo "  Killing any active port-forward on port 3000..."
pkill -f "port-forward.*3000" 2>/dev/null || true

# ── Work directory ─────────────────────────────────────────────────────────────
echo "  Cleaning work directory..."
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

echo ""
echo "  Done. Work directory reset to $WORK_DIR/"
echo "  Start fresh with: kubectl create namespace monitoring"
