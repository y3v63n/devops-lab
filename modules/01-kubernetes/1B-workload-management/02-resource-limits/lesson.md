# Exercise 1B-02: Resource Requests and Limits

## Concept

Kubernetes uses **requests** and **limits** to manage CPU and memory:

| Field | Meaning |
|-------|---------|
| `requests` | Minimum guaranteed; used for scheduling decisions |
| `limits` | Maximum allowed; enforced at runtime |

### CPU Units
- `1` = 1 full core
- `100m` = 100 millicores = 0.1 core
- `500m` = half a core

### Memory Units
- `64Mi` = 64 mebibytes
- `1Gi` = 1 gibibyte
- `128M` = 128 megabytes (note: Mi vs M differ slightly)

### QoS Classes
Kubernetes assigns a Quality of Service class to each pod:

| Class | Condition |
|-------|-----------|
| **Guaranteed** | requests == limits for all containers |
| **Burstable** | requests set but != limits |
| **BestEffort** | no requests or limits set |

When nodes run out of memory, BestEffort pods are killed first, then Burstable, then Guaranteed.

---

## Tasks

### Setup
```bash
mkdir -p /tmp/devops-lab/1B-02
```

### Task 1 — Pod with Resource Requests and Limits
Create a pod YAML with specific resource constraints:
```yaml
# /tmp/devops-lab/1B-02/resource-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-demo
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    resources:
      requests:
        cpu: "100m"
        memory: "64Mi"
      limits:
        cpu: "200m"
        memory: "128Mi"
```
Apply it and verify it's running:
```bash
kubectl apply -f /tmp/devops-lab/1B-02/resource-pod.yaml
kubectl get pod resource-demo
```

### Task 2 — Pending Pod (Impossible Request)
Create a pod requesting more memory than any node has:
```bash
kubectl run memory-hog \
  --image=nginx:1.25 \
  --overrides='{"spec":{"containers":[{"name":"memory-hog","image":"nginx:1.25","resources":{"requests":{"memory":"999Gi"}}}]}}' \
  --restart=Never

# Wait a moment, then check status
kubectl get pod memory-hog
kubectl describe pod memory-hog > /tmp/devops-lab/1B-02/pending-reason.txt
```
Look for the "Events" section — it will show `Insufficient memory`.

### Task 3 — Metrics
Capture resource usage (requires metrics-server):
```bash
kubectl top pods > /tmp/devops-lab/1B-02/metrics.txt 2>&1
kubectl top nodes >> /tmp/devops-lab/1B-02/metrics.txt 2>&1
```
If metrics-server isn't running: `kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`

### Task 4 — Document QoS Classes
Write your understanding of QoS classes:
```bash
cat > /tmp/devops-lab/1B-02/qos-notes.txt << 'EOF'
QoS Classes in Kubernetes:

Guaranteed:
- requests == limits for ALL containers in the pod
- Highest priority, killed last
- Example: cpu request=200m limit=200m, mem request=128Mi limit=128Mi

Burstable:
- At least one container has requests set, but requests != limits
- Medium priority
- Example: cpu request=100m limit=500m (can burst to 500m)

BestEffort:
- No requests or limits set on ANY container
- Lowest priority, killed first under memory pressure
- Not recommended for production workloads

Eviction order under node pressure: BestEffort > Burstable > Guaranteed
EOF
```

---

## What Just Happened

- The `resource-demo` pod was scheduled because the node had 100m CPU and 64Mi memory available
- The `memory-hog` pod is Pending because no node can satisfy 999Gi memory
- Kubernetes uses requests (not limits) for scheduling — limits are enforced at runtime
- CPU limits throttle; memory limits OOM-kill

---

## Interview Question

**"What happens when a container exceeds its memory limit vs CPU limit?"**

Strong answer: CPU is compressible — exceeding the CPU limit causes throttling (the container runs slower but doesn't die). Memory is incompressible — exceeding the memory limit causes the container to be OOM-killed and restarted. This is why setting memory limits carefully matters: too low and your app gets killed; too high and you risk node instability.
