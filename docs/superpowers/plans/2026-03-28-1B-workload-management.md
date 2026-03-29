# 1B Workload Management Exercises Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create 6 Kubernetes exercises (1B-01 through 1B-06) covering namespaces, resource limits, health checks, rolling updates, jobs/cronjobs, and debugging.

**Architecture:** Each exercise lives in `modules/01-kubernetes/1B-workload-management/NN-name/` with 4 files: `lesson.md`, `verify.sh`, `reset.sh`, `hint.md`. Verify scripts use the shared `check()` pattern. If minikube is not running, verify scripts check only file outputs and note cluster checks were skipped.

**Tech Stack:** bash, kubectl, Kubernetes (minikube), nginx container images

---

## File Map

Each of the 6 exercises creates exactly these 4 files:

| Exercise | Directory |
|----------|-----------|
| 01-namespaces | `modules/01-kubernetes/1B-workload-management/01-namespaces/` |
| 02-resource-limits | `modules/01-kubernetes/1B-workload-management/02-resource-limits/` |
| 03-health-checks | `modules/01-kubernetes/1B-workload-management/03-health-checks/` |
| 04-rolling-updates | `modules/01-kubernetes/1B-workload-management/04-rolling-updates/` |
| 05-jobs-cronjobs | `modules/01-kubernetes/1B-workload-management/05-jobs-cronjobs/` |
| 06-debugging | `modules/01-kubernetes/1B-workload-management/06-debugging/` |

Files per exercise: `lesson.md`, `verify.sh`, `reset.sh`, `hint.md`

---

## Reference Pattern

All verify.sh scripts follow:
```bash
#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1B-NN"
PASS=0; FAIL=0
check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}
echo "Verifying: <Exercise Name>"; echo ""
# ... checks ...
echo ""; echo "Results: $PASS passed, $FAIL failed"; [[ $FAIL -eq 0 ]]
```

For cluster checks, always wrap with:
```bash
if ! kubectl cluster-info &>/dev/null; then
  echo "  (skipped — minikube not running)"
else
  # cluster check here
fi
```

---

## Task 1: Exercise 01-namespaces

**Files:**
- Create: `modules/01-kubernetes/1B-workload-management/01-namespaces/lesson.md`
- Create: `modules/01-kubernetes/1B-workload-management/01-namespaces/verify.sh`
- Create: `modules/01-kubernetes/1B-workload-management/01-namespaces/reset.sh`
- Create: `modules/01-kubernetes/1B-workload-management/01-namespaces/hint.md`

- [ ] **Step 1: Write lesson.md**

File path: `modules/01-kubernetes/1B-workload-management/01-namespaces/lesson.md`

Content:
```markdown
# 1B-01: Namespaces

## Theory

Kubernetes **namespaces** are virtual clusters within a physical cluster. They provide a scope for names — two objects can share the same name as long as they live in different namespaces. Namespaces are the primary mechanism for resource isolation in multi-team environments: each team or environment (dev, staging, prod) gets its own namespace, keeping their resources separate and reducing blast radius from mistakes.

Kubernetes ships with four built-in namespaces: `default` (where resources land if you don't specify), `kube-system` (system components like CoreDNS and the API server), `kube-public` (readable by all users, mostly unused), and `kube-node-lease` (node heartbeat objects). You should never deploy workloads into `kube-system`. All your application namespaces are separate from these.

Within a cluster, services in one namespace can reach services in another using a **Fully Qualified Domain Name (FQDN)**: `<service>.<namespace>.svc.cluster.local`. This DNS resolution is provided by CoreDNS. Within the same namespace, just `<service>` suffices. Cross-namespace calls require the full path — a useful security boundary.

---

## Tasks

### Task 1: Create Namespaces

1. Create your work directory:
   ```bash
   mkdir -p /tmp/devops-lab/1B-01
   ```

2. Create two namespaces:
   ```bash
   kubectl create namespace dev
   kubectl create namespace staging
   ```

3. List all namespaces and save the output:
   ```bash
   kubectl get namespaces > /tmp/devops-lab/1B-01/namespaces.txt
   cat /tmp/devops-lab/1B-01/namespaces.txt
   ```

---

### Task 2: Deploy nginx in Each Namespace

1. Deploy nginx with 2 replicas in `dev`:
   ```bash
   kubectl create deployment nginx-dev --image=nginx:stable --replicas=2 -n dev
   kubectl expose deployment nginx-dev --port=80 --name=nginx-svc -n dev
   ```

2. Deploy nginx with 1 replica in `staging`:
   ```bash
   kubectl create deployment nginx-staging --image=nginx:stable --replicas=1 -n staging
   kubectl expose deployment nginx-staging --port=80 --name=nginx-svc -n staging
   ```

3. Wait for pods to be ready, then save pod lists:
   ```bash
   kubectl wait --for=condition=ready pod -l app=nginx-dev -n dev --timeout=60s
   kubectl get pods -n dev > /tmp/devops-lab/1B-01/pods-dev.txt
   kubectl get pods -n staging > /tmp/devops-lab/1B-01/pods-staging.txt
   ```

---

### Task 3: Cross-Namespace DNS Access

From a pod in `staging`, reach the `dev` service using its FQDN.

1. Run a temporary pod in `staging` and curl the `dev` service:
   ```bash
   kubectl run test-pod --image=curlimages/curl --restart=Never -n staging \
     --command -- curl -s http://nginx-svc.dev.svc.cluster.local
   ```

2. Wait for it to finish and save the output:
   ```bash
   kubectl wait --for=condition=complete pod/test-pod -n staging --timeout=30s
   kubectl logs test-pod -n staging > /tmp/devops-lab/1B-01/cross-ns.txt
   cat /tmp/devops-lab/1B-01/cross-ns.txt
   ```

---

### Task 4: Set Default Namespace to dev

1. Set your current context's default namespace to `dev`:
   ```bash
   kubectl config set-context --current --namespace=dev
   ```

2. Verify — `kubectl get pods` (no `-n` flag) should show only dev pods:
   ```bash
   kubectl get pods
   ```

3. Save the verification:
   ```bash
   kubectl get pods > /tmp/devops-lab/1B-01/default-ns-pods.txt
   cat /tmp/devops-lab/1B-01/default-ns-pods.txt
   ```

---

## Interview Question

**"How do namespaces help in a multi-team environment?"**

Namespaces give each team or environment its own isolated slice of the cluster. Teams can't accidentally modify each other's resources because names don't collide. You can apply `ResourceQuota` per namespace to cap CPU/memory usage per team. `NetworkPolicy` can restrict cross-namespace traffic. RBAC roles scoped to a namespace mean developers can have admin rights in `dev` but read-only in `prod`. It's not security isolation (a compromised pod can still talk to other namespaces unless NetworkPolicy blocks it), but it's excellent organizational isolation.

---

## What Just Happened

You created two separate namespaces that act as isolated workspaces within the same cluster. Pods in `dev` and `staging` run on the same nodes but are logically separated. CoreDNS made the cross-namespace call work by resolving `nginx-svc.dev.svc.cluster.local` to the ClusterIP of the `dev` service. Setting the default namespace means you don't need `-n dev` on every command — your context remembers it.
```

- [ ] **Step 2: Write verify.sh**

File path: `modules/01-kubernetes/1B-workload-management/01-namespaces/verify.sh`

Content:
```bash
#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1B-01"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Namespaces"
echo ""

# Check 1: namespaces.txt exists and contains dev and staging
if [[ -f "$WORK_DIR/namespaces.txt" ]]; then
  if grep -q "^dev" "$WORK_DIR/namespaces.txt" && grep -q "^staging" "$WORK_DIR/namespaces.txt"; then
    check "namespaces.txt lists dev and staging namespaces" "pass"
  else
    check "namespaces.txt should contain 'dev' and 'staging' entries" "fail"
  fi
else
  check "namespaces.txt exists in $WORK_DIR" "fail"
fi

# Check 2: pods-dev.txt shows 2 pods
if [[ -f "$WORK_DIR/pods-dev.txt" ]]; then
  pod_count=$(grep -c "nginx-dev" "$WORK_DIR/pods-dev.txt" 2>/dev/null || echo 0)
  if [[ "$pod_count" -ge 2 ]]; then
    check "pods-dev.txt shows 2 nginx pods in dev" "pass"
  else
    check "pods-dev.txt should show 2 nginx-dev pods (found $pod_count)" "fail"
  fi
else
  check "pods-dev.txt exists in $WORK_DIR" "fail"
fi

# Check 3: pods-staging.txt shows 1 pod
if [[ -f "$WORK_DIR/pods-staging.txt" ]]; then
  pod_count=$(grep -c "nginx-staging" "$WORK_DIR/pods-staging.txt" 2>/dev/null || echo 0)
  if [[ "$pod_count" -ge 1 ]]; then
    check "pods-staging.txt shows 1 nginx pod in staging" "pass"
  else
    check "pods-staging.txt should show 1 nginx-staging pod (found $pod_count)" "fail"
  fi
else
  check "pods-staging.txt exists in $WORK_DIR" "fail"
fi

# Check 4: cross-ns.txt has nginx HTML content
if [[ -f "$WORK_DIR/cross-ns.txt" ]]; then
  if grep -qi "welcome to nginx\|html\|<!DOCTYPE" "$WORK_DIR/cross-ns.txt"; then
    check "cross-ns.txt contains nginx response (cross-namespace DNS worked)" "pass"
  else
    check "cross-ns.txt should contain nginx HTML — did the curl succeed?" "fail"
  fi
else
  check "cross-ns.txt exists in $WORK_DIR" "fail"
fi

# Check 5: default-ns-pods.txt only has dev pods (no staging)
if [[ -f "$WORK_DIR/default-ns-pods.txt" ]]; then
  if grep -q "nginx-dev" "$WORK_DIR/default-ns-pods.txt" && ! grep -q "nginx-staging" "$WORK_DIR/default-ns-pods.txt"; then
    check "default-ns-pods.txt shows only dev namespace pods" "pass"
  else
    check "default-ns-pods.txt should show dev pods only — set context namespace to dev" "fail"
  fi
else
  check "default-ns-pods.txt exists in $WORK_DIR" "fail"
fi

# Cluster checks
if ! kubectl cluster-info &>/dev/null; then
  echo "  (cluster checks skipped — minikube not running)"
else
  # Check 6: dev namespace exists
  if kubectl get namespace dev &>/dev/null; then
    check "namespace 'dev' exists in cluster" "pass"
  else
    check "namespace 'dev' not found in cluster" "fail"
  fi

  # Check 7: staging namespace exists
  if kubectl get namespace staging &>/dev/null; then
    check "namespace 'staging' exists in cluster" "pass"
  else
    check "namespace 'staging' not found in cluster" "fail"
  fi

  # Check 8: current context namespace is dev
  current_ns=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
  if [[ "$current_ns" == "dev" ]]; then
    check "current context namespace is 'dev'" "pass"
  else
    check "current context namespace should be 'dev', got: '${current_ns:-default}'" "fail"
  fi
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
```

- [ ] **Step 3: Write reset.sh**

File path: `modules/01-kubernetes/1B-workload-management/01-namespaces/reset.sh`

Content:
```bash
#!/usr/bin/env bash
echo "Resetting: Namespaces exercise"

# Delete namespaces (this removes all resources within them)
kubectl delete namespace dev --ignore-not-found=true
kubectl delete namespace staging --ignore-not-found=true

# Reset context to default namespace
kubectl config set-context --current --namespace=default

# Clean work directory
rm -rf /tmp/devops-lab/1B-01
mkdir -p /tmp/devops-lab/1B-01

echo "Reset complete. Work directory: /tmp/devops-lab/1B-01"
```

- [ ] **Step 4: Write hint.md**

File path: `modules/01-kubernetes/1B-workload-management/01-namespaces/hint.md`

Content:
```markdown
## Hints

### Creating namespaces
- `kubectl create namespace <name>` or `kubectl create ns <name>`
- `kubectl get namespaces` (or `kubectl get ns`) lists all namespaces
- Redirect output: `kubectl get namespaces > /tmp/devops-lab/1B-01/namespaces.txt`

### Deploying to a specific namespace
- Always add `-n <namespace>` to your kubectl commands
- `kubectl create deployment nginx-dev --image=nginx:stable --replicas=2 -n dev`
- `kubectl expose deployment nginx-dev --port=80 --name=nginx-svc -n dev`
- Check pods: `kubectl get pods -n dev`

### Cross-namespace DNS
- FQDN format: `<service-name>.<namespace>.svc.cluster.local`
- So `nginx-svc` in `dev` is reachable at: `nginx-svc.dev.svc.cluster.local`
- Run a one-shot curl pod: `kubectl run test-pod --image=curlimages/curl --restart=Never -n staging --command -- curl -s http://nginx-svc.dev.svc.cluster.local`
- Wait for it: `kubectl wait --for=condition=complete pod/test-pod -n staging --timeout=30s`
- Get logs: `kubectl logs test-pod -n staging`

### Setting default namespace
- `kubectl config set-context --current --namespace=dev`
- After this, `kubectl get pods` shows pods from `dev` without needing `-n dev`
- Verify: `kubectl config view --minify | grep namespace`

### Common errors
- "Error from server (NotFound)" — you forgot `-n <namespace>`
- Pod stuck Pending — image pull issue, try `kubectl describe pod <name> -n <ns>`
- curl pod shows error — make sure the service exists: `kubectl get svc -n dev`
```

- [ ] **Step 5: Commit**

```bash
cd ~/devops-lab
git add modules/01-kubernetes/1B-workload-management/01-namespaces/
git commit -m "feat: add 1B-01 namespaces exercise"
```

---

## Task 2: Exercise 02-resource-limits

**Files:**
- Create: `modules/01-kubernetes/1B-workload-management/02-resource-limits/lesson.md`
- Create: `modules/01-kubernetes/1B-workload-management/02-resource-limits/verify.sh`
- Create: `modules/01-kubernetes/1B-workload-management/02-resource-limits/reset.sh`
- Create: `modules/01-kubernetes/1B-workload-management/02-resource-limits/hint.md`

- [ ] **Step 1: Write lesson.md**

File path: `modules/01-kubernetes/1B-workload-management/02-resource-limits/lesson.md`

Content:
```markdown
# 1B-02: Resource Limits

## Theory

Kubernetes distinguishes between **requests** and **limits** for CPU and memory. A **request** is what the scheduler uses to decide which node can fit your pod — it's a reservation. A **limit** is the ceiling the container cannot exceed. CPU is measured in **millicores** (1000m = 1 CPU core). Memory uses standard byte units (Mi, Gi). CPU is **compressible**: if a container exceeds its CPU limit, it gets throttled (slowed down). Memory is **incompressible**: if a container exceeds its memory limit, it gets OOM-killed (killed immediately by the kernel).

Kubernetes assigns every pod a **Quality of Service (QoS) class** based on its resource configuration. **Guaranteed** pods have requests == limits for all containers (most predictable, first protected during eviction). **Burstable** pods have at least one container with a request or limit set, but they aren't equal (can burst above requests up to limits). **BestEffort** pods have no requests or limits at all — they're the first to be evicted under memory pressure. QoS class directly affects scheduling priority and eviction order.

When you set resources too high (over-provisioning), you waste cluster capacity. Too low (under-provisioning) and pods get throttled or OOM-killed. The right approach is to **measure first** (`kubectl top pods`), then set requests slightly above observed usage and limits 2-3x requests. The `metrics-server` must be installed for `kubectl top` to work — in minikube, enable it with `minikube addons enable metrics-server`.

---

## Tasks

### Task 1: Create a Pod with Resource Limits

1. Create your work directory:
   ```bash
   mkdir -p /tmp/devops-lab/1B-02
   ```

2. Write the pod YAML with resource requests and limits:
   ```bash
   cat > /tmp/devops-lab/1B-02/resource-pod.yaml << 'EOF'
   apiVersion: v1
   kind: Pod
   metadata:
     name: resource-demo
     namespace: default
   spec:
     containers:
     - name: nginx
       image: nginx:stable
       resources:
         requests:
           cpu: "100m"
           memory: "64Mi"
         limits:
           cpu: "200m"
           memory: "128Mi"
   EOF
   ```

3. Apply the YAML:
   ```bash
   kubectl apply -f /tmp/devops-lab/1B-02/resource-pod.yaml
   kubectl wait --for=condition=ready pod/resource-demo --timeout=60s
   kubectl get pod resource-demo
   ```

---

### Task 2: Observe an Unschedulable Pod

1. Create a pod that requests more memory than any node has:
   ```bash
   kubectl run memory-hog --image=nginx:stable \
     --overrides='{"spec":{"containers":[{"name":"memory-hog","image":"nginx:stable","resources":{"requests":{"memory":"999Gi"}}}]}}' \
     --restart=Never
   ```

2. Watch it stay Pending — the scheduler can't find a node:
   ```bash
   kubectl get pod memory-hog
   kubectl describe pod memory-hog > /tmp/devops-lab/1B-02/pending-reason.txt
   cat /tmp/devops-lab/1B-02/pending-reason.txt | grep -A5 "Events:"
   ```

---

### Task 3: Observe Resource Metrics

> Note: Requires metrics-server. In minikube: `minikube addons enable metrics-server`
> Wait ~60s after enabling for data to appear.

1. Get pod and node metrics:
   ```bash
   kubectl top pods 2>/dev/null || echo "metrics-server not available"
   kubectl top nodes 2>/dev/null || echo "metrics-server not available"
   ```

2. Save output (even if metrics-server isn't available):
   ```bash
   {
     echo "=== Pod Metrics ==="
     kubectl top pods 2>/dev/null || echo "metrics-server not available — install with: minikube addons enable metrics-server"
     echo ""
     echo "=== Node Metrics ==="
     kubectl top nodes 2>/dev/null || echo "metrics-server not available"
   } > /tmp/devops-lab/1B-02/metrics.txt
   cat /tmp/devops-lab/1B-02/metrics.txt
   ```

---

### Task 4: Document QoS Classes

Write an explanation of all three QoS classes in your own words:
```bash
cat > /tmp/devops-lab/1B-02/qos-notes.txt << 'EOF'
Kubernetes QoS Classes:

Guaranteed:
- All containers have requests == limits for both CPU and memory
- Example: requests.cpu=200m, limits.cpu=200m; requests.memory=128Mi, limits.memory=128Mi
- These pods are the last to be evicted under memory pressure
- Use for: production workloads, databases, anything that can't tolerate interruption

Burstable:
- At least one container has CPU or memory request/limit set, but requests != limits
- Example: requests.cpu=100m, limits.cpu=500m (can burst up to 500m)
- Middle tier for eviction — evicted before BestEffort, after Guaranteed
- Use for: most application workloads where some variability is acceptable

BestEffort:
- No requests or limits set on any container
- First to be evicted under any memory pressure
- Scheduler places these pods on any available node with no guarantees
- Use for: batch jobs, non-critical background tasks that can be restarted

Check QoS class: kubectl get pod <name> -o jsonpath='{.status.qosClass}'
EOF
```

---

## Interview Question

**"What happens when a container exceeds its memory limit vs CPU limit?"**

CPU is compressible — the container gets **throttled** (its processes slow down) but keeps running. You'll see higher latency but no crash. Memory is incompressible — when a container exceeds its memory limit, the Linux kernel OOM-killer terminates it immediately. Kubernetes then restarts the container (incrementing the restart count). If this keeps happening, the pod enters `CrashLoopBackOff`. Repeated OOM kills signal that your limit is too low for your workload — either increase the limit or fix a memory leak.

---

## What Just Happened

You created a pod with explicit resource boundaries. The `memory-hog` pod demonstrates what happens when no node has enough capacity — the scheduler leaves it `Pending` and the `Events` section of `kubectl describe` tells you exactly why: "Insufficient memory." The QoS class (`kubectl get pod resource-demo -o jsonpath='{.status.qosClass}'`) for your resource-demo pod is `Burstable` because requests != limits.
```

- [ ] **Step 2: Write verify.sh**

File path: `modules/01-kubernetes/1B-workload-management/02-resource-limits/verify.sh`

Content:
```bash
#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1B-02"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Resource Limits"
echo ""

# Check 1: resource-pod.yaml exists and has limits
if [[ -f "$WORK_DIR/resource-pod.yaml" ]]; then
  if grep -q "limits" "$WORK_DIR/resource-pod.yaml" && grep -q "requests" "$WORK_DIR/resource-pod.yaml"; then
    check "resource-pod.yaml has both requests and limits" "pass"
  else
    check "resource-pod.yaml should contain both 'requests' and 'limits' sections" "fail"
  fi
else
  check "resource-pod.yaml exists in $WORK_DIR" "fail"
fi

# Check 2: resource-pod.yaml has correct values
if [[ -f "$WORK_DIR/resource-pod.yaml" ]]; then
  if grep -q "100m" "$WORK_DIR/resource-pod.yaml" && grep -q "64Mi" "$WORK_DIR/resource-pod.yaml"; then
    check "resource-pod.yaml has correct request values (100m cpu, 64Mi memory)" "pass"
  else
    check "resource-pod.yaml should have requests: cpu=100m, memory=64Mi" "fail"
  fi
fi

# Check 3: pending-reason.txt shows Pending/insufficient memory
if [[ -f "$WORK_DIR/pending-reason.txt" ]]; then
  if grep -qi "insufficient\|pending\|0/1 nodes\|didn't match" "$WORK_DIR/pending-reason.txt"; then
    check "pending-reason.txt documents unschedulable pod (insufficient resources)" "pass"
  else
    check "pending-reason.txt should show scheduling failure — did the memory-hog pod stay Pending?" "fail"
  fi
else
  check "pending-reason.txt exists in $WORK_DIR" "fail"
fi

# Check 4: metrics.txt exists
if [[ -f "$WORK_DIR/metrics.txt" ]]; then
  check "metrics.txt exists" "pass"
else
  check "metrics.txt exists in $WORK_DIR" "fail"
fi

# Check 5: qos-notes.txt covers all 3 QoS classes
if [[ -f "$WORK_DIR/qos-notes.txt" ]]; then
  has_guaranteed=$(grep -ci "guaranteed" "$WORK_DIR/qos-notes.txt")
  has_burstable=$(grep -ci "burstable" "$WORK_DIR/qos-notes.txt")
  has_besteffort=$(grep -ci "besteffort\|best.effort" "$WORK_DIR/qos-notes.txt")
  if [[ "$has_guaranteed" -ge 1 && "$has_burstable" -ge 1 && "$has_besteffort" -ge 1 ]]; then
    check "qos-notes.txt covers Guaranteed, Burstable, and BestEffort" "pass"
  else
    check "qos-notes.txt should mention Guaranteed, Burstable, and BestEffort" "fail"
  fi
else
  check "qos-notes.txt exists in $WORK_DIR" "fail"
fi

# Cluster checks
if ! kubectl cluster-info &>/dev/null; then
  echo "  (cluster checks skipped — minikube not running)"
else
  # Check 6: resource-demo pod is Running
  phase=$(kubectl get pod resource-demo -o jsonpath='{.status.phase}' 2>/dev/null)
  if [[ "$phase" == "Running" ]]; then
    check "resource-demo pod is Running" "pass"
  else
    check "resource-demo pod should be Running (got: ${phase:-not found})" "fail"
  fi

  # Check 7: resource-demo has correct limits
  cpu_limit=$(kubectl get pod resource-demo -o jsonpath='{.spec.containers[0].resources.limits.cpu}' 2>/dev/null)
  if [[ "$cpu_limit" == "200m" ]]; then
    check "resource-demo CPU limit is 200m" "pass"
  else
    check "resource-demo CPU limit should be 200m (got: ${cpu_limit:-not set})" "fail"
  fi

  # Check 8: memory-hog pod is Pending
  hog_phase=$(kubectl get pod memory-hog -o jsonpath='{.status.phase}' 2>/dev/null)
  if [[ "$hog_phase" == "Pending" ]]; then
    check "memory-hog pod is Pending (unschedulable)" "pass"
  else
    check "memory-hog pod should be Pending — it requests 999Gi memory (got: ${hog_phase:-not found})" "fail"
  fi
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
```

- [ ] **Step 3: Write reset.sh**

File path: `modules/01-kubernetes/1B-workload-management/02-resource-limits/reset.sh`

Content:
```bash
#!/usr/bin/env bash
echo "Resetting: Resource Limits exercise"

kubectl delete pod resource-demo --ignore-not-found=true
kubectl delete pod memory-hog --ignore-not-found=true

rm -rf /tmp/devops-lab/1B-02
mkdir -p /tmp/devops-lab/1B-02

echo "Reset complete. Work directory: /tmp/devops-lab/1B-02"
```

- [ ] **Step 4: Write hint.md**

File path: `modules/01-kubernetes/1B-workload-management/02-resource-limits/hint.md`

Content:
```markdown
## Hints

### Resource requests and limits
- `requests` = minimum reserved on the node (affects scheduling)
- `limits` = maximum the container can use (hard ceiling)
- CPU unit: `100m` = 100 millicores = 0.1 CPU
- Memory unit: `64Mi` = 64 mebibytes
- If you forget the units, K8s treats plain numbers as bytes (CPU) or bytes (memory)

### Writing the YAML
```yaml
resources:
  requests:
    cpu: "100m"
    memory: "64Mi"
  limits:
    cpu: "200m"
    memory: "128Mi"
```
Apply with: `kubectl apply -f /tmp/devops-lab/1B-02/resource-pod.yaml`

### Creating the memory-hog pod
The `--overrides` flag lets you inject arbitrary JSON into a `kubectl run`:
```bash
kubectl run memory-hog --image=nginx:stable \
  --overrides='{"spec":{"containers":[{"name":"memory-hog","image":"nginx:stable","resources":{"requests":{"memory":"999Gi"}}}]}}' \
  --restart=Never
```
It will stay in `Pending` because no node has 999Gi of memory.

### Finding why a pod is Pending
```bash
kubectl describe pod memory-hog
```
Look at the `Events:` section at the bottom — it will say something like:
`0/1 nodes are available: 1 Insufficient memory.`

### kubectl top not working?
Enable metrics-server in minikube:
```bash
minikube addons enable metrics-server
```
Wait about 60 seconds, then try `kubectl top pods` again.

### Checking QoS class
```bash
kubectl get pod resource-demo -o jsonpath='{.status.qosClass}'
```
Your resource-demo pod should be `Burstable` (requests != limits).
```

- [ ] **Step 5: Commit**

```bash
cd ~/devops-lab
git add modules/01-kubernetes/1B-workload-management/02-resource-limits/
git commit -m "feat: add 1B-02 resource-limits exercise"
```

---

## Task 3: Exercise 03-health-checks

**Files:**
- Create: `modules/01-kubernetes/1B-workload-management/03-health-checks/lesson.md`
- Create: `modules/01-kubernetes/1B-workload-management/03-health-checks/verify.sh`
- Create: `modules/01-kubernetes/1B-workload-management/03-health-checks/reset.sh`
- Create: `modules/01-kubernetes/1B-workload-management/03-health-checks/hint.md`

- [ ] **Step 1: Write lesson.md**

File path: `modules/01-kubernetes/1B-workload-management/03-health-checks/lesson.md`

Content:
```markdown
# 1B-03: Health Checks

## Theory

Kubernetes uses three types of **probes** to monitor container health. A **liveness probe** checks if the container is still alive — if it fails, Kubernetes kills and restarts the container. Use this for deadlock detection: a process that's running but completely stuck. A **readiness probe** checks if the container is ready to receive traffic — if it fails, the pod is removed from the Service's endpoint list but not restarted. Use this for startup delays and temporary unavailability (e.g., loading data into cache). A **startup probe** gives slow-starting containers extra time before liveness kicks in — it disables liveness/readiness until it succeeds.

Probes come in three flavors: **HTTP GET** (checks a URL, success = 2xx/3xx), **TCP socket** (checks if a port is open), and **exec** (runs a command inside the container, success = exit code 0). Each probe has configurable `initialDelaySeconds` (wait before first check), `periodSeconds` (how often), `failureThreshold` (how many failures before acting), and `successThreshold` (how many successes to go back to healthy).

A common mistake is setting liveness and readiness probes to the same endpoint with no delay — the container gets killed before it finishes starting up, creating a restart loop. Always set `initialDelaySeconds` generously and use a startup probe for applications with variable startup times. Aggressive readiness probes that temporarily fail under load will cause traffic shedding, which is often the right behavior but can amplify problems during high load.

---

## Tasks

### Task 1: Liveness Probe with HTTP

1. Create your work directory:
   ```bash
   mkdir -p /tmp/devops-lab/1B-03
   ```

2. Write a deployment with an HTTP liveness probe:
   ```bash
   cat > /tmp/devops-lab/1B-03/liveness.yaml << 'EOF'
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: liveness-demo
     namespace: default
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
           image: nginx:stable
           ports:
           - containerPort: 80
           livenessProbe:
             httpGet:
               path: /healthz
               port: 80
             initialDelaySeconds: 10
             periodSeconds: 10
             failureThreshold: 3
   EOF
   ```

3. Apply and wait:
   ```bash
   kubectl apply -f /tmp/devops-lab/1B-03/liveness.yaml
   kubectl rollout status deployment/liveness-demo --timeout=60s
   kubectl get pods -l app=liveness-demo
   ```

   > Note: `/healthz` doesn't exist in nginx, so this probe will eventually fail and restart the pod. That's intentional for Task 4.

---

### Task 2: Readiness Probe — Pod Starts Not Ready

1. Deploy a pod with a readiness probe that checks for a file:
   ```bash
   cat > /tmp/devops-lab/1B-03/readiness.yaml << 'EOF'
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: readiness-demo
     namespace: default
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
         - name: nginx
           image: nginx:stable
           readinessProbe:
             exec:
               command:
               - cat
               - /tmp/ready
             initialDelaySeconds: 5
             periodSeconds: 5
   EOF
   kubectl apply -f /tmp/devops-lab/1B-03/readiness.yaml
   ```

2. Wait briefly then check status — pod should show 0/1 Ready:
   ```bash
   sleep 15
   kubectl get pods -l app=readiness-demo
   kubectl get pods -l app=readiness-demo > /tmp/devops-lab/1B-03/not-ready.txt
   cat /tmp/devops-lab/1B-03/not-ready.txt
   ```

---

### Task 3: Make the Pod Ready

1. Exec into the pod and create the file the readiness probe checks:
   ```bash
   POD=$(kubectl get pods -l app=readiness-demo -o jsonpath='{.items[0].metadata.name}')
   kubectl exec "$POD" -- touch /tmp/ready
   ```

2. Wait for the pod to become Ready, then save the updated status:
   ```bash
   sleep 10
   kubectl get pods -l app=readiness-demo
   kubectl get pods -l app=readiness-demo > /tmp/devops-lab/1B-03/ready.txt
   cat /tmp/devops-lab/1B-03/ready.txt
   ```

---

### Task 4: Observe Liveness Restarts

The `liveness-demo` deployment probes `/healthz` which doesn't exist in nginx (returns 404). After `failureThreshold` failures, Kubernetes will restart the container.

1. Check restart count after a couple of minutes:
   ```bash
   kubectl get pods -l app=liveness-demo
   kubectl describe pod -l app=liveness-demo > /tmp/devops-lab/1B-03/restart-events.txt
   cat /tmp/devops-lab/1B-03/restart-events.txt | grep -A20 "Events:"
   ```

   You should see events like: `Liveness probe failed: HTTP probe failed with statuscode: 404`

2. If you don't want to wait, you can force a describe now and revisit:
   ```bash
   kubectl describe pod -l app=liveness-demo >> /tmp/devops-lab/1B-03/restart-events.txt
   ```

---

## Interview Question

**"When should you use readiness vs liveness? What if readiness probe is too aggressive?"**

Use **readiness** when your app needs time to warm up (loading configs, connecting to DB) or can temporarily become unavailable (upstream dependency down) — remove it from traffic without killing it. Use **liveness** when your app can get truly stuck in a way it can't self-recover from (deadlock, infinite loop) — kill it and let Kubernetes restart it fresh.

If readiness is too aggressive (low `failureThreshold`, short `periodSeconds`), it will flap under load. The pod gets removed from endpoints mid-request, existing connections break, and traffic routes to other pods — potentially overloading them and causing a cascade. The fix: increase `failureThreshold`, use `successThreshold > 1` to require multiple consecutive successes before marking ready, and ensure your health endpoint doesn't check downstream dependencies (only local health).

---

## What Just Happened

You saw two probes in action. The readiness probe kept the pod out of service rotation until the file existed — Kubernetes knew the pod wasn't ready to serve traffic and silently withheld it from Service endpoints. The liveness probe on `/healthz` failed because nginx doesn't have that route (returns 404), and after `failureThreshold` failures Kubernetes killed and restarted the container — you can see this in the `RESTARTS` column and in the Events section of `kubectl describe`.
```

- [ ] **Step 2: Write verify.sh**

File path: `modules/01-kubernetes/1B-workload-management/03-health-checks/verify.sh`

Content:
```bash
#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1B-03"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Health Checks"
echo ""

# Check 1: liveness.yaml exists and has livenessProbe
if [[ -f "$WORK_DIR/liveness.yaml" ]]; then
  if grep -q "livenessProbe" "$WORK_DIR/liveness.yaml" && grep -q "healthz" "$WORK_DIR/liveness.yaml"; then
    check "liveness.yaml has livenessProbe on /healthz" "pass"
  else
    check "liveness.yaml should have livenessProbe with httpGet on /healthz" "fail"
  fi
else
  check "liveness.yaml exists in $WORK_DIR" "fail"
fi

# Check 2: not-ready.txt shows 0/1 ready
if [[ -f "$WORK_DIR/not-ready.txt" ]]; then
  if grep -q "0/1" "$WORK_DIR/not-ready.txt"; then
    check "not-ready.txt shows pod at 0/1 (not ready)" "pass"
  else
    check "not-ready.txt should show 0/1 — readiness probe should be failing initially" "fail"
  fi
else
  check "not-ready.txt exists in $WORK_DIR" "fail"
fi

# Check 3: ready.txt shows 1/1 ready
if [[ -f "$WORK_DIR/ready.txt" ]]; then
  if grep -q "1/1" "$WORK_DIR/ready.txt"; then
    check "ready.txt shows pod at 1/1 (ready after file creation)" "pass"
  else
    check "ready.txt should show 1/1 — did you exec in and touch /tmp/ready?" "fail"
  fi
else
  check "ready.txt exists in $WORK_DIR" "fail"
fi

# Check 4: restart-events.txt mentions liveness or probe
if [[ -f "$WORK_DIR/restart-events.txt" ]]; then
  if grep -qi "liveness\|probe\|restart\|killing\|back-off" "$WORK_DIR/restart-events.txt"; then
    check "restart-events.txt documents liveness probe events" "pass"
  else
    check "restart-events.txt should show liveness probe events (may need to wait longer)" "fail"
  fi
else
  check "restart-events.txt exists in $WORK_DIR" "fail"
fi

# Cluster checks
if ! kubectl cluster-info &>/dev/null; then
  echo "  (cluster checks skipped — minikube not running)"
else
  # Check 5: readiness-demo pod is ready (1/1)
  ready=$(kubectl get pods -l app=readiness-demo -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
  if [[ "$ready" == "true" ]]; then
    check "readiness-demo pod is Ready (1/1)" "pass"
  else
    check "readiness-demo pod should be Ready — exec into it and touch /tmp/ready" "fail"
  fi

  # Check 6: liveness-demo has restart count > 0 (eventually)
  restarts=$(kubectl get pods -l app=liveness-demo -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}' 2>/dev/null || echo "0")
  if [[ "${restarts:-0}" -ge 1 ]]; then
    check "liveness-demo has restarted at least once (liveness probe failing as expected)" "pass"
  else
    echo "  (liveness restart check: $restarts restarts so far — may need a few minutes to accumulate)"
    check "liveness-demo deployment exists" "$(kubectl get deployment liveness-demo &>/dev/null && echo pass || echo fail)"
  fi
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
```

- [ ] **Step 3: Write reset.sh**

File path: `modules/01-kubernetes/1B-workload-management/03-health-checks/reset.sh`

Content:
```bash
#!/usr/bin/env bash
echo "Resetting: Health Checks exercise"

kubectl delete deployment liveness-demo readiness-demo --ignore-not-found=true

rm -rf /tmp/devops-lab/1B-03
mkdir -p /tmp/devops-lab/1B-03

echo "Reset complete. Work directory: /tmp/devops-lab/1B-03"
```

- [ ] **Step 4: Write hint.md**

File path: `modules/01-kubernetes/1B-workload-management/03-health-checks/hint.md`

Content:
```markdown
## Hints

### Liveness probe YAML structure
```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 80
  initialDelaySeconds: 10
  periodSeconds: 10
  failureThreshold: 3
```
Place this under `spec.containers[].` (same level as `image`, `ports`)

### Readiness probe with exec (file check)
```yaml
readinessProbe:
  exec:
    command:
    - cat
    - /tmp/ready
  initialDelaySeconds: 5
  periodSeconds: 5
```
This runs `cat /tmp/ready` inside the container. Exit 0 = ready, any other exit = not ready.

### Pod shows 0/1 — that's expected!
The readiness probe fails because `/tmp/ready` doesn't exist yet. This is the point of the exercise. The pod is running but not serving traffic.

### Making the pod Ready
```bash
# Get the pod name first
POD=$(kubectl get pods -l app=readiness-demo -o jsonpath='{.items[0].metadata.name}')
# Create the file the probe checks
kubectl exec "$POD" -- touch /tmp/ready
# Wait a few seconds for the next probe cycle, then check
kubectl get pods -l app=readiness-demo
```

### Viewing liveness probe failures
```bash
kubectl describe pod -l app=liveness-demo
```
Scroll to the bottom and look at `Events:` — you'll see entries like:
`Warning  Unhealthy  Liveness probe failed: HTTP probe failed with statuscode: 404`

After 3 consecutive failures (`failureThreshold: 3`), Kubernetes kills and restarts the container.

### Why does liveness fail?
nginx doesn't have a `/healthz` route by default. It returns 404, which Kubernetes treats as a probe failure. In production you'd implement a real health endpoint.
```

- [ ] **Step 5: Commit**

```bash
cd ~/devops-lab
git add modules/01-kubernetes/1B-workload-management/03-health-checks/
git commit -m "feat: add 1B-03 health-checks exercise"
```

---

## Task 4: Exercise 04-rolling-updates

**Files:**
- Create: `modules/01-kubernetes/1B-workload-management/04-rolling-updates/lesson.md`
- Create: `modules/01-kubernetes/1B-workload-management/04-rolling-updates/verify.sh`
- Create: `modules/01-kubernetes/1B-workload-management/04-rolling-updates/reset.sh`
- Create: `modules/01-kubernetes/1B-workload-management/04-rolling-updates/hint.md`

- [ ] **Step 1: Write lesson.md**

File path: `modules/01-kubernetes/1B-workload-management/04-rolling-updates/lesson.md`

Content:
```markdown
# 1B-04: Rolling Updates

## Theory

Kubernetes deployments use a **rolling update** strategy by default: it replaces pods incrementally, ensuring some capacity remains available throughout the update. Two parameters control the pace: `maxSurge` (how many extra pods can exist above the desired count during the update) and `maxUnavailable` (how many pods can be down at once). With `maxSurge=1, maxUnavailable=0`, Kubernetes starts one new pod, waits for it to become Ready, then terminates one old pod — zero downtime, at the cost of briefly using one extra pod's worth of resources.

Kubernetes tracks **rollout history** via revision numbers. Every `kubectl set image` or `kubectl apply` with a changed spec creates a new revision. You can view history with `kubectl rollout history deployment/<name>` and roll back to any previous revision with `kubectl rollout undo deployment/<name> --to-revision=N`. By default, `revisionHistoryLimit` is 10. If a new image can't be pulled or pods never become Ready, the rollout stalls — you'll see the old pods still running alongside the stuck new ones.

The alternatives to rolling updates are **blue-green** (run two full environments, switch traffic at once — instant cutover, double the cost) and **canary** (route a small percentage of traffic to the new version first, observe, then increase). Kubernetes natively supports rolling updates only; blue-green and canary require an Ingress controller or service mesh to manage traffic splitting.

---

## Tasks

### Task 1: Create a Deployment with Rolling Update Strategy

1. Create your work directory:
   ```bash
   mkdir -p /tmp/devops-lab/1B-04
   ```

2. Write the deployment YAML:
   ```bash
   cat > /tmp/devops-lab/1B-04/deploy.yaml << 'EOF'
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: rolling-demo
     namespace: default
   spec:
     replicas: 3
     strategy:
       type: RollingUpdate
       rollingUpdate:
         maxSurge: 1
         maxUnavailable: 0
     selector:
       matchLabels:
         app: rolling-demo
     template:
       metadata:
         labels:
           app: rolling-demo
       spec:
         containers:
         - name: nginx
           image: nginx:1.24
   EOF
   ```

3. Apply and wait for rollout:
   ```bash
   kubectl apply -f /tmp/devops-lab/1B-04/deploy.yaml
   kubectl rollout status deployment/rolling-demo --timeout=90s
   kubectl get pods -l app=rolling-demo
   ```

---

### Task 2: Update to nginx:1.25 and Watch Rollout

1. Update the image:
   ```bash
   kubectl set image deployment/rolling-demo nginx=nginx:1.25
   ```

2. Watch the rollout in real time:
   ```bash
   kubectl rollout status deployment/rolling-demo
   ```

3. Save the rollout status:
   ```bash
   {
     echo "=== Rollout Status ==="
     kubectl rollout status deployment/rolling-demo
     echo ""
     echo "=== Pods After Update ==="
     kubectl get pods -l app=rolling-demo
     echo ""
     echo "=== Current Image ==="
     kubectl get deployment rolling-demo -o jsonpath='{.spec.template.spec.containers[0].image}'
     echo ""
   } > /tmp/devops-lab/1B-04/rollout-log.txt
   cat /tmp/devops-lab/1B-04/rollout-log.txt
   ```

---

### Task 3: Trigger a Failed Rollout

1. Update to a non-existent image:
   ```bash
   kubectl set image deployment/rolling-demo nginx=nginx:nonexistent
   ```

2. Watch it stall (Ctrl+C after ~30s):
   ```bash
   kubectl rollout status deployment/rolling-demo --timeout=30s || true
   ```

3. Check pod state — some old pods still running, new one stuck:
   ```bash
   kubectl get pods -l app=rolling-demo
   kubectl describe pods -l app=rolling-demo | grep -A5 "Events:" | head -30
   ```

4. Save the failure evidence:
   ```bash
   {
     echo "=== Rollout Status (failed) ==="
     kubectl rollout status deployment/rolling-demo --timeout=10s 2>&1 || true
     echo ""
     echo "=== Pod Status ==="
     kubectl get pods -l app=rolling-demo
     echo ""
     echo "=== Events ==="
     kubectl get events --field-selector involvedObject.name=rolling-demo --sort-by='.lastTimestamp' | tail -10
   } > /tmp/devops-lab/1B-04/failed-rollout.txt
   cat /tmp/devops-lab/1B-04/failed-rollout.txt
   ```

---

### Task 4: Rollback and View History

1. Roll back to the previous revision:
   ```bash
   kubectl rollout undo deployment/rolling-demo
   kubectl rollout status deployment/rolling-demo --timeout=60s
   ```

2. View the full rollout history:
   ```bash
   kubectl rollout history deployment/rolling-demo > /tmp/devops-lab/1B-04/history.txt
   cat /tmp/devops-lab/1B-04/history.txt
   ```

   You should see at least 3 revisions (initial, nginx:1.25, nonexistent — undo returns to 1.25).

---

## Interview Question

**"Explain rolling update vs blue-green vs canary. Which does K8s support natively?"**

**Rolling update** (K8s native): pods replaced gradually, some old + some new run simultaneously. Zero-downtime if `maxUnavailable=0`. Risk: both versions handle traffic during transition, so your API must be backward-compatible.

**Blue-green**: two full environments exist. Switch all traffic at once (swap a Service selector or update DNS). Instant rollback (switch back). Cost: you need double the resources during deployment. K8s supports this pattern by hand — maintain two Deployments with different labels, update the Service selector.

**Canary**: route a small slice of traffic (e.g., 5%) to the new version. Observe error rates and latency. Incrementally increase. K8s alone can't do percentage-based routing — you need an Ingress controller (nginx, Traefik) with canary annotations or a service mesh (Istio, Linkerd).

---

## What Just Happened

The rolling update created a new pod with `nginx:1.25`, waited for it to pass readiness checks, then terminated one `nginx:1.24` pod — repeating until all were replaced. With `maxUnavailable=0`, you always had 3 ready pods serving traffic. The failed rollout with `nginx:nonexistent` stalled: the new pod couldn't pull the image (`ImagePullBackOff`), so K8s left the old pods running (keeping capacity). `kubectl rollout undo` re-applied the previous ReplicaSet and replaced the stuck pod.
```

- [ ] **Step 2: Write verify.sh**

File path: `modules/01-kubernetes/1B-workload-management/04-rolling-updates/verify.sh`

Content:
```bash
#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1B-04"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Rolling Updates"
echo ""

# Check 1: deploy.yaml has RollingUpdate strategy with correct values
if [[ -f "$WORK_DIR/deploy.yaml" ]]; then
  if grep -q "RollingUpdate" "$WORK_DIR/deploy.yaml" && \
     grep -q "maxSurge: 1" "$WORK_DIR/deploy.yaml" && \
     grep -q "maxUnavailable: 0" "$WORK_DIR/deploy.yaml"; then
    check "deploy.yaml has RollingUpdate strategy (maxSurge=1, maxUnavailable=0)" "pass"
  else
    check "deploy.yaml should have RollingUpdate with maxSurge: 1 and maxUnavailable: 0" "fail"
  fi
else
  check "deploy.yaml exists in $WORK_DIR" "fail"
fi

# Check 2: deploy.yaml starts with nginx:1.24
if [[ -f "$WORK_DIR/deploy.yaml" ]]; then
  if grep -q "nginx:1.24" "$WORK_DIR/deploy.yaml"; then
    check "deploy.yaml uses nginx:1.24 as initial image" "pass"
  else
    check "deploy.yaml should use nginx:1.24 as initial image" "fail"
  fi
fi

# Check 3: rollout-log.txt shows successful rollout
if [[ -f "$WORK_DIR/rollout-log.txt" ]]; then
  if grep -qi "successfully rolled out\|complete\|1.25" "$WORK_DIR/rollout-log.txt"; then
    check "rollout-log.txt shows successful rollout to nginx:1.25" "pass"
  else
    check "rollout-log.txt should show successful rollout status" "fail"
  fi
else
  check "rollout-log.txt exists in $WORK_DIR" "fail"
fi

# Check 4: failed-rollout.txt shows failure
if [[ -f "$WORK_DIR/failed-rollout.txt" ]]; then
  if grep -qi "error\|waiting\|imagepull\|nonexistent\|timed out\|not progressing" "$WORK_DIR/failed-rollout.txt"; then
    check "failed-rollout.txt documents the failed rollout" "pass"
  else
    check "failed-rollout.txt should show rollout failure (ImagePullBackOff or timeout)" "fail"
  fi
else
  check "failed-rollout.txt exists in $WORK_DIR" "fail"
fi

# Check 5: history.txt has multiple revisions
if [[ -f "$WORK_DIR/history.txt" ]]; then
  revision_count=$(grep -c "^[0-9]" "$WORK_DIR/history.txt" 2>/dev/null || echo 0)
  if [[ "$revision_count" -ge 3 ]]; then
    check "history.txt shows $revision_count revisions (3+ expected)" "pass"
  else
    check "history.txt should show 3+ revisions (found $revision_count)" "fail"
  fi
else
  check "history.txt exists in $WORK_DIR" "fail"
fi

# Cluster checks
if ! kubectl cluster-info &>/dev/null; then
  echo "  (cluster checks skipped — minikube not running)"
else
  # Check 6: rolling-demo deployment is fully available
  available=$(kubectl get deployment rolling-demo -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo 0)
  desired=$(kubectl get deployment rolling-demo -o jsonpath='{.spec.replicas}' 2>/dev/null || echo 3)
  if [[ "${available:-0}" -eq "${desired:-3}" ]]; then
    check "rolling-demo deployment is fully available ($available/$desired replicas)" "pass"
  else
    check "rolling-demo should have all replicas available (got $available/$desired)" "fail"
  fi

  # Check 7: current image is NOT nginx:nonexistent (rollback happened)
  current_image=$(kubectl get deployment rolling-demo -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
  if [[ "$current_image" != "nginx:nonexistent" ]]; then
    check "rolling-demo rolled back from nginx:nonexistent (current: $current_image)" "pass"
  else
    check "rolling-demo is still on nginx:nonexistent — run: kubectl rollout undo deployment/rolling-demo" "fail"
  fi
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
```

- [ ] **Step 3: Write reset.sh**

File path: `modules/01-kubernetes/1B-workload-management/04-rolling-updates/reset.sh`

Content:
```bash
#!/usr/bin/env bash
echo "Resetting: Rolling Updates exercise"

kubectl delete deployment rolling-demo --ignore-not-found=true

rm -rf /tmp/devops-lab/1B-04
mkdir -p /tmp/devops-lab/1B-04

echo "Reset complete. Work directory: /tmp/devops-lab/1B-04"
```

- [ ] **Step 4: Write hint.md**

File path: `modules/01-kubernetes/1B-workload-management/04-rolling-updates/hint.md`

Content:
```markdown
## Hints

### Rolling update strategy in YAML
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
```
This goes under `spec:` of the Deployment (same level as `replicas`).

### Updating an image
```bash
kubectl set image deployment/<name> <container-name>=<new-image>
```
The container name is whatever you put in `spec.template.spec.containers[].name`.
For this exercise: `kubectl set image deployment/rolling-demo nginx=nginx:1.25`

### Watching a rollout
```bash
kubectl rollout status deployment/rolling-demo
```
This blocks until complete or times out. Add `--timeout=60s` to not wait forever.

### Triggering a failed rollout
```bash
kubectl set image deployment/rolling-demo nginx=nginx:nonexistent
```
Watch with `kubectl get pods -w` — you'll see the new pod stuck in `ImagePullBackOff` while old pods stay Running (K8s won't kill them until new pods are Ready).

### Rolling back
```bash
# Undo last change
kubectl rollout undo deployment/rolling-demo

# Undo to a specific revision
kubectl rollout undo deployment/rolling-demo --to-revision=2
```

### Viewing rollout history
```bash
kubectl rollout history deployment/rolling-demo
# Show details of a specific revision:
kubectl rollout history deployment/rolling-demo --revision=2
```

### Stuck rollout — how to diagnose
```bash
kubectl get pods -l app=rolling-demo      # look for ImagePullBackOff
kubectl describe pod <stuck-pod-name>     # check Events section
kubectl get events --sort-by='.lastTimestamp' | tail -10
```
```

- [ ] **Step 5: Commit**

```bash
cd ~/devops-lab
git add modules/01-kubernetes/1B-workload-management/04-rolling-updates/
git commit -m "feat: add 1B-04 rolling-updates exercise"
```

---

## Task 5: Exercise 05-jobs-cronjobs

**Files:**
- Create: `modules/01-kubernetes/1B-workload-management/05-jobs-cronjobs/lesson.md`
- Create: `modules/01-kubernetes/1B-workload-management/05-jobs-cronjobs/verify.sh`
- Create: `modules/01-kubernetes/1B-workload-management/05-jobs-cronjobs/reset.sh`
- Create: `modules/01-kubernetes/1B-workload-management/05-jobs-cronjobs/hint.md`

- [ ] **Step 1: Write lesson.md**

File path: `modules/01-kubernetes/1B-workload-management/05-jobs-cronjobs/lesson.md`

Content:
```markdown
# 1B-05: Jobs and CronJobs

## Theory

A Kubernetes **Job** runs one or more pods to completion — unlike Deployments, which keep pods running indefinitely. When all pods complete successfully, the Job is done. Jobs are for batch work: database migrations, report generation, data processing, one-off scripts. Key parameters: `completions` (total successful completions needed, default 1) and `parallelism` (how many pods run simultaneously). With `completions=5, parallelism=2`, K8s runs 2 pods at a time until 5 total complete.

A **CronJob** is a Job factory that creates Jobs on a schedule using standard cron syntax (`* * * * *` = minute, hour, day-of-month, month, day-of-week). A CronJob doesn't run pods directly — it creates a Job at each scheduled time, and that Job runs pods. The `concurrencyPolicy` field controls what happens if a previous run hasn't finished: `Allow` (run both), `Forbid` (skip new run), or `Replace` (cancel old, start new). The default is `Allow`, which can cause pile-up for long-running jobs.

Job pods don't get deleted automatically — they stay around so you can inspect their logs. Old completed Job pods accumulate. Control retention with `ttlSecondsAfterFinished` on the Job (auto-delete after N seconds). CronJobs have `successfulJobsHistoryLimit` (default 3) and `failedJobsHistoryLimit` (default 1) to keep a fixed number of past job records.

---

## Tasks

### Task 1: Create a Simple Job

1. Create your work directory:
   ```bash
   mkdir -p /tmp/devops-lab/1B-05
   ```

2. Write a Job that echoes a message:
   ```bash
   cat > /tmp/devops-lab/1B-05/job.yaml << 'EOF'
   apiVersion: batch/v1
   kind: Job
   metadata:
     name: hello-job
   spec:
     template:
       spec:
         restartPolicy: Never
         containers:
         - name: hello
           image: busybox:stable
           command: ["sh", "-c", "echo 'Hello from K8s Job' && date"]
   EOF
   ```

3. Apply and wait for completion:
   ```bash
   kubectl apply -f /tmp/devops-lab/1B-05/job.yaml
   kubectl wait --for=condition=complete job/hello-job --timeout=60s
   ```

4. Check the output:
   ```bash
   kubectl logs -l job-name=hello-job
   kubectl get job hello-job
   ```

---

### Task 2: Parallel Job with Multiple Completions

1. Create a Job that must complete 3 times, running 2 pods in parallel:
   ```bash
   cat > /tmp/devops-lab/1B-05/parallel-job.yaml << 'EOF'
   apiVersion: batch/v1
   kind: Job
   metadata:
     name: parallel-job
   spec:
     completions: 3
     parallelism: 2
     template:
       spec:
         restartPolicy: Never
         containers:
         - name: worker
           image: busybox:stable
           command: ["sh", "-c", "echo 'Worker $HOSTNAME running'; sleep 2; echo 'Worker done'"]
   EOF
   kubectl apply -f /tmp/devops-lab/1B-05/parallel-job.yaml
   ```

2. Watch pods as they run:
   ```bash
   kubectl get pods -l job-name=parallel-job -w &
   WATCH_PID=$!
   kubectl wait --for=condition=complete job/parallel-job --timeout=90s
   kill $WATCH_PID 2>/dev/null
   ```

3. Save the pod status showing all completions:
   ```bash
   kubectl get pods -l job-name=parallel-job > /tmp/devops-lab/1B-05/parallel-jobs.txt
   kubectl get job parallel-job >> /tmp/devops-lab/1B-05/parallel-jobs.txt
   cat /tmp/devops-lab/1B-05/parallel-jobs.txt
   ```

---

### Task 3: Create a CronJob

1. Write a CronJob that runs every minute:
   ```bash
   cat > /tmp/devops-lab/1B-05/cronjob.yaml << 'EOF'
   apiVersion: batch/v1
   kind: CronJob
   metadata:
     name: date-printer
   spec:
     schedule: "* * * * *"
     successfulJobsHistoryLimit: 3
     failedJobsHistoryLimit: 1
     jobTemplate:
       spec:
         template:
           spec:
             restartPolicy: OnFailure
             containers:
             - name: date-writer
               image: busybox:stable
               command: ["sh", "-c", "echo \"CronJob ran at: $(date)\""]
   EOF
   kubectl apply -f /tmp/devops-lab/1B-05/cronjob.yaml
   ```

2. Wait for the first execution (up to 90 seconds):
   ```bash
   echo "Waiting for CronJob to execute (up to 90s)..."
   for i in $(seq 1 18); do
     count=$(kubectl get jobs -l app!=rolling-demo 2>/dev/null | grep "date-printer" | wc -l)
     if [[ "$count" -ge 1 ]]; then
       echo "CronJob executed!"
       break
     fi
     sleep 5
   done
   kubectl get cronjob date-printer
   kubectl get jobs | grep date-printer
   ```

---

### Task 4: Document Job Use Cases

```bash
cat > /tmp/devops-lab/1B-05/job-usecases.txt << 'EOF'
Job vs CronJob Use Cases:

JOB use cases (one-off tasks):
1. Database migration: Run schema migrations before deploying a new app version.
   One execution needed, exit 0 = success, don't restart on completion.
2. Data import: Load a large CSV into a database at application launch.
   parallelism=N can split the work across multiple pods.
3. Index rebuild: Rebuild a search index after bulk data changes.
   Run once, check logs, done.

CRONJOB use cases (scheduled recurring tasks):
1. Nightly backup: Run `pg_dump` every night at 2am and upload to S3.
   schedule: "0 2 * * *"
2. Cache warming: Pre-populate application cache every 30 minutes.
   schedule: "*/30 * * * *"
3. Report generation: Generate weekly analytics reports every Monday morning.
   schedule: "0 9 * * 1"

Key decision: if it needs to happen ONCE → Job. If it needs to happen REPEATEDLY on a schedule → CronJob.
EOF
```

---

## Interview Question

**"What if a CronJob's previous run hasn't finished when the next one triggers?"**

Controlled by `concurrencyPolicy`:
- **Allow** (default): Both runs execute simultaneously. Can cause resource contention and data conflicts if they write to the same place.
- **Forbid**: The new run is skipped entirely. Safe but you may miss executions if jobs consistently run longer than their interval.
- **Replace**: The running job is cancelled and a new one starts. Good for idempotent jobs where "run most recent version" matters more than completing every run.

For most production use cases, `Forbid` is the safest choice combined with alerting if jobs start getting skipped. Always instrument your jobs with metrics — silent skipped runs are invisible failures.

---

## What Just Happened

The simple Job ran a pod to completion and the pod stays in `Completed` state (not deleted) so you can inspect the logs later. The parallel Job ran 2 pods simultaneously, tracked completions, and triggered the third pod after one of the first two finished — all orchestrated by the Job controller. The CronJob created a new Job object every minute; the Job then created a pod. You can see this hierarchy: CronJob → Job → Pod.
```

- [ ] **Step 2: Write verify.sh**

File path: `modules/01-kubernetes/1B-workload-management/05-jobs-cronjobs/verify.sh`

Content:
```bash
#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1B-05"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Jobs and CronJobs"
echo ""

# Check 1: job.yaml exists and has correct structure
if [[ -f "$WORK_DIR/job.yaml" ]]; then
  if grep -q "kind: Job" "$WORK_DIR/job.yaml" && grep -q "Hello from K8s Job" "$WORK_DIR/job.yaml"; then
    check "job.yaml is a Job manifest with correct echo command" "pass"
  else
    check "job.yaml should be a Job manifest with 'Hello from K8s Job' command" "fail"
  fi
else
  check "job.yaml exists in $WORK_DIR" "fail"
fi

# Check 2: parallel-jobs.txt shows 3 completed pods
if [[ -f "$WORK_DIR/parallel-jobs.txt" ]]; then
  completed_count=$(grep -c "Completed" "$WORK_DIR/parallel-jobs.txt" 2>/dev/null || echo 0)
  if [[ "$completed_count" -ge 3 ]]; then
    check "parallel-jobs.txt shows 3 completed pods" "pass"
  else
    # Check if job shows 3/3 completions
    if grep -q "3/3\|3 Completed" "$WORK_DIR/parallel-jobs.txt" 2>/dev/null; then
      check "parallel-jobs.txt shows 3/3 job completions" "pass"
    else
      check "parallel-jobs.txt should show 3 completed pods (found $completed_count Completed entries)" "fail"
    fi
  fi
else
  check "parallel-jobs.txt exists in $WORK_DIR" "fail"
fi

# Check 3: cronjob.yaml exists and has correct schedule
if [[ -f "$WORK_DIR/cronjob.yaml" ]]; then
  if grep -q "kind: CronJob" "$WORK_DIR/cronjob.yaml" && grep -q '"* * * * *"' "$WORK_DIR/cronjob.yaml"; then
    check "cronjob.yaml is a CronJob with every-minute schedule" "pass"
  else
    check "cronjob.yaml should be a CronJob with schedule: \"* * * * *\"" "fail"
  fi
else
  check "cronjob.yaml exists in $WORK_DIR" "fail"
fi

# Check 4: job-usecases.txt covers Job and CronJob examples
if [[ -f "$WORK_DIR/job-usecases.txt" ]]; then
  has_job=$(grep -ci "^.*job\b" "$WORK_DIR/job-usecases.txt" 2>/dev/null || echo 0)
  has_cron=$(grep -ci "cronjob\|cron" "$WORK_DIR/job-usecases.txt" 2>/dev/null || echo 0)
  has_examples=$(grep -c "[0-9]\." "$WORK_DIR/job-usecases.txt" 2>/dev/null || echo 0)
  if [[ "$has_job" -ge 1 && "$has_cron" -ge 1 && "$has_examples" -ge 3 ]]; then
    check "job-usecases.txt covers Job and CronJob with 3+ examples" "pass"
  else
    check "job-usecases.txt should have Job and CronJob examples (3+ numbered items)" "fail"
  fi
else
  check "job-usecases.txt exists in $WORK_DIR" "fail"
fi

# Cluster checks
if ! kubectl cluster-info &>/dev/null; then
  echo "  (cluster checks skipped — minikube not running)"
else
  # Check 5: hello-job completed
  job_status=$(kubectl get job hello-job -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' 2>/dev/null)
  if [[ "$job_status" == "True" ]]; then
    check "hello-job completed successfully" "pass"
  else
    check "hello-job should show Complete=True (got: ${job_status:-not found})" "fail"
  fi

  # Check 6: parallel-job had 3 completions
  completions=$(kubectl get job parallel-job -o jsonpath='{.status.succeeded}' 2>/dev/null || echo 0)
  if [[ "${completions:-0}" -ge 3 ]]; then
    check "parallel-job had $completions successful completions (3 required)" "pass"
  else
    check "parallel-job should have 3 successful completions (got: ${completions:-0})" "fail"
  fi

  # Check 7: CronJob exists and has run at least once
  cj_exists=$(kubectl get cronjob date-printer &>/dev/null && echo yes || echo no)
  if [[ "$cj_exists" == "yes" ]]; then
    check "date-printer CronJob exists" "pass"
    last_schedule=$(kubectl get cronjob date-printer -o jsonpath='{.status.lastScheduleTime}' 2>/dev/null)
    if [[ -n "$last_schedule" ]]; then
      check "date-printer CronJob has been scheduled at least once" "pass"
    else
      check "date-printer CronJob hasn't run yet — wait up to 60s and retry" "fail"
    fi
  else
    check "date-printer CronJob exists" "fail"
  fi
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
```

- [ ] **Step 3: Write reset.sh**

File path: `modules/01-kubernetes/1B-workload-management/05-jobs-cronjobs/reset.sh`

Content:
```bash
#!/usr/bin/env bash
echo "Resetting: Jobs and CronJobs exercise"

kubectl delete job hello-job parallel-job --ignore-not-found=true
kubectl delete cronjob date-printer --ignore-not-found=true
# Clean up any completed cronjob pods
kubectl delete jobs -l app!=rolling-demo --ignore-not-found=true 2>/dev/null || true

rm -rf /tmp/devops-lab/1B-05
mkdir -p /tmp/devops-lab/1B-05

echo "Reset complete. Work directory: /tmp/devops-lab/1B-05"
```

- [ ] **Step 4: Write hint.md**

File path: `modules/01-kubernetes/1B-workload-management/05-jobs-cronjobs/hint.md`

Content:
```markdown
## Hints

### Job YAML structure
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: hello-job
spec:
  template:
    spec:
      restartPolicy: Never   # Required! Jobs must have Never or OnFailure (not Always)
      containers:
      - name: hello
        image: busybox:stable
        command: ["sh", "-c", "echo 'Hello from K8s Job'"]
```

### Waiting for a Job to complete
```bash
kubectl wait --for=condition=complete job/hello-job --timeout=60s
```
Then check logs: `kubectl logs -l job-name=hello-job`

### Parallel Job settings
`completions: 3` = need 3 total successful pod completions
`parallelism: 2` = run up to 2 pods at once
With these settings: 2 pods start, when 1 finishes, a 3rd starts (to reach 3 total).

### CronJob schedule format
```
* * * * *
│ │ │ │ └── Day of week (0-7, 0=Sunday)
│ │ │ └──── Month (1-12)
│ │ └────── Day of month (1-31)
│ └──────── Hour (0-23)
└────────── Minute (0-59)
```
`* * * * *` = every minute
`0 2 * * *` = 2am every day
`*/5 * * * *` = every 5 minutes

### Viewing CronJob-created Jobs
```bash
kubectl get jobs
kubectl get cronjob date-printer
```
CronJob creates Job objects which create pods.

### Watching job completion
```bash
kubectl get pods -l job-name=parallel-job -w
```
Press Ctrl+C to stop watching.

### Why restartPolicy: Never vs OnFailure?
- `Never`: if a pod fails, K8s creates a NEW pod (keeps records of all attempts)
- `OnFailure`: if a pod fails, K8s restarts the SAME pod (single pod, retried in-place)
- `Always`: not allowed for Jobs (that's for Deployments)
```

- [ ] **Step 5: Commit**

```bash
cd ~/devops-lab
git add modules/01-kubernetes/1B-workload-management/05-jobs-cronjobs/
git commit -m "feat: add 1B-05 jobs-cronjobs exercise"
```

---

## Task 6: Exercise 06-debugging

**Files:**
- Create: `modules/01-kubernetes/1B-workload-management/06-debugging/lesson.md`
- Create: `modules/01-kubernetes/1B-workload-management/06-debugging/verify.sh`
- Create: `modules/01-kubernetes/1B-workload-management/06-debugging/reset.sh`
- Create: `modules/01-kubernetes/1B-workload-management/06-debugging/hint.md`

- [ ] **Step 1: Write lesson.md**

File path: `modules/01-kubernetes/1B-workload-management/06-debugging/lesson.md`

Content:
```markdown
# 1B-06: Debugging Kubernetes Workloads

## Theory

Debugging in Kubernetes is systematic: you work outward from the symptom to the cause. The primary tool is `kubectl describe` — it shows current state, conditions, and crucially the **Events** section which captures what Kubernetes has tried and why it failed. `kubectl logs` gives you the container's stdout/stderr. For pods that won't start, `kubectl logs --previous` gets logs from the last crashed container. For running pods, `kubectl exec` drops you into a shell to inspect the environment directly.

The most common failure modes map to recognizable states. **ImagePullBackOff** (also **ErrImagePull**): image doesn't exist, wrong tag, or registry credentials missing. **CrashLoopBackOff**: container starts but immediately exits — check logs for the actual error; the "BackOff" just means K8s is adding increasing delay between restart attempts. **Pending**: pod can't be scheduled — usually insufficient node resources (check `kubectl describe pod` Events) or a missing PVC. **Evicted**: node ran out of memory or disk and evicted the pod — check if requests/limits are set. **0/1 Running**: pod is up but not passing readiness probe.

Service connectivity failures are trickier because the pod may be healthy but unreachable. The cause is almost always a **selector mismatch**: the Service's `selector` doesn't match the pod's `labels`. Check with `kubectl get endpoints <svc>` — if it shows `<none>`, no pods matched. Compare `kubectl get svc <svc> -o yaml` (look at `spec.selector`) with `kubectl get pods --show-labels` (look at actual labels). One character difference breaks the match.

---

## Setup Note

The `reset.sh` for this exercise creates the three broken deployments for you to diagnose. Run `reset.sh` before starting the tasks.

---

## Tasks

### Task 0: Set Up the Broken Environment

Run reset first to create the broken deployments:
```bash
bash ~/devops-lab/modules/01-kubernetes/1B-workload-management/06-debugging/reset.sh
```

---

### Task 1: Diagnose and Fix broken-image

1. Create your work directory:
   ```bash
   mkdir -p /tmp/devops-lab/1B-06
   ```

2. Check what's wrong:
   ```bash
   kubectl get pods -l app=broken-image
   kubectl describe pod -l app=broken-image | tail -30
   ```
   You'll see `ImagePullBackOff` — look at Events for the image name.

3. Write your diagnosis:
   ```bash
   cat > /tmp/devops-lab/1B-06/issue1.txt << 'EOF'
   Issue: ImagePullBackOff
   Cause: Deployment uses image nginx:99.99.99 which does not exist in Docker Hub.
   Evidence: Events show "Failed to pull image nginx:99.99.99: not found"
   Fix: Update the deployment to use a valid image tag (e.g., nginx:stable)
   EOF
   ```

4. Fix the deployment:
   ```bash
   kubectl set image deployment/broken-image nginx=nginx:stable
   kubectl rollout status deployment/broken-image --timeout=60s
   kubectl get pods -l app=broken-image
   ```

---

### Task 2: Diagnose and Fix broken-probe

1. Check what's wrong:
   ```bash
   kubectl get pods -l app=broken-probe
   kubectl describe pod -l app=broken-probe | tail -40
   ```
   You'll see restarts and liveness probe failures.

2. Check the probe configuration:
   ```bash
   kubectl get deployment broken-probe -o yaml | grep -A10 "livenessProbe:"
   ```

3. Write your diagnosis:
   ```bash
   cat > /tmp/devops-lab/1B-06/issue2.txt << 'EOF'
   Issue: CrashLoopBackOff / repeated restarts
   Cause: Liveness probe checks port 9999, but nginx listens on port 80.
          Probe always fails -> K8s kills container -> restart -> repeat.
   Evidence: describe shows "Liveness probe failed: Get http://....:9999/: connection refused"
   Fix: Update livenessProbe port from 9999 to 80
   EOF
   ```

4. Fix the deployment (patch the liveness probe port):
   ```bash
   kubectl patch deployment broken-probe --type='json' \
     -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/livenessProbe/httpGet/port", "value": 80}]'
   kubectl rollout status deployment/broken-probe --timeout=60s
   kubectl get pods -l app=broken-probe
   ```

---

### Task 3: Diagnose and Fix broken-selector

1. Check what's wrong:
   ```bash
   kubectl get pods -l app=broken-selector
   kubectl get svc broken-selector-svc
   kubectl get endpoints broken-selector-svc
   ```
   The endpoints will show `<none>`.

2. Compare service selector vs pod labels:
   ```bash
   echo "Service selector:"
   kubectl get svc broken-selector-svc -o jsonpath='{.spec.selector}' && echo ""
   echo "Pod labels:"
   kubectl get pods -l app=broken-selector --show-labels
   ```

3. Write your diagnosis:
   ```bash
   cat > /tmp/devops-lab/1B-06/issue3.txt << 'EOF'
   Issue: Service has no endpoints (kubectl get endpoints shows <none>)
   Cause: Service selector uses label "app: broken-slector" (typo: missing 'e')
          but pods have label "app: broken-selector" (correct spelling).
          Selector mismatch = no pods match = no endpoints.
   Evidence: kubectl get endpoints broken-selector-svc shows <none>
   Fix: Patch service selector to match correct pod label "app: broken-selector"
   EOF
   ```

4. Fix the service selector:
   ```bash
   kubectl patch svc broken-selector-svc --type='json' \
     -p='[{"op": "replace", "path": "/spec/selector/app", "value": "broken-selector"}]'
   kubectl get endpoints broken-selector-svc
   ```

---

### Task 4: Verify All Services Are Reachable

1. Run a debug pod and curl each fixed service:
   ```bash
   kubectl run debug-pod --image=curlimages/curl --restart=Never \
     --command -- sleep 120
   kubectl wait --for=condition=ready pod/debug-pod --timeout=30s
   ```

2. Curl each service from inside the cluster:
   ```bash
   {
     echo "=== Testing broken-image (now fixed) ==="
     kubectl exec debug-pod -- curl -s --max-time 5 http://broken-image-svc/ | head -3 || echo "FAILED"
     echo ""
     echo "=== Testing broken-probe (now fixed) ==="
     kubectl exec debug-pod -- curl -s --max-time 5 http://broken-probe-svc/ | head -3 || echo "FAILED"
     echo ""
     echo "=== Testing broken-selector (now fixed) ==="
     kubectl exec debug-pod -- curl -s --max-time 5 http://broken-selector-svc/ | head -3 || echo "FAILED"
   } > /tmp/devops-lab/1B-06/connectivity.txt
   cat /tmp/devops-lab/1B-06/connectivity.txt
   ```

3. Clean up debug pod:
   ```bash
   kubectl delete pod debug-pod --ignore-not-found=true
   ```

---

## Interview Question

**"Pod stuck in CrashLoopBackOff. Walk through debugging steps."**

1. `kubectl get pods` — confirm it's in CrashLoopBackOff, note restart count
2. `kubectl logs <pod>` — see why it crashed (the actual error message)
3. `kubectl logs --previous <pod>` — if the pod restarted, get logs from the crashed instance
4. `kubectl describe pod <pod>` — check Events (probe failures, OOM kills, image errors) and resource limits
5. Check if it's a liveness probe issue: probe failing before app is ready (`initialDelaySeconds` too low?)
6. Check if it's OOM: `kubectl describe node` shows recent OOM events; `Last State: OOMKilled` in describe pod
7. `kubectl exec <pod> -- sh` — if you can get in before it crashes, inspect env vars, mounts, connectivity
8. Compare against a working deployment: same image, same config — does it run there?

CrashLoopBackOff itself is just K8s adding delay between restarts. The real problem is always in the logs.

---

## What Just Happened

Three different categories of Kubernetes failures, each with distinct symptoms and fixes. `ImagePullBackOff` is caught immediately in Events — the image tag was wrong. The liveness probe failure was subtler: nginx was healthy, but the probe was checking the wrong port, so K8s killed it every 10 seconds. The selector mismatch is the most common real-world issue: everything looks healthy (pods Running, service exists) but traffic doesn't flow because no endpoints match. `kubectl get endpoints` is the fastest way to diagnose service connectivity.
```

- [ ] **Step 2: Write verify.sh**

File path: `modules/01-kubernetes/1B-workload-management/06-debugging/verify.sh`

Content:
```bash
#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1B-06"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Debugging"
echo ""

# Check 1: issue1.txt exists and mentions image/pull error
if [[ -f "$WORK_DIR/issue1.txt" ]]; then
  if grep -qi "imagepull\|image\|99.99\|not found\|tag" "$WORK_DIR/issue1.txt"; then
    check "issue1.txt documents the image pull error" "pass"
  else
    check "issue1.txt should describe the ImagePullBackOff issue (bad image tag)" "fail"
  fi
else
  check "issue1.txt exists in $WORK_DIR" "fail"
fi

# Check 2: issue2.txt mentions probe/port issue
if [[ -f "$WORK_DIR/issue2.txt" ]]; then
  if grep -qi "probe\|port\|9999\|liveness\|crash" "$WORK_DIR/issue2.txt"; then
    check "issue2.txt documents the liveness probe port mismatch" "pass"
  else
    check "issue2.txt should describe the liveness probe issue (wrong port)" "fail"
  fi
else
  check "issue2.txt exists in $WORK_DIR" "fail"
fi

# Check 3: issue3.txt mentions selector/labels
if [[ -f "$WORK_DIR/issue3.txt" ]]; then
  if grep -qi "selector\|label\|endpoint\|mismatch\|typo" "$WORK_DIR/issue3.txt"; then
    check "issue3.txt documents the service selector mismatch" "pass"
  else
    check "issue3.txt should describe the selector/label mismatch issue" "fail"
  fi
else
  check "issue3.txt exists in $WORK_DIR" "fail"
fi

# Check 4: connectivity.txt has curl responses from all 3 services
if [[ -f "$WORK_DIR/connectivity.txt" ]]; then
  if grep -qi "html\|nginx\|welcome\|broken-image\|broken-probe\|broken-selector" "$WORK_DIR/connectivity.txt"; then
    check "connectivity.txt has curl results for fixed services" "pass"
  else
    check "connectivity.txt should show curl responses from the 3 fixed services" "fail"
  fi
else
  check "connectivity.txt exists in $WORK_DIR" "fail"
fi

# Cluster checks
if ! kubectl cluster-info &>/dev/null; then
  echo "  (cluster checks skipped — minikube not running)"
else
  # Check 5: broken-image deployment is healthy
  available=$(kubectl get deployment broken-image -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo 0)
  if [[ "${available:-0}" -ge 1 ]]; then
    check "broken-image deployment is healthy ($available replicas available)" "pass"
  else
    check "broken-image deployment should be healthy — fix the image tag with: kubectl set image deployment/broken-image nginx=nginx:stable" "fail"
  fi

  # Check 6: broken-probe deployment is healthy (no excessive restarts)
  restarts=$(kubectl get pods -l app=broken-probe -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}' 2>/dev/null || echo 999)
  available2=$(kubectl get deployment broken-probe -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo 0)
  if [[ "${available2:-0}" -ge 1 ]]; then
    check "broken-probe deployment is healthy (probe fixed)" "pass"
  else
    check "broken-probe deployment should be healthy — fix the liveness probe port to 80" "fail"
  fi

  # Check 7: broken-selector service has endpoints
  endpoint_count=$(kubectl get endpoints broken-selector-svc -o jsonpath='{.subsets[0].addresses}' 2>/dev/null | grep -o "ip" | wc -l || echo 0)
  endpoints_raw=$(kubectl get endpoints broken-selector-svc 2>/dev/null)
  if echo "$endpoints_raw" | grep -q "[0-9]\{1,3\}\.[0-9]\{1,3\}"; then
    check "broken-selector-svc has endpoints (selector fixed)" "pass"
  else
    check "broken-selector-svc has no endpoints — fix the service selector to match pod labels" "fail"
  fi
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
```

- [ ] **Step 3: Write reset.sh**

Note: This reset.sh creates the broken deployments for the exercise.

File path: `modules/01-kubernetes/1B-workload-management/06-debugging/reset.sh`

Content:
```bash
#!/usr/bin/env bash
echo "Resetting: Debugging exercise"
echo "Creating 3 broken deployments for you to diagnose..."

# Clean previous state
kubectl delete deployment broken-image broken-probe broken-selector --ignore-not-found=true
kubectl delete svc broken-image-svc broken-probe-svc broken-selector-svc --ignore-not-found=true

# Wait for deletion
sleep 3

# 1. broken-image: uses non-existent image tag → ImagePullBackOff
kubectl create deployment broken-image --image=nginx:99.99.99 --replicas=1
kubectl expose deployment broken-image --port=80 --name=broken-image-svc

# 2. broken-probe: liveness probe on wrong port → restarts
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broken-probe
spec:
  replicas: 1
  selector:
    matchLabels:
      app: broken-probe
  template:
    metadata:
      labels:
        app: broken-probe
    spec:
      containers:
      - name: nginx
        image: nginx:stable
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 9999
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 2
EOF
kubectl expose deployment broken-probe --port=80 --name=broken-probe-svc

# 3. broken-selector: service selector doesn't match pod labels (typo)
kubectl create deployment broken-selector --image=nginx:stable --replicas=1

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: broken-selector-svc
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: broken-slector
EOF

# Clean work directory
rm -rf /tmp/devops-lab/1B-06
mkdir -p /tmp/devops-lab/1B-06

echo ""
echo "Reset complete. 3 broken deployments created:"
echo "  broken-image     → ImagePullBackOff (bad image tag)"
echo "  broken-probe     → CrashLoopBackOff (liveness probe on wrong port)"
echo "  broken-selector  → Service has no endpoints (selector typo)"
echo ""
echo "Work directory: /tmp/devops-lab/1B-06"
echo "Start with: kubectl get pods"
```

- [ ] **Step 4: Write hint.md**

File path: `modules/01-kubernetes/1B-workload-management/06-debugging/hint.md`

Content:
```markdown
## Hints

### General debugging workflow
```bash
kubectl get pods                          # see overall state
kubectl describe pod <pod-name>           # detailed state + Events
kubectl logs <pod-name>                   # stdout/stderr
kubectl logs --previous <pod-name>        # logs from last crashed container
kubectl get events --sort-by='.lastTimestamp'  # cluster-wide recent events
```

### Diagnosing broken-image (ImagePullBackOff)
```bash
kubectl get pods -l app=broken-image
kubectl describe pod -l app=broken-image
```
Look at `Events:` — it will say something like:
`Failed to pull image "nginx:99.99.99": ... not found`

Fix: update to a real tag:
```bash
kubectl set image deployment/broken-image nginx=nginx:stable
```

### Diagnosing broken-probe (CrashLoopBackOff / restarts)
```bash
kubectl get pods -l app=broken-probe    # high RESTARTS count
kubectl describe pod -l app=broken-probe
```
Look for: `Liveness probe failed: Get "http://10.x.x.x:9999/": connect: connection refused`

Check the probe config:
```bash
kubectl get deployment broken-probe -o yaml | grep -A10 livenessProbe
```

Fix: patch the probe port:
```bash
kubectl patch deployment broken-probe --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/livenessProbe/httpGet/port", "value": 80}]'
```

### Diagnosing broken-selector (no endpoints)
```bash
kubectl get endpoints broken-selector-svc   # shows <none>
```
If endpoints are empty, the selector doesn't match any pod labels.

Compare selectors:
```bash
kubectl get svc broken-selector-svc -o jsonpath='{.spec.selector}'
kubectl get pods -l app=broken-selector --show-labels
```
Spot the difference! The service has a typo in the label value.

Fix: patch the service selector:
```bash
kubectl patch svc broken-selector-svc --type='json' \
  -p='[{"op": "replace", "path": "/spec/selector/app", "value": "broken-selector"}]'
```
Verify: `kubectl get endpoints broken-selector-svc` should now show an IP.

### Running a debug pod for connectivity testing
```bash
kubectl run debug-pod --image=curlimages/curl --restart=Never \
  --command -- sleep 120
kubectl exec debug-pod -- curl -s http://broken-image-svc/
kubectl delete pod debug-pod
```

### Quick reference: K8s failure states
| State | Cause |
|-------|-------|
| `ImagePullBackOff` | Image doesn't exist or registry auth failed |
| `CrashLoopBackOff` | Container exits immediately — check logs |
| `Pending` | No node can schedule the pod — check events |
| `0/1 Running` | Pod up but readiness probe failing |
| `Evicted` | Node ran out of resources |
```

- [ ] **Step 5: Commit**

```bash
cd ~/devops-lab
git add modules/01-kubernetes/1B-workload-management/06-debugging/
git commit -m "feat: add 1B-06 debugging exercise"
```

---

## Task 7: Final Cleanup and Integration Commit

- [ ] **Step 1: Make all shell scripts executable**

```bash
find ~/devops-lab/modules/01-kubernetes/1B-workload-management/ -name "*.sh" -exec chmod +x {} \;
```

- [ ] **Step 2: Verify directory structure**

```bash
find ~/devops-lab/modules/01-kubernetes/1B-workload-management/ -type f | sort
```

Expected output: 4 files per exercise × 6 exercises = 24 files total (plus section.json = 25).

- [ ] **Step 3: Final integration commit**

```bash
cd ~/devops-lab
git add modules/01-kubernetes/1B-workload-management/
git commit -m "feat: add exercises 1B-01 through 1B-06 (K8s workload management)"
```

---

## Verification Checklist

After all tasks complete, confirm:

- [ ] `01-namespaces/` — 4 files exist, verify.sh checks namespaces.txt, pods-dev.txt, pods-staging.txt, cross-ns.txt, default-ns-pods.txt
- [ ] `02-resource-limits/` — 4 files exist, verify.sh checks resource-pod.yaml, pending-reason.txt, metrics.txt, qos-notes.txt
- [ ] `03-health-checks/` — 4 files exist, verify.sh checks liveness.yaml, not-ready.txt (0/1), ready.txt (1/1), restart-events.txt
- [ ] `04-rolling-updates/` — 4 files exist, verify.sh checks deploy.yaml strategy, rollout-log.txt, failed-rollout.txt, history.txt
- [ ] `05-jobs-cronjobs/` — 4 files exist, verify.sh checks job.yaml, parallel-jobs.txt (3 completed), cronjob.yaml, job-usecases.txt
- [ ] `06-debugging/` — 4 files exist, reset.sh creates 3 broken deployments, verify.sh checks issue1-3.txt, connectivity.txt
- [ ] All .sh files are executable (`chmod +x`)
- [ ] All verify.sh scripts skip cluster checks gracefully if minikube not running
