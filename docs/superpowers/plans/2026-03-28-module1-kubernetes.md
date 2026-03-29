# Module 1: Kubernetes — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build 20 hands-on Kubernetes exercises plus a capstone project for the DevOps Lab platform, taking a learner from zero K8s knowledge to deploying a multi-container monitoring stack with Helm.

**Architecture:** Same pattern as Module 0 — each exercise has `lesson.md`, `verify.sh`, `reset.sh`, and `hint.md`. Exercises run against a minikube cluster on the server. A prerequisites setup task installs minikube, kubectl, and helm. Verification scripts use `kubectl` to check actual cluster state (pods running, services created, etc.). The capstone produces a Helm chart repo suitable for GitHub/CV.

**Tech Stack:** minikube, kubectl, helm, Docker (already installed), Kubernetes concepts

**Scope note:** This plan covers Module 1 only. The platform infrastructure already exists at `~/devops-lab/`.

---

## File Structure

```
~/devops-lab/modules/01-kubernetes/
├── module.json
├── cheatsheet.md
├── 1A-core-concepts/
│   ├── section.json
│   ├── 01-architecture-overview/
│   │   ├── lesson.md
│   │   ├── verify.sh
│   │   ├── reset.sh
│   │   └── hint.md
│   ├── 02-pods/
│   ├── 03-deployments/
│   ├── 04-services/
│   ├── 05-configmaps-secrets/
│   └── 06-persistent-volumes/
├── 1B-workload-management/
│   ├── section.json
│   ├── 01-namespaces/
│   ├── 02-resource-limits/
│   ├── 03-health-checks/
│   ├── 04-rolling-updates/
│   ├── 05-jobs-cronjobs/
│   └── 06-debugging/
├── 1C-packaging-networking/
│   ├── section.json
│   ├── 01-helm-basics/
│   ├── 02-helm-create-chart/
│   ├── 03-ingress/
│   ├── 04-network-policies/
│   ├── 05-dns-service-discovery/
│   └── 06-multi-container-pods/
├── 1D-capstone/
│   ├── section.json
│   ├── 01-capstone-monitoring-stack/
│   │   ├── lesson.md
│   │   ├── verify.sh
│   │   ├── reset.sh
│   │   └── hint.md
│   └── 02-capstone-helm-chart/
│       ├── lesson.md
│       ├── verify.sh
│       ├── reset.sh
│       └── hint.md
capstone-templates/
└── k8s-monitoring-stack/
    ├── README.md
    └── chart/          # Helm chart skeleton
```

## Exercise Content Guidelines

Same rules as Module 0 (these apply to ALL exercises):

1. **lesson.md**: Theory (2-3 paragraphs, short), numbered Tasks with exact kubectl commands and file paths under `/tmp/devops-lab/<exercise-id>/`, Interview Q blockquote, "What Just Happened" section
2. **verify.sh**: Uses check() pattern, checks actual K8s cluster state via kubectl, exits 0 only if ALL pass
3. **reset.sh**: Deletes K8s resources created by the exercise, cleans work directory
4. **hint.md**: Progressive hints per task (direction first, then command syntax)

**Important for K8s exercises:**
- Module 1 does NOT have the no-AI rule — learners can use AI for concepts but should type commands themselves
- All exercises must work on minikube (not a real cloud cluster)
- Verification should check actual cluster state: `kubectl get pods -o json`, `kubectl get svc`, etc.
- Reset scripts must clean up K8s resources (delete pods, services, deployments, namespaces, etc.)
- Use blockchain-relevant examples where possible (node health checker, validator monitoring)
- Include `kubectl` commands in the lesson — don't just describe what to do, show the exact commands

---

## Phase 0: Prerequisites

### Task 1: Install Minikube, kubectl, and Helm

**Files:**
- Create: `~/devops-lab/modules/01-kubernetes/setup-prereqs.sh`

- [ ] **Step 1: Write the prerequisites installation script**

This script checks for and installs minikube, kubectl, and helm. It also starts minikube if not running.

```bash
#!/usr/bin/env bash
set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${BOLD}Setting up Kubernetes prerequisites...${NC}\n"

# Check Docker
if ! command -v docker &>/dev/null; then
  echo -e "${YELLOW}Docker is required. Install Docker first (Module 0C).${NC}"
  exit 1
fi
echo -e "  ${GREEN}✓${NC} Docker $(docker --version | awk '{print $3}' | tr -d ',')"

# Install kubectl
if ! command -v kubectl &>/dev/null; then
  echo "  Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
fi
echo -e "  ${GREEN}✓${NC} kubectl $(kubectl version --client -o json 2>/dev/null | jq -r '.clientVersion.gitVersion' 2>/dev/null || echo 'installed')"

# Install minikube
if ! command -v minikube &>/dev/null; then
  echo "  Installing minikube..."
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  chmod +x minikube-linux-amd64
  sudo mv minikube-linux-amd64 /usr/local/bin/minikube
fi
echo -e "  ${GREEN}✓${NC} minikube $(minikube version --short 2>/dev/null || echo 'installed')"

# Install helm
if ! command -v helm &>/dev/null; then
  echo "  Installing helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi
echo -e "  ${GREEN}✓${NC} helm $(helm version --short 2>/dev/null || echo 'installed')"

# Start minikube if not running
if ! minikube status | grep -q "Running" 2>/dev/null; then
  echo -e "\n  ${BLUE}Starting minikube...${NC} (this may take a few minutes)"
  # Check available memory (need at least 10GB free for minikube + host)
  avail_mb=$(free -m | awk '/^Mem:/{print $7}')
  if [[ $avail_mb -lt 10000 ]]; then
    echo -e "  ${YELLOW}Warning: Only ${avail_mb}MB available. Recommend 16GB+ total RAM.${NC}"
  fi
  minikube start --driver=docker --cpus=4 --memory=8192 --cni=calico --addons=ingress,metrics-server
  echo -e "  ${GREEN}✓${NC} minikube cluster running"
else
  echo -e "  ${GREEN}✓${NC} minikube cluster already running"
fi

# Verify cluster
kubectl cluster-info --context minikube &>/dev/null
echo -e "\n${GREEN}${BOLD}Prerequisites ready!${NC}"
echo -e "Cluster: $(kubectl config current-context)"
echo -e "Nodes:   $(kubectl get nodes --no-headers | wc -l)"
```

- [ ] **Step 2: Make executable and test**

```bash
chmod +x ~/devops-lab/modules/01-kubernetes/setup-prereqs.sh
```

- [ ] **Step 3: Commit**

```bash
cd ~/devops-lab && git add modules/01-kubernetes/setup-prereqs.sh && git commit -m "feat: add Kubernetes prerequisites installer"
```

---

## Phase 1: Module Metadata

### Task 2: Module 1 Metadata and Cheatsheet

**Files:**
- Create: `~/devops-lab/modules/01-kubernetes/module.json`
- Create: `~/devops-lab/modules/01-kubernetes/cheatsheet.md`
- Create: `~/devops-lab/modules/01-kubernetes/1A-core-concepts/section.json`
- Create: `~/devops-lab/modules/01-kubernetes/1B-workload-management/section.json`
- Create: `~/devops-lab/modules/01-kubernetes/1C-packaging-networking/section.json`
- Create: `~/devops-lab/modules/01-kubernetes/1D-capstone/section.json`

- [ ] **Step 1: Create module.json**

```json
{
  "title": "Module 1: Kubernetes",
  "description": "From zero to deploying a multi-container monitoring stack with Helm on minikube.",
  "duration": "2 weeks",
  "noAiRule": false,
  "prerequisites": "Module 0 (especially Docker), minikube, kubectl, helm"
}
```

- [ ] **Step 2: Create section.json files**

`1A-core-concepts/section.json`:
```json
{ "title": "1A: Core Concepts", "description": "Architecture, Pods, Deployments, Services, ConfigMaps, Volumes" }
```

`1B-workload-management/section.json`:
```json
{ "title": "1B: Workload Management", "description": "Namespaces, resource limits, health checks, rolling updates, jobs, debugging" }
```

`1C-packaging-networking/section.json`:
```json
{ "title": "1C: Packaging & Networking", "description": "Helm, Ingress, network policies, DNS, multi-container pods" }
```

`1D-capstone/section.json`:
```json
{ "title": "1D: Capstone Project", "description": "Deploy a blockchain monitoring stack with Prometheus, Grafana, and Helm" }
```

- [ ] **Step 3: Write the Kubernetes cheatsheet**

`cheatsheet.md` — comprehensive kubectl/helm reference (~250 lines):

**Cluster & Context:**
- `kubectl cluster-info`, `kubectl config current-context`, `kubectl config use-context NAME`
- `minikube start/stop/delete/status/dashboard/tunnel`

**Pods:**
- `kubectl run NAME --image=IMAGE`, `kubectl get pods [-o wide|-o yaml]`, `kubectl describe pod NAME`
- `kubectl logs NAME [-f] [-c CONTAINER]`, `kubectl exec -it NAME -- /bin/sh`
- `kubectl delete pod NAME`, `kubectl port-forward pod/NAME LOCAL:REMOTE`

**Deployments:**
- `kubectl create deployment NAME --image=IMAGE --replicas=N`
- `kubectl scale deployment NAME --replicas=N`
- `kubectl set image deployment/NAME CONTAINER=IMAGE:TAG`
- `kubectl rollout status/history/undo deployment/NAME`

**Services:**
- `kubectl expose deployment NAME --port=PORT --target-port=PORT --type=ClusterIP|NodePort|LoadBalancer`
- `kubectl get svc`, `minikube service NAME --url`

**ConfigMaps & Secrets:**
- `kubectl create configmap NAME --from-literal=key=val --from-file=path`
- `kubectl create secret generic NAME --from-literal=key=val`

**Volumes:**
- PVC: `kubectl get pvc`, PV: `kubectl get pv`

**Namespaces:**
- `kubectl create ns NAME`, `kubectl get pods -n NAME`, `kubectl config set-context --current --namespace=NAME`

**Resource Management:**
- `kubectl top pods/nodes`, `kubectl describe node NAME | grep -A5 Allocated`

**Debugging:**
- `kubectl describe pod NAME`, `kubectl logs NAME --previous`, `kubectl get events --sort-by=.lastTimestamp`
- `kubectl exec -it NAME -- /bin/sh`, `kubectl run debug --image=busybox -it --rm -- sh`

**Helm:**
- `helm repo add NAME URL`, `helm search repo KEYWORD`, `helm install RELEASE CHART`
- `helm upgrade RELEASE CHART`, `helm uninstall RELEASE`, `helm list`
- `helm create NAME` (scaffold), `helm template RELEASE CHART` (dry run), `helm lint CHART`

**YAML shortcuts:**
- `kubectl create deployment NAME --image=IMAGE --dry-run=client -o yaml > dep.yaml`
- `kubectl apply -f file.yaml`, `kubectl delete -f file.yaml`

- [ ] **Step 4: Commit**

```bash
cd ~/devops-lab && git add modules/01-kubernetes/ && git commit -m "feat: add Module 1 metadata, section configs, and cheatsheet"
```

---

## Phase 2: Section 1A — Core Concepts (6 exercises)

### Task 3: Exercise 1A-01 — Architecture Overview

**Files:**
- Create: `modules/01-kubernetes/1A-core-concepts/01-architecture-overview/lesson.md`
- Create: `modules/01-kubernetes/1A-core-concepts/01-architecture-overview/verify.sh`
- Create: `modules/01-kubernetes/1A-core-concepts/01-architecture-overview/reset.sh`
- Create: `modules/01-kubernetes/1A-core-concepts/01-architecture-overview/hint.md`

Content:
- Theory: K8s architecture — control plane (API server, etcd, scheduler, controller manager) vs worker nodes (kubelet, kube-proxy, container runtime). What talks to what. The API server as the single source of truth.
- Include an ASCII diagram of the architecture.
- Task 1: Run `kubectl cluster-info` and write the output to `/tmp/devops-lab/1A-01/cluster-info.txt`
- Task 2: Run `kubectl get nodes -o wide` and write output to `nodes.txt`
- Task 3: List all system pods in `kube-system` namespace. Write to `system-pods.txt`. Identify which component each pod belongs to (API server, etcd, etc.)
- Task 4: Write to `architecture.txt` — explain in your own words what happens when you run `kubectl create deployment nginx --image=nginx` (which components are involved and in what order)
- Verify: cluster-info shows running cluster, nodes.txt contains at least 1 node, system-pods.txt lists kube-system pods, architecture.txt has 3+ lines
- Interview Q: "Explain the role of etcd in a Kubernetes cluster. What happens if etcd becomes unavailable?"

### Task 4: Exercise 1A-02 — Pods

Content:
- Theory: Pods as the smallest deployable unit, single vs multi-container pods, pod lifecycle
- Task 1: Create a pod named `lab-nginx` running `nginx:alpine` using `kubectl run`. Write the YAML that kubectl generates to `/tmp/devops-lab/1A-02/pod.yaml` (use `--dry-run=client -o yaml`)
- Task 2: Verify the pod is running with `kubectl get pods`. Exec into it and create a file `/usr/share/nginx/html/devops.html` with content "Hello K8s"
- Task 3: Port-forward the pod to local port 8088 (run in background: `kubectl port-forward pod/lab-nginx 8088:80 &`), curl `localhost:8088/devops.html`, and write the curl output to `response.txt`. Then kill the port-forward process.
- Task 4: View pod logs and write them to `pod-logs.txt`. Then delete the pod.
- Verify: pod.yaml exists with valid YAML, response.txt contains "Hello K8s", pod-logs.txt is non-empty, pod is deleted
- Interview Q: "Why can't you have two containers in the same pod that listen on the same port?"

### Task 5: Exercise 1A-03 — Deployments

Content:
- Theory: Deployments manage ReplicaSets which manage Pods. Desired state vs actual state. Self-healing.
- Task 1: Create a deployment `web-app` with image `nginx:1.24` and 3 replicas. Write the YAML to `/tmp/devops-lab/1A-03/deployment.yaml`
- Task 2: Scale the deployment to 5 replicas. Verify with `kubectl get pods`. Write pod names to `scaled-pods.txt`
- Task 3: Update the image to `nginx:1.25` and watch the rollout. Write `kubectl rollout status` output to `rollout.txt`
- Task 4: Roll back to the previous version. Write `kubectl rollout history` output to `history.txt`
- Verify: deployment exists with correct image, correct replica count, rollout.txt shows successful rollout, history shows 2+ revisions
- Interview Q: "What's the relationship between a Deployment, a ReplicaSet, and a Pod? What happens if you delete a Pod managed by a Deployment?"

### Task 6: Exercise 1A-04 — Services

Content:
- Theory: Service types (ClusterIP, NodePort, LoadBalancer), selectors, endpoints, port vs targetPort
- Task 1: Create a deployment `backend` with `nginx:alpine` (2 replicas). Then expose it as a ClusterIP service on port 80.
- Task 2: Create a NodePort service for the same deployment. Use `minikube service` to get the URL. Write URL to `/tmp/devops-lab/1A-04/nodeport-url.txt`
- Task 3: Create a temporary debug pod and curl the ClusterIP service by name from inside the cluster. Write output to `internal-access.txt`
- Task 4: Write to `service-types.txt` — explain when you'd use ClusterIP vs NodePort vs LoadBalancer (2-3 sentences each)
- Verify: Services exist with correct types, nodeport-url.txt has a URL, internal-access.txt shows nginx response, service-types.txt has 3 explanations
- Interview Q: "How does a Kubernetes Service route traffic to Pods? What happens when a Pod becomes unhealthy?"

### Task 7: Exercise 1A-05 — ConfigMaps and Secrets

Content:
- Theory: ConfigMaps for non-sensitive config, Secrets for sensitive data (base64, not encrypted at rest by default), mounting as env vars or volumes
- Task 1: Create a ConfigMap `app-config` with keys: `DB_HOST=postgres`, `DB_PORT=5432`, `LOG_LEVEL=info`. Write the YAML to `/tmp/devops-lab/1A-05/configmap.yaml`
- Task 2: Create a Secret `app-secret` with `DB_PASSWORD=supersecret123`. Write the YAML to `secret.yaml` (note how the value is base64-encoded)
- Task 3: Create a pod that mounts both as environment variables. Exec into it and write the output of `env | grep DB` to `env-output.txt`
- Task 4: Create another pod that mounts the ConfigMap as a volume at `/etc/config`. Exec in and write `ls /etc/config` output to `volume-mount.txt`
- Verify: ConfigMap and Secret exist, env-output.txt contains all DB_ vars, volume-mount.txt shows files
- Interview Q: "Kubernetes Secrets are base64-encoded, not encrypted. Why is this a concern and what solutions exist?"

### Task 8: Exercise 1A-06 — Persistent Volumes

Content:
- Theory: PersistentVolumes (PV), PersistentVolumeClaims (PVC), StorageClasses, data lifecycle beyond pod lifetime
- Task 1: Create a PVC named `data-pvc` requesting 100Mi of storage. Write YAML to `/tmp/devops-lab/1A-06/pvc.yaml`
- Task 2: Create a pod that mounts the PVC at `/data` and writes "persistent data" to `/data/test.txt`
- Task 3: Delete the pod. Create a NEW pod that mounts the same PVC. Verify the data persists — read `/data/test.txt` and write to `persistence-proof.txt`
- Task 4: Write to `storage-notes.txt` — explain the difference between PV, PVC, and StorageClass
- Verify: PVC is bound, persistence-proof.txt contains "persistent data", storage-notes.txt has 3+ lines
- Interview Q: "What happens to a PersistentVolume when the PVC is deleted? Explain Retain vs Delete reclaim policies."

---

## Phase 3: Section 1B — Workload Management (6 exercises)

### Task 9: Exercise 1B-01 — Namespaces

Content:
- Theory: Namespaces as virtual clusters, resource isolation, default namespaces (default, kube-system, kube-public)
- Task 1: Create namespaces `dev` and `staging`. List all namespaces and write to `/tmp/devops-lab/1B-01/namespaces.txt`
- Task 2: Deploy `nginx` in the `dev` namespace. Deploy `nginx` in the `staging` namespace with different replicas. Write pod list per namespace.
- Task 3: Try to access a service in `dev` from a pod in `staging` using the FQDN (`<svc>.<namespace>.svc.cluster.local`). Write result to `cross-ns.txt`
- Task 4: Set your default namespace to `dev` with `kubectl config`. Verify `kubectl get pods` shows only dev pods.
- Verify: Both namespaces exist, pods running in correct namespaces, cross-ns.txt shows successful access, current context namespace is dev
- Reset: Delete dev and staging namespaces, reset context namespace
- Interview Q: "How do namespaces help in a multi-team environment? Can you use them for security isolation?"

### Task 10: Exercise 1B-02 — Resource Limits and Requests

Content:
- Theory: Requests (scheduling guarantee) vs limits (hard ceiling), CPU (millicores) and memory, QoS classes (Guaranteed, Burstable, BestEffort)
- Task 1: Create a pod with resource requests (cpu: 100m, memory: 64Mi) and limits (cpu: 200m, memory: 128Mi). Write YAML to `/tmp/devops-lab/1B-02/resource-pod.yaml`
- Task 2: Create a pod that requests more memory than the node has (e.g., 999Gi). Observe the Pending state. Write `kubectl describe pod` output to `pending-reason.txt`
- Task 3: Run `kubectl top pods` and `kubectl top nodes` (requires metrics-server). Write output to `metrics.txt`
- Task 4: Write to `qos-notes.txt` — explain Guaranteed, Burstable, and BestEffort QoS classes
- Verify: Resource pod has correct requests/limits, pending pod is Pending with reason, metrics.txt has data, qos-notes.txt has explanations
- Interview Q: "What happens when a container exceeds its memory limit? What about its CPU limit?"

### Task 11: Exercise 1B-03 — Health Checks (Probes)

Content:
- Theory: Liveness (is it alive?), readiness (can it serve traffic?), startup (has it finished starting?) probes. HTTP, TCP, exec types.
- Task 1: Create a deployment with a liveness probe (HTTP GET /healthz). Write YAML to `/tmp/devops-lab/1B-03/liveness.yaml`
- Task 2: Create a deployment with a readiness probe that initially fails (e.g., checks a file that doesn't exist yet). Observe the pod is Running but not Ready. Write `kubectl get pods` output to `not-ready.txt`
- Task 3: Exec into the pod and create the file that makes the readiness probe pass. Verify the pod becomes Ready.
- Task 4: Create a deployment with a deliberately failing liveness probe. Watch it restart. Write `kubectl describe pod` showing restart events to `restart-events.txt`
- Verify: Liveness deployment exists with probe config, not-ready.txt shows 0/1 READY, pod eventually becomes Ready, restart-events shows CrashLoopBackOff or restarts
- Interview Q: "When should you use a readiness probe vs a liveness probe? What happens if your readiness probe is too aggressive?"

### Task 12: Exercise 1B-04 — Rolling Updates and Rollbacks

Content:
- Theory: Rolling update strategy, maxSurge, maxUnavailable, revision history, blue-green vs canary concepts
- Task 1: Create a deployment with `nginx:1.24` and strategy `RollingUpdate` with maxSurge=1, maxUnavailable=0. Write YAML to `/tmp/devops-lab/1B-04/deploy.yaml`
- Task 2: Update image to `nginx:1.25`. Watch the rollout with `kubectl rollout status`. Write to `rollout-log.txt`
- Task 3: Update to a BAD image (`nginx:nonexistent`). Watch it fail. Write `kubectl rollout status` output to `failed-rollout.txt`
- Task 4: Rollback with `kubectl rollout undo`. Verify pods are healthy. Write rollout history to `history.txt`
- Verify: Deployment has correct strategy, rollout-log shows success, failed-rollout shows failure, history shows 3+ revisions, current image is nginx:1.25
- Interview Q: "Explain the difference between a rolling update, blue-green deployment, and canary deployment. Which does Kubernetes support natively?"

### Task 13: Exercise 1B-05 — Jobs and CronJobs

Content:
- Theory: Jobs for one-off tasks, CronJobs for scheduled tasks, completions, parallelism, backoffLimit
- Task 1: Create a Job that runs `echo "Hello from K8s Job"` and write YAML to `/tmp/devops-lab/1B-05/job.yaml`. Verify it completes.
- Task 2: Create a Job with `completions: 3` and `parallelism: 2`. Watch all 3 complete. Write pod statuses to `parallel-jobs.txt`
- Task 3: Create a CronJob that runs every minute, writing the date to a log. Write YAML to `cronjob.yaml`. Wait for at least 1 execution.
- Task 4: Write to `job-usecases.txt` — 3 real-world examples of when you'd use a Job vs a CronJob
- Verify: Job completed successfully, parallel job had 3 completions, CronJob exists with schedule, at least 1 CronJob pod ran
- Interview Q: "What happens if a CronJob's previous run hasn't finished when the next scheduled run triggers? How do you control this?"

### Task 14: Exercise 1B-06 — Debugging

Content:
- Theory: The kubectl debugging toolkit — describe, logs, events, exec, ephemeral containers, common failure modes
- Setup: reset.sh creates 3 DELIBERATELY BROKEN deployments:
  1. Image doesn't exist → ImagePullBackOff
  2. Liveness probe fails → CrashLoopBackOff
  3. Service selector doesn't match deployment labels → no endpoints
- Task 1: Diagnose deployment 1. Write the issue and fix to `/tmp/devops-lab/1B-06/issue1.txt`. Fix it.
- Task 2: Diagnose deployment 2. Write issue and fix to `issue2.txt`. Fix it.
- Task 3: Diagnose deployment 3. Write issue and fix to `issue3.txt`. Fix it.
- Task 4: Run a debug pod with busybox to test connectivity to each fixed service. Write curl results to `connectivity.txt`
- Verify: All 3 deployments running and healthy, issue files describe correct problems, services have endpoints
- Interview Q: "A pod is stuck in CrashLoopBackOff. Walk me through your debugging steps from the first command to the fix."

---

## Phase 4: Section 1C — Packaging & Networking (6 exercises)

### Task 15: Exercise 1C-01 — Helm Basics

Content:
- Theory: Helm as K8s package manager, charts, releases, repos, values
- Task 1: Add the Bitnami repo. Search for nginx chart. Write search results to `/tmp/devops-lab/1C-01/search-results.txt`
- Task 2: Install the Bitnami nginx chart as release `my-nginx`. Write `helm list` output to `releases.txt`
- Task 3: Customize the installation — set `service.type=NodePort` and `replicaCount=2` using `--set`. Write the values to `custom-values.yaml`
- Task 4: Upgrade the release with the custom values. Then uninstall it. Write the history to `helm-history.txt`
- Verify: Bitnami repo added, release was installed, custom values were applied, release was uninstalled
- Interview Q: "What's the difference between `helm install` and `kubectl apply`? When would you use each?"

### Task 16: Exercise 1C-02 — Create a Helm Chart

Content:
- Theory: Chart structure (Chart.yaml, values.yaml, templates/), Go templating basics, helm create, helm template
- Task 1: Scaffold a new chart with `helm create node-monitor` in `/tmp/devops-lab/1C-02/`. Examine the structure.
- Task 2: Modify the chart to deploy a simple app: edit `values.yaml` to use `nginx:alpine` image, set replicas to 2, add custom environment variables
- Task 3: Run `helm template` to see the rendered YAML. Write to `rendered.yaml`. Run `helm lint` to validate.
- Task 4: Install the chart on minikube. Verify pods are running with correct config.
- Verify: Chart directory exists with correct structure, rendered.yaml is valid K8s YAML, helm lint passes, release is installed and pods running
- Interview Q: "Explain Go templating in Helm. What are `{{ .Values }}`, `{{ .Release }}`, and `{{ include }}`?"

### Task 17: Exercise 1C-03 — Ingress

Content:
- Theory: Ingress as L7 routing, Ingress Controller (nginx), host-based and path-based routing, TLS
- Prerequisites: Ensure minikube ingress addon is enabled
- Task 1: Create two deployments (`app-v1` and `app-v2`) with different content
- Task 2: Create services for both deployments
- Task 3: Write an Ingress resource that routes `/v1` to app-v1 and `/v2` to app-v2. Write YAML to `/tmp/devops-lab/1C-03/ingress.yaml`
- Task 4: Test the routing with curl (using minikube IP). Write results to `routing-test.txt`
- Verify: Ingress exists with correct rules, both paths route to correct backends, routing-test.txt shows different responses
- Interview Q: "What's the difference between an Ingress resource and an Ingress Controller? Can you have multiple Ingress Controllers?"

### Task 18: Exercise 1C-04 — Network Policies

Content:
- Theory: Network Policies as K8s firewalls, ingress vs egress rules, label selectors, namespace selectors
- Task 1: Create a namespace `netpol-lab`. Deploy a `web` and a `db` pod. Verify web can reach db.
- Task 2: Write a NetworkPolicy that only allows traffic to `db` from pods with label `role=web`. Write YAML to `/tmp/devops-lab/1C-04/netpol.yaml`
- Task 3: Verify `web` can still reach `db`, but a new pod without the label cannot. Write test results to `policy-test.txt`
- Task 4: Write to `netpol-notes.txt` — explain why network policies are important for multi-tenant clusters
- Verify: NetworkPolicy exists, labeled pod can access db, unlabeled pod cannot, notes file has content
- Note: Network policies require a CNI that supports them. minikube with Calico addon. If not available, verify YAML correctness only.
- Interview Q: "What's the default network policy in Kubernetes? What happens when you apply your first NetworkPolicy to a namespace?"

### Task 19: Exercise 1C-05 — DNS and Service Discovery

Content:
- Theory: CoreDNS, service DNS names (<svc>.<ns>.svc.cluster.local), pod DNS, headless services
- Task 1: Create a service `my-svc` in `default` namespace. From a debug pod, resolve it using `nslookup my-svc` and `nslookup my-svc.default.svc.cluster.local`. Write to `/tmp/devops-lab/1C-05/dns-resolution.txt`
- Task 2: Create a headless service (clusterIP: None) with a StatefulSet of 2 pods. Resolve individual pod DNS names. Write to `headless-dns.txt`
- Task 3: Check CoreDNS config: `kubectl get configmap coredns -n kube-system -o yaml`. Write to `coredns-config.txt`
- Task 4: Write to `dns-notes.txt` — explain when you'd use a headless service
- Verify: DNS resolutions succeeded, headless DNS shows individual pod IPs, config file is non-empty
- Interview Q: "How does DNS work inside a Kubernetes cluster? What happens when a pod tries to resolve an external domain name?"

### Task 20: Exercise 1C-06 — Multi-Container Pods

Content:
- Theory: Sidecar pattern, init containers, ambassador pattern, shared volumes between containers
- Task 1: Create a pod with an init container that writes a config file to a shared volume, and a main container that reads it. Write YAML to `/tmp/devops-lab/1C-06/init-container.yaml`
- Task 2: Create a pod with a sidecar pattern — main container writes logs to a shared volume, sidecar reads and forwards them. Write YAML to `sidecar.yaml`
- Task 3: Verify the init container completed before the main container started. Write `kubectl describe pod` output to `init-events.txt`
- Task 4: Write to `patterns.txt` — describe 3 multi-container pod patterns and when you'd use each
- Verify: Init container pod has both containers, init completed before main, sidecar pod has 2 running containers, patterns file has 3 descriptions
- Interview Q: "What's the difference between a sidecar container and an init container? Give a real-world example of each."

---

## Phase 5: Section 1D — Capstone (2 exercises)

### Task 21: Exercise 1D-01 — Deploy Monitoring Stack

Content:
- Theory: Prometheus + Grafana as the standard K8s monitoring stack, what gets scraped, how metrics flow
- Task 1: Create a namespace `monitoring`
- Task 2: Deploy Prometheus using a Helm chart (prometheus-community/prometheus) with custom values: scrape interval 15s, retention 2h (minikube-friendly)
- Task 3: Deploy Grafana using its Helm chart with default admin credentials
- Task 4: Deploy a simple "node health checker" service (a Python/Go app or nginx with a metrics endpoint) that Prometheus can scrape
- Task 5: Port-forward Grafana and verify it loads. Import a basic dashboard. Write the Grafana URL to `/tmp/devops-lab/1D-01/grafana-url.txt`
- Verify: All pods in monitoring namespace are running, Prometheus targets page shows scraped targets, Grafana is accessible
- Interview Q: "Explain the pull-based monitoring model that Prometheus uses. How is it different from push-based monitoring?"

### Task 22: Exercise 1D-02 — Package as Helm Chart (CV Piece)

Content:
- Theory: Packaging your work as a reusable Helm chart, chart best practices, values for customization
- Task 1: Create a Helm chart `blockchain-monitor` in `/tmp/devops-lab/1D-02/chart/` that deploys the entire stack from 1D-01 (Prometheus, Grafana, health checker)
- Task 2: Use subcharts or templates to define all resources. Add configurable values for: replica counts, scrape interval, dashboard selection
- Task 3: Add an Ingress resource in the chart that exposes Grafana
- Task 4: Run `helm lint` and `helm template` to validate. Install it. Verify the full stack works.
- Task 5: Write a README.md for the chart repo (for GitHub/CV)
- Verify: Chart passes lint, template renders valid YAML, installation succeeds, all pods running, README exists with install instructions
- Interview Q: "How would you manage multiple environments (dev, staging, prod) with the same Helm chart?"

---

### Task 23: Capstone Template

**Files:**
- Create: `~/devops-lab/capstone-templates/k8s-monitoring-stack/README.md`
- Create: `~/devops-lab/capstone-templates/k8s-monitoring-stack/Chart.yaml`
- Create: `~/devops-lab/capstone-templates/k8s-monitoring-stack/values.yaml`

Starter template for the capstone Helm chart:
- README with project description, features, prerequisites, install instructions, and "Skills Demonstrated" section
- Basic Chart.yaml with name, version, description
- Starter values.yaml with commented structure for Prometheus, Grafana, and health-checker configs

---

### Task 24: Final Integration Test

- [ ] **Step 1: Run prerequisites script (if not already done)**
- [ ] **Step 2: Start server and test API**

```bash
cd ~/devops-lab && node server.js &
sleep 1
curl -s http://localhost:3333/api/modules | jq '[.modules[] | {title, exercises: ([.sections[].exercises | length] | add)}]'
```
Expected: Shows Module 0 (25 exercises) AND Module 1 (20 exercises)

- [ ] **Step 3: Test CLI**

```bash
lab status
lab list
```
Expected: Module 1 exercises appear in the listing

- [ ] **Step 4: Test first K8s exercise verify (should fail without minikube)**

```bash
lab reset 1A-core-concepts/01-architecture-overview
lab verify 1A-core-concepts/01-architecture-overview
```
Expected: Verification fails with clear messages about missing files

- [ ] **Step 5: Kill test server and commit any fixes**

---

## Summary

**Total tasks:** 24
**Total exercises:** 20 + 2 capstone = 22

**What this plan produces:**
- 22 Kubernetes exercises with lessons, verification, hints, and reset scripts
- Comprehensive kubectl/helm cheatsheet
- Prerequisites installer for minikube/kubectl/helm
- Capstone Helm chart template for GitHub/CV
- Content organized into 4 sections: Core Concepts, Workload Management, Packaging & Networking, Capstone

**Exercise count by section:**
| Section | Exercises |
|---------|-----------|
| 1A: Core Concepts | 6 (architecture, pods, deployments, services, configmaps, volumes) |
| 1B: Workload Management | 6 (namespaces, resources, probes, rolling updates, jobs, debugging) |
| 1C: Packaging & Networking | 6 (helm basics, helm create, ingress, netpol, DNS, multi-container) |
| 1D: Capstone | 2 (deploy stack, package as chart) |
| **Total** | **20** |

**Blockchain relevance:** The capstone deploys a "blockchain monitoring stack" — validator health checker + Prometheus + Grafana. The Helm chart is directly portfolio-relevant for crypto infrastructure companies.
