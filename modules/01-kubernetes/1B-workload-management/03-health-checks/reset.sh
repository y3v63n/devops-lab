#!/usr/bin/env bash
echo "Resetting Exercise 1B-03 — Health Checks..."

# Delete deployments created during the exercise
kubectl delete deployment liveness-demo --ignore-not-found=true
kubectl delete deployment readiness-demo --ignore-not-found=true
kubectl delete deployment failing-liveness --ignore-not-found=true

echo "  Deleted deployments: liveness-demo, readiness-demo, failing-liveness"

# Clean up work directory
rm -rf /tmp/devops-lab/1B-03
echo "  Cleaned /tmp/devops-lab/1B-03"

echo "Reset complete."
