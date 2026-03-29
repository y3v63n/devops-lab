# Exercise 1A-05: ConfigMaps and Secrets

## Theory

Hardcoding configuration into container images is an anti-pattern — it couples your deployment artifact to a specific environment. Kubernetes provides two objects for decoupling configuration from application code.

### ConfigMaps

A **ConfigMap** stores non-sensitive configuration data as key-value pairs. The data is stored in plaintext in etcd. ConfigMaps can be consumed by Pods in three ways:

1. **Environment variables** — individual keys mapped to env var names
2. **Bulk env vars** — all keys in a ConfigMap loaded as env vars (`envFrom`)
3. **Volume mounts** — the ConfigMap is projected as files in a directory; each key becomes a filename and the value becomes the file content

ConfigMaps are not namespaced across clusters — they belong to a specific namespace. A ConfigMap in `default` is not accessible from `production`.

### Secrets

A **Secret** stores sensitive data such as passwords, OAuth tokens, or TLS certificates. Secrets are similar to ConfigMaps but:

- Values are **base64-encoded** (not encrypted at rest by default)
- Access can be restricted via RBAC more granularly
- Kubernetes avoids writing Secret data to disk on nodes when possible (uses tmpfs)
- With envelope encryption enabled, etcd stores Secrets encrypted at rest

**Important**: Base64 is encoding, not encryption. Anyone with `kubectl get secret` permissions can trivially decode the value. In production, use external secret managers (HashiCorp Vault, AWS Secrets Manager, Sealed Secrets) or enable etcd encryption at rest.

```
┌─────────────────────────────────────────────────────┐
│                        POD                          │
│                                                     │
│  env:                        volumeMounts:          │
│  - name: DB_HOST             - name: config-vol     │
│    valueFrom:                  mountPath: /etc/cfg  │
│      configMapKeyRef:                               │
│        name: app-config      ┌──────────────────┐   │
│        key: DB_HOST          │  /etc/cfg/        │   │
│  - name: DB_PASSWORD         │    DB_HOST        │   │
│    valueFrom:                │    DB_PORT        │   │
│      secretKeyRef:           │    LOG_LEVEL      │   │
│        name: app-secret      └──────────────────┘   │
│        key: DB_PASSWORD                             │
└─────────────────────────────────────────────────────┘
```

---

## Tasks

### Setup
```bash
mkdir -p /tmp/devops-lab/1A-05
```

### Task 1 — Create ConfigMap
```bash
kubectl create configmap app-config \
  --from-literal=DB_HOST=postgres.default.svc.cluster.local \
  --from-literal=DB_PORT=5432 \
  --from-literal=LOG_LEVEL=info \
  --dry-run=client -o yaml \
  | tee /tmp/devops-lab/1A-05/configmap.yaml

kubectl apply -f /tmp/devops-lab/1A-05/configmap.yaml
kubectl describe configmap app-config
```

### Task 2 — Create Secret
```bash
kubectl create secret generic app-secret \
  --from-literal=DB_PASSWORD=superSecretPassword123 \
  --dry-run=client -o yaml \
  | tee /tmp/devops-lab/1A-05/secret.yaml

kubectl apply -f /tmp/devops-lab/1A-05/secret.yaml

# Notice the value is base64 encoded:
kubectl get secret app-secret -o yaml
# Decode it:
kubectl get secret app-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 --decode
```

### Task 3 — Pod with Env Vars from ConfigMap and Secret
```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: config-test-pod
spec:
  containers:
  - name: app
    image: busybox:latest
    command: ["sleep", "300"]
    env:
    - name: DB_HOST
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: DB_HOST
    - name: DB_PORT
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: DB_PORT
    - name: LOG_LEVEL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: LOG_LEVEL
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: DB_PASSWORD
EOF

kubectl wait pod/config-test-pod --for=condition=Ready --timeout=60s

kubectl exec config-test-pod -- env | grep -E "DB_|LOG_" \
  | tee /tmp/devops-lab/1A-05/env-output.txt
```

### Task 4 — Pod with ConfigMap as Volume
```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: volume-test-pod
spec:
  containers:
  - name: app
    image: busybox:latest
    command: ["sleep", "300"]
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: app-config
EOF

kubectl wait pod/volume-test-pod --for=condition=Ready --timeout=60s

kubectl exec volume-test-pod -- ls /etc/config \
  | tee /tmp/devops-lab/1A-05/volume-mount.txt

# Read one of the config files:
kubectl exec volume-test-pod -- cat /etc/config/DB_HOST
```

---

## Interview Question

**"Kubernetes Secrets are only base64-encoded, not encrypted. Why is this a security concern and how do you address it in production?"**

Think about:
- Base64 is trivially reversible: `echo 'c3VwZXJTZWNyZXQ=' | base64 --decode`
- Anyone with read access to the Secret object (or to etcd) sees the plaintext value
- Default etcd is unencrypted — if someone gets etcd backup, they get all secrets
- Solutions: etcd encryption at rest (EncryptionConfiguration), external secrets operators (External Secrets Operator + AWS/GCP/Vault), Sealed Secrets (asymmetric encryption, safe to store in Git), HashiCorp Vault with the Agent Injector sidecar
- RBAC: restrict `get`/`list` on Secrets to only workloads that need them

---

## What Just Happened

When you mounted the ConfigMap as a volume, Kubernetes created a `projected` volume backed by the ConfigMap data. Each key in the ConfigMap became a separate file in `/etc/config/`. This is especially powerful because **ConfigMap volume mounts are live** — if you update the ConfigMap, Kubernetes propagates the change to the mounted files within seconds (the kubelet polls for updates). Environment variables, by contrast, are baked in at Pod start and do not update without restarting the Pod.
