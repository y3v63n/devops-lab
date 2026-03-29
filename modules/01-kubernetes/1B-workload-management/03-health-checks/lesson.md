# Exercise 1B-03: Health Checks (Probes)

## Concept

Kubernetes uses three types of probes to monitor container health:

| Probe | Purpose | Failure Action |
|-------|---------|----------------|
| **Liveness** | Is the container alive? | Restart the container |
| **Readiness** | Is the container ready to serve traffic? | Remove from Service endpoints |
| **Startup** | Has the container finished starting? | Restart if exceeded |

### Probe Types
- **HTTP GET** — expects 200-399 status code
- **TCP Socket** — checks if port accepts connections
- **Exec** — runs a command; exit code 0 = success

### Key Parameters
```yaml
initialDelaySeconds: 5    # Wait before first probe
periodSeconds: 10         # How often to probe
failureThreshold: 3       # Failures before action
successThreshold: 1       # Successes to become healthy
timeoutSeconds: 1         # Probe timeout
```

---

## Tasks

### Setup
```bash
mkdir -p /tmp/devops-lab/1B-03
```

### Task 1 — HTTP Liveness Probe
Create a deployment with an HTTP liveness probe:
```bash
cat > /tmp/devops-lab/1B-03/liveness.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: liveness-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: liveness-demo
  template:
    metadata:
      labels:
        app: liveness-demo
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        livenessProbe:
          httpGet:
            path: /healthz
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
          failureThreshold: 3
EOF
kubectl apply -f /tmp/devops-lab/1B-03/liveness.yaml
```
Note: nginx doesn't have a `/healthz` endpoint, so it will return 404 — but 404 is NOT in 200-399, so it will actually fail. Use `/` instead for a real test, or use a custom nginx config.

### Task 2 — Readiness Probe Checking a File
Deploy a pod that starts as Not Ready because a required file doesn't exist:
```bash
cat > /tmp/devops-lab/1B-03/readiness.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: readiness-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: readiness-demo
  template:
    metadata:
      labels:
        app: readiness-demo
    spec:
      containers:
      - name: busybox
        image: busybox:1.35
        command: ["sh", "-c", "sleep 3600"]
        readinessProbe:
          exec:
            command: ["test", "-f", "/tmp/ready"]
          initialDelaySeconds: 2
          periodSeconds: 5
EOF
kubectl apply -f /tmp/devops-lab/1B-03/readiness.yaml
```

Wait a few seconds and observe the pod is Not Ready:
```bash
kubectl get pods -l app=readiness-demo
kubectl describe pod -l app=readiness-demo | grep -A5 "Conditions:" > /tmp/devops-lab/1B-03/not-ready.txt
```

### Task 3 — Make the Pod Ready
Exec into the pod and create the file the readiness probe is checking:
```bash
POD=$(kubectl get pod -l app=readiness-demo -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- touch /tmp/ready

# Wait ~10 seconds for probe to run, then verify
sleep 10
kubectl get pods -l app=readiness-demo
```

### Task 4 — Watch a Failing Liveness Probe Restart a Pod
Create a pod with a liveness probe that will definitely fail:
```bash
cat > /tmp/devops-lab/1B-03/failing-liveness.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: failing-liveness
spec:
  replicas: 1
  selector:
    matchLabels:
      app: failing-liveness
  template:
    metadata:
      labels:
        app: failing-liveness
    spec:
      containers:
      - name: busybox
        image: busybox:1.35
        command: ["sh", "-c", "sleep 3600"]
        livenessProbe:
          exec:
            command: ["test", "-f", "/tmp/alive"]
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 2
EOF
kubectl apply -f /tmp/devops-lab/1B-03/failing-liveness.yaml
```

Watch the pod restart counter increase:
```bash
# Watch for ~60 seconds
kubectl get pods -l app=failing-liveness -w &
WATCH_PID=$!
sleep 60
kill $WATCH_PID 2>/dev/null

kubectl describe pod -l app=failing-liveness | grep -E "Restart|Liveness|Events" -A3 \
  > /tmp/devops-lab/1B-03/restart-events.txt
```

---

## What Just Happened

- The readiness probe prevented the pod from receiving traffic until `/tmp/ready` existed
- Once you created the file, the probe succeeded and the pod became Ready
- The failing liveness probe caused Kubernetes to restart the container — you can see the restart count incrementing
- Liveness and readiness work independently — a pod can be alive (liveness passing) but not ready

---

## Interview Question

**"What's the difference between readiness and liveness? What happens if readiness is too aggressive?"**

Strong answer: Liveness determines if a container should be restarted; readiness determines if it should receive traffic. If readiness thresholds are too aggressive (failing after one slow response), pods get constantly removed from service load balancers during normal operation — causing traffic spikes on remaining pods, which then also fail readiness, cascading into an outage. Always tune `failureThreshold` and `periodSeconds` to match your app's normal latency patterns.
