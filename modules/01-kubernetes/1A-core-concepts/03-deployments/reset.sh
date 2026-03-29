#!/usr/bin/env bash
# reset.sh — Exercise 1A-03: Deployments
# Deletes the web-app deployment and clears task output files.

set -euo pipefail

WORK_DIR="/tmp/devops-lab/1A-03"

echo "Resetting exercise 1A-03..."

# Delete the deployment (cascades to ReplicaSets and Pods)
if kubectl get deployment web-app &>/dev/null 2>&1; then
  kubectl delete deployment web-app
  echo "  ✓ Deleted deployment web-app (and its ReplicaSets + Pods)"
else
  echo "  ~ Deployment web-app not found (already gone)"
fi

# Clear work directory
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
echo "  ✓ Removed $WORK_DIR and recreated it (empty)"

echo ""
echo "Ready. Re-run the tasks in lesson.md to complete the exercise."
