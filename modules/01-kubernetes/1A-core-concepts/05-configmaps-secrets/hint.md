# Hints — Exercise 1A-05: ConfigMaps and Secrets

## Task 1 — ConfigMap
`--from-literal` adds key=value pairs directly. You can also create from a file with `--from-file=config.env`.

```bash
kubectl create configmap app-config \
  --from-literal=DB_HOST=postgres.default.svc.cluster.local \
  --from-literal=DB_PORT=5432 \
  --from-literal=LOG_LEVEL=info \
  --dry-run=client -o yaml | tee /tmp/devops-lab/1A-05/configmap.yaml

kubectl apply -f /tmp/devops-lab/1A-05/configmap.yaml
```

View the result: `kubectl get configmap app-config -o yaml`

## Task 2 — Secret
Kubernetes automatically base64-encodes the values when you use `--from-literal`.

```bash
kubectl create secret generic app-secret \
  --from-literal=DB_PASSWORD=superSecretPassword123 \
  --dry-run=client -o yaml | tee /tmp/devops-lab/1A-05/secret.yaml

kubectl apply -f /tmp/devops-lab/1A-05/secret.yaml
```

To verify the value decodes correctly:
```bash
kubectl get secret app-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 --decode
# Should print: superSecretPassword123
```

**Note**: If you write the YAML by hand and want to provide a base64 value, encode it first:
```bash
echo -n "superSecretPassword123" | base64
```
Use `-n` to avoid encoding the trailing newline.

## Task 3 — Pod with Env Vars
The Pod spec uses `valueFrom.configMapKeyRef` for ConfigMap keys and `valueFrom.secretKeyRef` for Secret keys.

If the Pod gets stuck in `Pending` or `CrashLoopBackOff`, check:
```bash
kubectl describe pod config-test-pod
# Look at Events section — common issues:
# - ConfigMap/Secret not found (wrong name)
# - Key not found in ConfigMap/Secret (wrong key name)
```

## Task 4 — Volume Mount
When a ConfigMap is mounted as a volume, **each key becomes a file**. The file content is the value.

```bash
# After the pod is running:
kubectl exec volume-test-pod -- ls /etc/config
# Output: DB_HOST  DB_PORT  LOG_LEVEL

kubectl exec volume-test-pod -- cat /etc/config/DB_HOST
# Output: postgres.default.svc.cluster.local
```

Key advantage over env vars: Volume-mounted ConfigMaps update dynamically (within ~1 minute) when the ConfigMap is changed. Env vars are static after Pod start.

## General Tips
- `kubectl edit configmap app-config` lets you modify the ConfigMap in-place — changes propagate to volume mounts automatically.
- For multi-line values (like TLS certs), use `--from-file` pointing to the cert file.
- `envFrom` lets you mount ALL keys from a ConfigMap as env vars at once — convenient but can pollute the env namespace.
