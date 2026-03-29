#!/usr/bin/env bash
echo "Resetting Exercise 1C-04 — Network Policies..."

# Delete the entire namespace (removes all resources inside it)
if kubectl get namespace netpol-lab &>/dev/null; then
  echo "  Deleting namespace: netpol-lab (this removes all pods, services, and policies inside)"
  kubectl delete namespace netpol-lab
  echo "  Waiting for namespace deletion..."
  kubectl wait --for=delete namespace/netpol-lab --timeout=60s 2>/dev/null || true
else
  echo "  Namespace netpol-lab not found (already removed)"
fi

# Clean up work directory
if [[ -d /tmp/devops-lab/1C-04 ]]; then
  echo "  Removing /tmp/devops-lab/1C-04"
  rm -rf /tmp/devops-lab/1C-04
fi

echo "Reset complete. You can now start the exercise fresh."
