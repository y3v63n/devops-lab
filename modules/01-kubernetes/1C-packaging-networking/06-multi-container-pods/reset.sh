#!/usr/bin/env bash
echo "Resetting Exercise 1C-06 — Multi-Container Pods..."

# Delete pods
for pod in init-demo sidecar-demo; do
  if kubectl get pod "$pod" &>/dev/null; then
    echo "  Deleting pod: $pod"
    kubectl delete pod "$pod" --grace-period=5
  else
    echo "  Pod $pod not found (already removed)"
  fi
done

# Clean up work directory
if [[ -d /tmp/devops-lab/1C-06 ]]; then
  echo "  Removing /tmp/devops-lab/1C-06"
  rm -rf /tmp/devops-lab/1C-06
fi

echo "Reset complete. You can now start the exercise fresh."
