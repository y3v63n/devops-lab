# Hints — Exercise 1A-04: Services

## Task 1 — ClusterIP Service
`kubectl expose` infers the selector from the deployment's Pod template labels. `--port` is the Service port; `--target-port` is the container port.

```bash
kubectl create deployment backend --image=nginx:alpine --replicas=2
kubectl expose deployment backend --port=80 --target-port=80 --name=backend-svc
# Verify the endpoints are populated (should show Pod IPs):
kubectl get endpoints backend-svc
```

If endpoints show `<none>`, the label selector isn't matching any Pods — check:
```bash
kubectl get pods --show-labels
kubectl describe svc backend-svc   # shows Selector field
```

## Task 2 — NodePort
```bash
kubectl expose deployment backend --port=80 --target-port=80 \
  --name=backend-nodeport --type=NodePort

# Get NodePort number:
kubectl get svc backend-nodeport -o jsonpath='{.spec.ports[0].nodePort}'

# Get a node IP:
kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}'
```

In a local cluster (minikube/kind), the node IP may be localhost or a local IP. With minikube:
```bash
minikube service backend-nodeport --url
```

## Task 3 — Internal Access via DNS
The debug pod needs curl. `curlimages/curl` is a minimal curl image. The key is using the **Service name** as the hostname — CoreDNS resolves it.

```bash
# If debug-pod already exists:
kubectl delete pod debug-pod --ignore-not-found

kubectl run debug-pod --image=curlimages/curl:latest --restart=Never \
  --command -- sleep 300

kubectl wait pod/debug-pod --for=condition=Ready --timeout=30s

# Curl using Service name (works because CoreDNS resolves it):
kubectl exec debug-pod -- curl -s http://backend-svc:80

# You can also use the FQDN:
kubectl exec debug-pod -- curl -s http://backend-svc.default.svc.cluster.local:80
```

## Task 4 — Service Types Explanation
Your explanation should cover the 4 types and include practical use cases. A table or bullet points both work well.

## General Tips
- `kubectl describe svc <name>` shows the Endpoints (healthy Pod IPs) and the selector.
- Services are namespace-scoped: a Service in namespace `A` is not reachable by its short name from namespace `B` — use the FQDN `<svc>.<ns>.svc.cluster.local`.
- `kubectl get svc` with no `-n` flag shows services in the `default` namespace. Use `-A` for all namespaces.
