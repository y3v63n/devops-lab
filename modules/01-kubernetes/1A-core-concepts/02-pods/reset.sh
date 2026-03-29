#!/usr/bin/env bash
# reset.sh — Exercise 1A-02: Pods
# Deletes the lab pod (if it exists) and clears task output files.

set -euo pipefail

WORK_DIR="/tmp/devops-lab/1A-02"

echo "Resetting exercise 1A-02..."

# Kill any lingering port-forward for lab-nginx
if pgrep -f "port-forward pod/lab-nginx" &>/dev/null; then
  pkill -f "port-forward pod/lab-nginx" && echo "  ✓ Killed background port-forward"
fi

# Delete the pod if it exists
if kubectl get pod lab-nginx &>/dev/null 2>&1; then
  kubectl delete pod lab-nginx --grace-period=0 --force 2>/dev/null || true
  echo "  ✓ Deleted pod lab-nginx"
else
  echo "  ~ Pod lab-nginx not found (already gone)"
fi

# Clear work directory
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
echo "  ✓ Removed $WORK_DIR and recreated it (empty)"

echo ""
echo "Ready. Re-run the tasks in lesson.md to complete the exercise."
