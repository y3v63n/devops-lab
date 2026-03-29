#!/usr/bin/env bash
# reset.sh — Exercise 1A-06: Persistent Volumes
# Deletes lab pods and PVC, clears output files.

set -euo pipefail

WORK_DIR="/tmp/devops-lab/1A-06"

echo "Resetting exercise 1A-06..."

# Delete pods
for pod in writer-pod reader-pod; do
  if kubectl get pod "$pod" &>/dev/null 2>&1; then
    kubectl delete pod "$pod" --grace-period=0 --force 2>/dev/null || true
    echo "  ✓ Deleted pod $pod"
  else
    echo "  ~ Pod $pod not found (already gone)"
  fi
done

# Delete PVC (this may also delete the underlying PV if reclaim policy is Delete)
if kubectl get pvc data-pvc &>/dev/null 2>&1; then
  kubectl delete pvc data-pvc
  echo "  ✓ Deleted PVC data-pvc"
  echo "    (If reclaim policy is Retain, the PV still exists — check: kubectl get pv)"
else
  echo "  ~ PVC data-pvc not found (already gone)"
fi

# Clear work directory
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
echo "  ✓ Removed $WORK_DIR and recreated it (empty)"

echo ""
echo "Ready. Re-run the tasks in lesson.md to complete the exercise."
