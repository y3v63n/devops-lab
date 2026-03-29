#!/usr/bin/env bash
# reset.sh — Exercise 1A-04: Services
# Removes lab services, deployment, and debug pod; clears output files.

set -euo pipefail

WORK_DIR="/tmp/devops-lab/1A-04"

echo "Resetting exercise 1A-04..."

# Delete services
for svc in backend-svc backend-nodeport; do
  if kubectl get svc "$svc" &>/dev/null 2>&1; then
    kubectl delete svc "$svc"
    echo "  ✓ Deleted service $svc"
  else
    echo "  ~ Service $svc not found (already gone)"
  fi
done

# Delete deployment
if kubectl get deployment backend &>/dev/null 2>&1; then
  kubectl delete deployment backend
  echo "  ✓ Deleted deployment backend"
else
  echo "  ~ Deployment backend not found (already gone)"
fi

# Delete debug pod if still lingering
if kubectl get pod debug-pod &>/dev/null 2>&1; then
  kubectl delete pod debug-pod --grace-period=0 --force 2>/dev/null || true
  echo "  ✓ Deleted pod debug-pod"
fi

# Clear work directory
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
echo "  ✓ Removed $WORK_DIR and recreated it (empty)"

echo ""
echo "Ready. Re-run the tasks in lesson.md to complete the exercise."
