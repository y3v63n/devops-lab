#!/usr/bin/env bash
echo "Resetting Exercise 1C-03 — Ingress..."

# Delete ingress
if kubectl get ingress app-ingress &>/dev/null; then
  echo "  Deleting ingress: app-ingress"
  kubectl delete ingress app-ingress
fi

# Delete services
for svc in app-v1 app-v2; do
  if kubectl get service "$svc" &>/dev/null; then
    echo "  Deleting service: $svc"
    kubectl delete service "$svc"
  fi
done

# Delete deployments
for deploy in app-v1 app-v2; do
  if kubectl get deployment "$deploy" &>/dev/null; then
    echo "  Deleting deployment: $deploy"
    kubectl delete deployment "$deploy"
  fi
done

# Clean up work directory
if [[ -d /tmp/devops-lab/1C-03 ]]; then
  echo "  Removing /tmp/devops-lab/1C-03"
  rm -rf /tmp/devops-lab/1C-03
fi

echo "Reset complete. You can now start the exercise fresh."
