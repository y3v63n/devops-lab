#!/usr/bin/env bash
echo "Resetting Exercise 1B-02 — Resource Limits..."

# Delete pods created during the exercise
kubectl delete pod resource-demo --ignore-not-found=true
kubectl delete pod memory-hog --ignore-not-found=true

echo "  Deleted pods: resource-demo, memory-hog"

# Clean up work directory
rm -rf /tmp/devops-lab/1B-02
echo "  Cleaned /tmp/devops-lab/1B-02"

echo "Reset complete."
