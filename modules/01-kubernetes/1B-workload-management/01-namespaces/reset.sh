#!/usr/bin/env bash
echo "Resetting Exercise 1B-01 — Namespaces..."

# Delete namespaces (also removes all resources within them)
kubectl delete namespace dev --ignore-not-found=true
kubectl delete namespace staging --ignore-not-found=true

# Reset context to default namespace
kubectl config set-context --current --namespace=default
echo "  Context namespace reset to: default"

# Clean up work directory
rm -rf /tmp/devops-lab/1B-01
echo "  Cleaned /tmp/devops-lab/1B-01"

echo "Reset complete."
