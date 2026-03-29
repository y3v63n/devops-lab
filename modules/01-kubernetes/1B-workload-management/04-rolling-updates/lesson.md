# Exercise 1B-04: Rolling Updates and Rollbacks

## Concept

Kubernetes deployments support multiple update strategies:

### Rolling Update (default)
Gradually replaces old pods with new ones. Zero downtime when configured correctly.

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1          # Extra pods above desired count during update
    maxUnavailable: 0    # Pods that can be unavailable during update
```

| Parameter | Effect |
|-----------|--------|
| `maxSurge: 1` | One extra pod spins up before old ones die |
| `maxUnavailable: 0` | Never reduce below desired count during update |
| Both = 0 | Not allowed — deadlock |

### Revision History
Every change creates a new ReplicaSet. `revisionHistoryLimit` (default: 10) controls how many to keep. Older ReplicaSets enable rollbacks.

### Recreate Strategy
Kills all old pods, then creates new ones. Has downtime. Used when you can't run two versions simultaneously.

---

## Tasks

### Setup
```bash
mkdir -p /tmp/devops-lab/1B-04
```

### Task 1 — Deployment with Rolling Strategy
Create and save a deployment YAML with explicit rolling update strategy:
```bash
cat > /tmp/devops-lab/1B-04/deploy.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rolling-demo
spec:
  replicas: 3
  revisionHistoryLimit: 5
  selector:
    matchLabels:
      app: rolling-demo
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: rolling-demo
    spec:
      containers:
      - name: nginx
        image: nginx:1.24
EOF
kubectl apply -f /tmp/devops-lab/1B-04/deploy.yaml
kubectl rollout status deployment/rolling-demo
```

### Task 2 — Update the Image
Update nginx from 1.24 to 1.25 and observe the rolling update:
```bash
kubectl set image deployment/rolling-demo nginx=nginx:1.25

# Watch the rollout in real time
kubectl rollout status deployment/rolling-demo | tee /tmp/devops-lab/1B-04/rollout-log.txt

# See how many ReplicaSets exist now
kubectl get replicasets -l app=rolling-demo >> /tmp/devops-lab/1B-04/rollout-log.txt
```

### Task 3 — Simulate a Failed Rollout
Update to a nonexistent image tag and watch it fail:
```bash
kubectl set image deployment/rolling-demo nginx=nginx:nonexistent

# Watch it fail (Ctrl+C after ~30 seconds)
kubectl rollout status deployment/rolling-demo --timeout=30s | tee /tmp/devops-lab/1B-04/failed-rollout.txt 2>&1 || true

# Check the pod status — some will be in ImagePullBackOff
kubectl get pods -l app=rolling-demo >> /tmp/devops-lab/1B-04/failed-rollout.txt
```

### Task 4 — Rollback
Roll back to the previous working version and capture history:
```bash
kubectl rollout undo deployment/rolling-demo

# Wait for rollback to complete
kubectl rollout status deployment/rolling-demo

# View the full revision history
kubectl rollout history deployment/rolling-demo > /tmp/devops-lab/1B-04/history.txt

# Confirm pods are running
kubectl get pods -l app=rolling-demo >> /tmp/devops-lab/1B-04/history.txt
```

To rollback to a specific revision: `kubectl rollout undo deployment/rolling-demo --to-revision=1`

---

## What Just Happened

- With `maxUnavailable=0`, the rolling update never dropped below 3 running pods
- `maxSurge=1` allowed a 4th pod to exist temporarily during the transition
- The bad image tag left half the pods in `ImagePullBackOff` — the old pods were preserved
- `kubectl rollout undo` switched the deployment back to the previous ReplicaSet instantly

---

## Interview Question

**"Compare rolling updates, blue-green deployments, and canary releases."**

Strong answer: Rolling updates gradually replace pods in-place — zero downtime, low resource cost, but both old and new versions run simultaneously during the update. Blue-green runs two full identical environments; you flip traffic all at once — instant rollback, but double the resources. Canary routes a small percentage of traffic to the new version first, then increments — best for risky changes, but requires traffic splitting infrastructure (like a service mesh or ingress controller with weight rules).
