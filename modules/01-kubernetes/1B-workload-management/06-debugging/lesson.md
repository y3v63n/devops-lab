# Exercise 1B-06: Kubernetes Debugging

## Concept

Systematic debugging is a core Kubernetes skill. Every experienced operator has a mental checklist.

### The Debugging Toolkit

| Command | Use |
|---------|-----|
| `kubectl get pods` | Pod status at a glance |
| `kubectl describe pod <name>` | Events, conditions, probe status |
| `kubectl logs <pod>` | Container stdout/stderr |
| `kubectl logs --previous <pod>` | Logs from the last crashed container |
| `kubectl exec -it <pod> -- sh` | Shell into a running container |
| `kubectl get events --sort-by=.lastTimestamp` | Cluster-wide recent events |
| `kubectl describe service <name>` | Check endpoints |

### Common Error States

| State | Likely Cause |
|-------|-------------|
| `Pending` | No schedulable node (resources, taints, affinity) |
| `ImagePullBackOff` | Bad image name, tag, or registry credentials |
| `CrashLoopBackOff` | App crashing on startup (check logs --previous) |
| `OOMKilled` | Memory limit exceeded |
| `Error` | Container exited non-zero |
| `0/1 Ready` | Readiness probe failing |

### Service Endpoint Debugging
```bash
# Are there endpoints? (no endpoints = selector mismatch)
kubectl get endpoints <service-name>

# Does selector match pod labels?
kubectl get pods --show-labels
kubectl describe service <name> | grep Selector
```

---

## Tasks

Run `./reset.sh` first to set up the three broken deployments, then diagnose and fix each one.

### Setup
```bash
mkdir -p /tmp/devops-lab/1B-06
./reset.sh  # This creates the broken deployments
```

### Task 1 — Fix ImagePullBackOff
The `broken-image` deployment uses a nonexistent image tag.

```bash
# Diagnose
kubectl get pods -l app=broken-image
kubectl describe pod -l app=broken-image > /tmp/devops-lab/1B-06/issue1.txt

# What do you see in Events? Look for ErrImagePull / ImagePullBackOff
grep -A5 "Events:" /tmp/devops-lab/1B-06/issue1.txt

# Fix: update to a valid image
kubectl set image deployment/broken-image nginx=nginx:1.25
kubectl rollout status deployment/broken-image
```

### Task 2 — Fix CrashLoopBackOff from Bad Probe
The `broken-probe` deployment has a liveness probe pointing to the wrong port.

```bash
# Diagnose
kubectl get pods -l app=broken-probe
kubectl describe pod -l app=broken-probe > /tmp/devops-lab/1B-06/issue2.txt

# Look for liveness probe failures in events
grep -i "liveness\|probe\|kill\|restart" /tmp/devops-lab/1B-06/issue2.txt

# Fix: patch the liveness probe to use port 80
kubectl patch deployment broken-probe --type=json -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/livenessProbe/httpGet/port", "value": 80}
]'
kubectl rollout status deployment/broken-probe
```

### Task 3 — Fix Service with No Endpoints
The `broken-selector` service has a label selector that doesn't match any pods.

```bash
# Diagnose: service exists but has no endpoints
kubectl get service broken-selector-svc
kubectl get endpoints broken-selector-svc
kubectl describe service broken-selector-svc > /tmp/devops-lab/1B-06/issue3.txt

# Compare service selector to pod labels
kubectl describe service broken-selector-svc | grep Selector
kubectl get pods -l app=broken-selector --show-labels

# Fix: patch the service selector to match the deployment's labels
kubectl patch service broken-selector-svc --type=merge \
  -p '{"spec":{"selector":{"app":"broken-selector"}}}'

# Verify endpoints now exist
kubectl get endpoints broken-selector-svc
```

### Task 4 — Connectivity Verification
After fixing all three, verify services are reachable:
```bash
# Create a debug pod for testing
kubectl run debug-pod --image=busybox:1.35 --rm -it --restart=Never -- sh

# From inside the pod, test each service:
# wget -qO- http://broken-image-svc
# wget -qO- http://broken-probe-svc
# wget -qO- http://broken-selector-svc

# Or run it non-interactively:
kubectl run debug-pod --image=busybox:1.35 --rm --restart=Never \
  -- sh -c "
    echo '=== broken-image-svc ===' && wget -qO- --timeout=5 http://broken-image-svc 2>&1 | head -3
    echo '=== broken-probe-svc ===' && wget -qO- --timeout=5 http://broken-probe-svc 2>&1 | head -3
    echo '=== broken-selector-svc ===' && wget -qO- --timeout=5 http://broken-selector-svc 2>&1 | head -3
  " > /tmp/devops-lab/1B-06/connectivity.txt 2>&1
```

---

## What Just Happened

- `ImagePullBackOff` was a bad image tag — a one-liner fix with `kubectl set image`
- The probe was pointing to port 9999 instead of 80 — nginx kept getting killed and restarting
- The service selector `label=wrong` didn't match pods labeled `app=broken-selector` — zero endpoints, no traffic
- All three are common real-world issues; the debugging workflow is always: get → describe → logs → fix

---

## Interview Question

**"Walk me through debugging a pod in CrashLoopBackOff."**

Strong answer: First, `kubectl get pod <name>` to confirm the state and see restart count. Then `kubectl describe pod <name>` to check events — is it OOMKilled, liveness probe failure, or an exec error? Then `kubectl logs <name> --previous` to see the last crash's output. If the container won't start at all, check the image and command. If it starts but crashes, look at the app logs. If liveness is killing it, check probe configuration. Common fixes: increase memory limit, fix the liveness probe path/port, fix the startup command, or check if a required ConfigMap/Secret is missing.
