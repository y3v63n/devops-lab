#!/usr/bin/env bash
echo "Resetting Exercise 1C-01 — Helm Basics..."

# Uninstall Helm release if it exists
if helm list --short 2>/dev/null | grep -q "^my-nginx$"; then
  echo "  Uninstalling Helm release: my-nginx"
  helm uninstall my-nginx
else
  echo "  No my-nginx release found (already removed)"
fi

# Clean up work directory
if [[ -d /tmp/devops-lab/1C-01 ]]; then
  echo "  Removing /tmp/devops-lab/1C-01"
  rm -rf /tmp/devops-lab/1C-01
fi

echo "Reset complete. You can now start the exercise fresh."
