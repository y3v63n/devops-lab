#!/usr/bin/env bash
# reset.sh — Exercise 1A-05: ConfigMaps and Secrets
# Deletes lab ConfigMap, Secret, and test pods; clears output files.

set -euo pipefail

WORK_DIR="/tmp/devops-lab/1A-05"

echo "Resetting exercise 1A-05..."

# Delete test pods
for pod in config-test-pod volume-test-pod; do
  if kubectl get pod "$pod" &>/dev/null 2>&1; then
    kubectl delete pod "$pod" --grace-period=0 --force 2>/dev/null || true
    echo "  ✓ Deleted pod $pod"
  else
    echo "  ~ Pod $pod not found (already gone)"
  fi
done

# Delete ConfigMap
if kubectl get configmap app-config &>/dev/null 2>&1; then
  kubectl delete configmap app-config
  echo "  ✓ Deleted ConfigMap app-config"
else
  echo "  ~ ConfigMap app-config not found (already gone)"
fi

# Delete Secret
if kubectl get secret app-secret &>/dev/null 2>&1; then
  kubectl delete secret app-secret
  echo "  ✓ Deleted Secret app-secret"
else
  echo "  ~ Secret app-secret not found (already gone)"
fi

# Clear work directory
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
echo "  ✓ Removed $WORK_DIR and recreated it (empty)"

echo ""
echo "Ready. Re-run the tasks in lesson.md to complete the exercise."
