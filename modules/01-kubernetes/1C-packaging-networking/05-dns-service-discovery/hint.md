# Hints — Exercise 1C-05: DNS and Service Discovery

## Task 1 Hints

<details>
<summary>Hint 1: Pod completes before you can get logs</summary>

The busybox pod runs `nslookup` and exits. Use `--restart=Never` so it becomes a completed pod (not restarted), then `kubectl logs` to read the output.

If the pod shows `Completed` status, that's correct:
```bash
kubectl get pod dns-test
# STATUS: Completed  ← this is fine
kubectl logs dns-test
```
</details>

<details>
<summary>Hint 2: nslookup says "can't resolve"</summary>

Make sure the service exists first:
```bash
kubectl get service my-svc
```

If it doesn't exist, create it:
```bash
kubectl create deployment web-app --image=nginx
kubectl expose deployment web-app --port=80 --name=my-svc
```

Also try the full FQDN: `my-svc.default.svc.cluster.local`
</details>

<details>
<summary>Hint 3: Alternative if nslookup isn't available</summary>

```bash
kubectl run dns-test --image=busybox:1.35 --restart=Never -- \
  sh -c "nslookup my-svc.default.svc.cluster.local"
```

Or use a dig-capable image:
```bash
kubectl run dns-test --image=tutum/dnsutils --restart=Never -- \
  dig my-svc.default.svc.cluster.local
```
</details>

---

## Task 2 Hints

<details>
<summary>Hint 1: What makes a service "headless"?</summary>

The key is `clusterIP: None` in the Service spec. You cannot set this with `kubectl expose` — you must write the YAML manually.
```yaml
spec:
  clusterIP: None
  selector:
    app: stateful-app
```
</details>

<details>
<summary>Hint 2: StatefulSet pods not getting DNS names</summary>

For pod DNS to work with a StatefulSet, the StatefulSet must reference the headless service in `spec.serviceName`:
```yaml
spec:
  serviceName: headless-svc  # ← must match the Service name
```
Without this, pod DNS names like `stateful-app-0.headless-svc` won't resolve.
</details>

<details>
<summary>Hint 3: headless-dns.txt shows NXDOMAIN</summary>

It can take 15-30 seconds after pod creation for DNS records to propagate. Wait for pods to be Running:
```bash
kubectl wait --for=condition=ready pod/stateful-app-0 --timeout=60s
kubectl wait --for=condition=ready pod/stateful-app-1 --timeout=60s
```
Then run the DNS test pod.
</details>

---

## Task 3 Hints

<details>
<summary>Hint: Getting CoreDNS ConfigMap</summary>

```bash
kubectl get configmap coredns -n kube-system -o yaml \
  > /tmp/devops-lab/1C-05/coredns-config.txt
```

The `-n kube-system` is essential — CoreDNS lives in the kube-system namespace.
</details>

---

## Verify Troubleshooting

<details>
<summary>verify.sh says "headless-svc has clusterIP: None" fails</summary>

Double-check the Service was created correctly:
```bash
kubectl get service headless-svc -o yaml | grep clusterIP
```
Should show `clusterIP: None`. If it shows an IP, delete and recreate with the correct YAML:
```bash
kubectl delete service headless-svc
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: headless-svc
spec:
  clusterIP: None
  selector:
    app: stateful-app
  ports:
  - port: 80
EOF
```
</details>
