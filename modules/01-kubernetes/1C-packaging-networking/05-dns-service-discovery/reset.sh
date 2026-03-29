#!/usr/bin/env bash
echo "Resetting Exercise 1C-05 — DNS and Service Discovery..."

# Delete StatefulSet
if kubectl get statefulset stateful-app &>/dev/null; then
  echo "  Deleting StatefulSet: stateful-app"
  kubectl delete statefulset stateful-app
fi

# Delete services
for svc in my-svc headless-svc; do
  if kubectl get service "$svc" &>/dev/null; then
    echo "  Deleting service: $svc"
    kubectl delete service "$svc"
  fi
done

# Delete deployment
if kubectl get deployment web-app &>/dev/null; then
  echo "  Deleting deployment: web-app"
  kubectl delete deployment web-app
fi

# Clean up any leftover test pods
for pod in dns-test headless-test; do
  if kubectl get pod "$pod" &>/dev/null; then
    echo "  Deleting pod: $pod"
    kubectl delete pod "$pod"
  fi
done

# Clean up work directory
if [[ -d /tmp/devops-lab/1C-05 ]]; then
  echo "  Removing /tmp/devops-lab/1C-05"
  rm -rf /tmp/devops-lab/1C-05
fi

echo "Reset complete. You can now start the exercise fresh."
