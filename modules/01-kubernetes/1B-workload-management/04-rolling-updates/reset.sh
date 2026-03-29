#!/usr/bin/env bash
echo "Resetting Exercise 1B-04 — Rolling Updates..."

# Delete the deployment (also removes associated ReplicaSets and pods)
kubectl delete deployment rolling-demo --ignore-not-found=true
echo "  Deleted deployment: rolling-demo"

# Clean up work directory
rm -rf /tmp/devops-lab/1B-04
echo "  Cleaned /tmp/devops-lab/1B-04"

echo "Reset complete."
