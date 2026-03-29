#!/usr/bin/env bash
echo "Resetting Exercise 1C-02 — Helm Create Chart..."

# Uninstall Helm release if it exists
if helm list --short 2>/dev/null | grep -q "^my-node-monitor$"; then
  echo "  Uninstalling Helm release: my-node-monitor"
  helm uninstall my-node-monitor
else
  echo "  No my-node-monitor release found (already removed)"
fi

# Clean up work directory
if [[ -d /tmp/devops-lab/1C-02 ]]; then
  echo "  Removing /tmp/devops-lab/1C-02"
  rm -rf /tmp/devops-lab/1C-02
fi

echo "Reset complete. You can now start the exercise fresh."
