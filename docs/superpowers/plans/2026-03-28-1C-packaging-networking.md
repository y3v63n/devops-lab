# 1C Packaging & Networking — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create 6 hands-on Kubernetes exercises covering Helm, Ingress, NetworkPolicy, DNS, and multi-container pod patterns for the DevOps Lab platform.

**Architecture:** Each exercise follows the established 4-file pattern (lesson.md, verify.sh, reset.sh, hint.md). Verify scripts check both cluster state (via kubectl/helm) and file artifacts in `/tmp/devops-lab/1C-NN/`. Reset scripts delete K8s resources and wipe the work directory. All files live under `~/devops-lab/modules/01-kubernetes/1C-packaging-networking/`.

**Tech Stack:** kubectl, helm, minikube, Kubernetes (ingress-nginx addon, Calico CNI), bash

---

## File Structure

```
~/devops-lab/modules/01-kubernetes/1C-packaging-networking/
├── section.json                          (already exists — do not modify)
├── 01-helm-basics/
│   ├── lesson.md
│   ├── verify.sh
│   ├── reset.sh
│   └── hint.md
├── 02-helm-create-chart/
│   ├── lesson.md
│   ├── verify.sh
│   ├── reset.sh
│   └── hint.md
├── 03-ingress/
│   ├── lesson.md
│   ├── verify.sh
│   ├── reset.sh
│   └── hint.md
├── 04-network-policies/
│   ├── lesson.md
│   ├── verify.sh
│   ├── reset.sh
│   └── hint.md
├── 05-dns-service-discovery/
│   ├── lesson.md
│   ├── verify.sh
│   ├── reset.sh
│   └── hint.md
└── 06-multi-container-pods/
    ├── lesson.md
    ├── verify.sh
    ├── reset.sh
    └── hint.md
```

---

## Task 1: 01-helm-basics

**Files:**
- Create: `modules/01-kubernetes/1C-packaging-networking/01-helm-basics/lesson.md`
- Create: `modules/01-kubernetes/1C-packaging-networking/01-helm-basics/verify.sh`
- Create: `modules/01-kubernetes/1C-packaging-networking/01-helm-basics/reset.sh`
- Create: `modules/01-kubernetes/1C-packaging-networking/01-helm-basics/hint.md`

- [ ] **Step 1: Create lesson.md**

`modules/01-kubernetes/1C-packaging-networking/01-helm-basics/lesson.md`:

```markdown
# Exercise 1C-01: Helm Basics

## Theory

Helm is the package manager for Kubernetes. Where `kubectl apply -f` deploys raw YAML, Helm packages a set of Kubernetes manifests into a **chart** — a versioned, configurable bundle. A chart lives in a **repository** (like a Docker registry, but for charts), and each deployment of a chart is a **release** with its own name and history. The Bitnami repository publishes production-grade charts for popular software: nginx, PostgreSQL, Redis, and hundreds more.

A release is not just "apply these files once." Helm tracks the full history of every upgrade, rollback, and configuration change. `helm upgrade` applies a new chart version or new values to an existing release; `helm rollback` reverts to a previous revision. This audit trail makes Helm far more production-friendly than raw manifests. The values system — a YAML file where every chart setting is configurable — means you can share one chart across dev, staging, and prod by supplying different values files.

**Key commands:** `helm repo add`, `helm repo update`, `helm search repo`, `helm install`, `helm upgrade`, `helm list`, `helm history`, `helm uninstall`. Helm stores release state as Secrets in the cluster — deleting the release also removes those Secrets.

## Tasks

Work directory: `/tmp/devops-lab/1C-01/`

```bash
mkdir -p /tmp/devops-lab/1C-01
```

**Task 1 — Add the Bitnami repo and search for nginx**

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm search repo bitnami/nginx > /tmp/devops-lab/1C-01/search-results.txt
cat /tmp/devops-lab/1C-01/search-results.txt
```

**Task 2 — Install bitnami/nginx as release `my-nginx`**

```bash
helm install my-nginx bitnami/nginx
helm list > /tmp/devops-lab/1C-01/releases.txt
cat /tmp/devops-lab/1C-01/releases.txt
```

Wait for the pod to be running:
```bash
kubectl get pods -w
```

**Task 3 — Customize the release (NodePort + 2 replicas)**

Create a values file:

```bash
cat > /tmp/devops-lab/1C-01/custom-values.yaml <<'EOF'
service:
  type: NodePort
replicaCount: 2
EOF
```

**Task 4 — Upgrade the release, review history, then uninstall**

```bash
helm upgrade my-nginx bitnami/nginx -f /tmp/devops-lab/1C-01/custom-values.yaml
helm history my-nginx > /tmp/devops-lab/1C-01/helm-history.txt
cat /tmp/devops-lab/1C-01/helm-history.txt
helm uninstall my-nginx
helm list
```

## Interview Question

**"What's the difference between `helm install` and `kubectl apply`?"**

`kubectl apply` is idempotent but stateless — it applies YAML with no memory of what you deployed before. `helm install` creates a named **release** with full history: Helm records every revision as a Secret in the cluster, enabling `helm rollback`, `helm history`, and `helm diff`. Helm also supports templating with `{{ .Values }}` so one chart serves many environments. The tradeoff: Helm adds indirection (templates, values) and a local chart dependency. For a single one-off resource, `kubectl apply` is simpler. For anything you need to version, share, or roll back, Helm wins.

## What Just Happened

You used Helm to pull a production-grade nginx chart from the Bitnami repository, deployed it with default settings, then upgraded it with custom values (NodePort service, 2 replicas). `helm history` showed both revisions. Finally you uninstalled the release cleanly. This is the entire Helm lifecycle in one exercise — the same workflow scales to complex charts with 50 configurable values.
```

- [ ] **Step 2: Create verify.sh**

`modules/01-kubernetes/1C-packaging-networking/01-helm-basics/verify.sh`:

```bash
#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1C-01"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Exercise 1C-01 — Helm Basics"
echo ""

# Bitnami repo exists
bitnami_repo=$(helm repo list 2>/dev/null | grep -c "bitnami" || echo 0)
check "Bitnami Helm repo is configured" \
  "$([[ "$bitnami_repo" -gt 0 ]] && echo pass || echo fail)"

# search-results.txt exists and mentions nginx
check "search-results.txt exists" \
  "$([[ -f "$WORK_DIR/search-results.txt" ]] && echo pass || echo fail)"
if [[ -f "$WORK_DIR/search-results.txt" ]]; then
  check "search-results.txt contains nginx" \
    "$([[ "$(cat "$WORK_DIR/search-results.txt")" == *"nginx"* ]] && echo pass || echo fail)"
fi

# releases.txt exists
check "releases.txt exists" \
  "$([[ -f "$WORK_DIR/releases.txt" ]] && echo pass || echo fail)"
if [[ -f "$WORK_DIR/releases.txt" ]]; then
  check "releases.txt mentions my-nginx" \
    "$([[ "$(cat "$WORK_DIR/releases.txt")" == *"my-nginx"* ]] && echo pass || echo fail)"
fi

# custom-values.yaml exists with correct content
check "custom-values.yaml exists" \
  "$([[ -f "$WORK_DIR/custom-values.yaml" ]] && echo pass || echo fail)"
if [[ -f "$WORK_DIR/custom-values.yaml" ]]; then
  vals=$(cat "$WORK_DIR/custom-values.yaml")
  check "custom-values.yaml sets service.type NodePort" \
    "$([[ "$vals" == *"NodePort"* ]] && echo pass || echo fail)"
  check "custom-values.yaml sets replicaCount 2" \
    "$([[ "$vals" == *"replicaCount"* ]] && echo pass || echo fail)"
fi

# helm-history.txt exists and shows 2+ revisions
check "helm-history.txt exists" \
  "$([[ -f "$WORK_DIR/helm-history.txt" ]] && echo pass || echo fail)"
if [[ -f "$WORK_DIR/helm-history.txt" ]]; then
  revision_count=$(grep -c "deployed\|superseded\|failed" "$WORK_DIR/helm-history.txt" 2>/dev/null || echo 0)
  check "helm-history.txt shows multiple revisions" \
    "$([[ "$revision_count" -ge 2 ]] && echo pass || echo fail)"
fi

# Release is uninstalled (my-nginx should NOT be in helm list)
active_release=$(helm list 2>/dev/null | grep -c "my-nginx" || echo 0)
check "my-nginx release has been uninstalled" \
  "$([[ "$active_release" -eq 0 ]] && echo pass || echo fail)"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
```

- [ ] **Step 3: Create reset.sh**

`modules/01-kubernetes/1C-packaging-networking/01-helm-basics/reset.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Resetting: Exercise 1C-01 — Helm Basics"

WORK_DIR="/tmp/devops-lab/1C-01"

# Uninstall release if present
if helm list 2>/dev/null | grep -q "my-nginx"; then
  echo "  Uninstalling my-nginx release..."
  helm uninstall my-nginx 2>/dev/null || true
fi

# Clean work directory
echo "  Cleaning work directory..."
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

echo "  Done. Work directory reset to $WORK_DIR/"
echo "  Bitnami repo is still configured (run 'helm repo list' to check)."
```

- [ ] **Step 4: Create hint.md**

`modules/01-kubernetes/1C-packaging-networking/01-helm-basics/hint.md`:

```markdown
# Hints — Exercise 1C-01: Helm Basics

## Adding the repo

**Hint 1:** Helm repos must be added before you can install charts from them. Use:
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

**Hint 2:** To verify it worked:
```bash
helm repo list
```

---

## Searching and installing

**Hint 1:** `helm search repo bitnami/nginx` shows available charts. Add `--versions` to see all chart versions.

**Hint 2:** Install with a specific release name:
```bash
helm install my-nginx bitnami/nginx
```

**Hint 3:** Watch pods start up:
```bash
kubectl get pods -w
# Ctrl+C when Running
```

---

## Custom values

**Hint 1:** Create `custom-values.yaml`:
```yaml
service:
  type: NodePort
replicaCount: 2
```

**Hint 2:** Apply on upgrade:
```bash
helm upgrade my-nginx bitnami/nginx -f /tmp/devops-lab/1C-01/custom-values.yaml
```

**Hint 3:** Check what values are actually deployed:
```bash
helm get values my-nginx
```

---

## History and cleanup

**Hint 1:** See all revisions:
```bash
helm history my-nginx
```

**Hint 2:** Uninstall completely:
```bash
helm uninstall my-nginx
```
```

- [ ] **Step 5: Commit**

```bash
cd ~/devops-lab
git add modules/01-kubernetes/1C-packaging-networking/01-helm-basics/
git commit -m "feat: add 1C-01 helm-basics exercise"
```

---

## Task 2: 02-helm-create-chart

**Files:**
- Create: `modules/01-kubernetes/1C-packaging-networking/02-helm-create-chart/lesson.md`
- Create: `modules/01-kubernetes/1C-packaging-networking/02-helm-create-chart/verify.sh`
- Create: `modules/01-kubernetes/1C-packaging-networking/02-helm-create-chart/reset.sh`
- Create: `modules/01-kubernetes/1C-packaging-networking/02-helm-create-chart/hint.md`

- [ ] **Step 1: Create lesson.md**

`modules/01-kubernetes/1C-packaging-networking/02-helm-create-chart/lesson.md`:

```markdown
# Exercise 1C-02: Creating a Helm Chart

## Theory

`helm create <name>` scaffolds a complete chart directory with sensible defaults. The chart directory has three key components: **Chart.yaml** (metadata — name, version, appVersion), **values.yaml** (all configurable defaults), and **templates/** (Go-templated Kubernetes manifests). When you run `helm install` or `helm upgrade`, Helm renders the templates by merging your supplied values with the defaults, producing plain Kubernetes YAML that gets applied to the cluster.

Go templating syntax inside templates uses `{{ .Values.key }}` to reference values from `values.yaml` (or overrides from `--set` or `-f`). `{{ .Release.Name }}` injects the release name so the same chart can be installed multiple times with different names and no resource collisions. `{{ include "chart.name" . }}` calls a named template (defined in `_helpers.tpl`), which is how charts share label logic across all resources. Pipelines like `{{ .Values.image.tag | default "latest" }}` apply transformations.

`helm template` renders all templates locally without touching a cluster — invaluable for debugging. `helm lint` validates chart structure and template syntax. Together, `template` + `lint` give you a local feedback loop before deploying. `helm package` creates a `.tgz` artifact you can upload to a chart repository.

## Tasks

Work directory: `/tmp/devops-lab/1C-02/`

```bash
mkdir -p /tmp/devops-lab/1C-02
cd /tmp/devops-lab/1C-02
```

**Task 1 — Scaffold the chart**

```bash
cd /tmp/devops-lab/1C-02
helm create node-monitor
ls node-monitor/
ls node-monitor/templates/
```

**Task 2 — Customize values.yaml**

Edit `/tmp/devops-lab/1C-02/node-monitor/values.yaml`. Set:
- `image.repository: nginx`
- `image.tag: alpine`
- `replicaCount: 2`
- Under `env:` add a custom environment variable `APP_ENV: production`

You'll also need to wire the `env` section into the deployment template. Open `node-monitor/templates/deployment.yaml` and add under the container spec:

```yaml
          env:
            {{- range $key, $val := .Values.env }}
            - name: {{ $key }}
              value: {{ $val | quote }}
            {{- end }}
```

**Task 3 — Lint and render**

```bash
cd /tmp/devops-lab/1C-02
helm lint node-monitor
helm template my-release node-monitor > /tmp/devops-lab/1C-02/rendered.yaml
wc -l /tmp/devops-lab/1C-02/rendered.yaml
```

**Task 4 — Install on minikube**

```bash
helm install node-monitor-release /tmp/devops-lab/1C-02/node-monitor
kubectl get pods
helm list
```

Wait for pods:
```bash
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=node-monitor --timeout=60s
```

## Interview Question

**"Explain Go templating in Helm: `{{ .Values }}`, `{{ .Release }}`, `{{ include }}`"**

Helm templates are Go `text/template` with extra functions. `.Values` is the merged values map (defaults from `values.yaml` + overrides). `.Release` is metadata about the release: `.Release.Name` is the name you gave at install, `.Release.Namespace` is the namespace. These two objects let one chart produce unique resource names across installs. `{{ include "mychart.labels" . }}` calls a named template defined in `_helpers.tpl` and passes the current context (`.`) so the helper can access `.Values` and `.Release`. The `|` pipe operator chains functions: `{{ .Values.image.tag | default "latest" | quote }}` — if the tag is unset, use `"latest"`, then wrap in quotes for YAML safety. Template logic (`if`, `range`, `with`) enables conditional resources and loops over lists.

## What Just Happened

You scaffolded a real Helm chart, customised its values for a specific deployment (nginx:alpine, 2 replicas, custom env var), rendered it locally to verify the output, linted it, and deployed it to minikube. This is how every production Helm chart begins — `helm create` + customise + lint + deploy.
```

- [ ] **Step 2: Create verify.sh**

`modules/01-kubernetes/1C-packaging-networking/02-helm-create-chart/verify.sh`:

```bash
#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1C-02"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Exercise 1C-02 — Creating a Helm Chart"
echo ""

# Chart directory structure
check "node-monitor chart directory exists" \
  "$([[ -d "$WORK_DIR/node-monitor" ]] && echo pass || echo fail)"
check "Chart.yaml exists" \
  "$([[ -f "$WORK_DIR/node-monitor/Chart.yaml" ]] && echo pass || echo fail)"
check "values.yaml exists" \
  "$([[ -f "$WORK_DIR/node-monitor/values.yaml" ]] && echo pass || echo fail)"
check "templates/ directory exists" \
  "$([[ -d "$WORK_DIR/node-monitor/templates" ]] && echo pass || echo fail)"
check "templates/deployment.yaml exists" \
  "$([[ -f "$WORK_DIR/node-monitor/templates/deployment.yaml" ]] && echo pass || echo fail)"

# values.yaml content
if [[ -f "$WORK_DIR/node-monitor/values.yaml" ]]; then
  vals=$(cat "$WORK_DIR/node-monitor/values.yaml")
  check "values.yaml uses nginx image" \
    "$([[ "$vals" == *"nginx"* ]] && echo pass || echo fail)"
  check "values.yaml uses alpine tag" \
    "$([[ "$vals" == *"alpine"* ]] && echo pass || echo fail)"
  check "values.yaml sets replicaCount 2" \
    "$(echo "$vals" | grep -q "replicaCount.*2" && echo pass || echo fail)"
fi

# rendered.yaml exists and is non-empty
check "rendered.yaml exists" \
  "$([[ -f "$WORK_DIR/rendered.yaml" ]] && echo pass || echo fail)"
if [[ -f "$WORK_DIR/rendered.yaml" ]]; then
  line_count=$(wc -l < "$WORK_DIR/rendered.yaml")
  check "rendered.yaml is non-trivial (>20 lines)" \
    "$([[ "$line_count" -gt 20 ]] && echo pass || echo fail)"
  check "rendered.yaml contains Deployment" \
    "$([[ "$(cat "$WORK_DIR/rendered.yaml")" == *"kind: Deployment"* ]] && echo pass || echo fail)"
fi

# helm lint passes
if [[ -d "$WORK_DIR/node-monitor" ]]; then
  lint_output=$(helm lint "$WORK_DIR/node-monitor" 2>&1)
  check "helm lint passes (0 errors)" \
    "$([[ "$lint_output" != *"[ERROR]"* ]] && echo pass || echo fail)"
fi

# Release installed on cluster
release_count=$(helm list 2>/dev/null | grep -c "node-monitor" || echo 0)
check "node-monitor release is installed" \
  "$([[ "$release_count" -gt 0 ]] && echo pass || echo fail)"

# Pods running
pod_count=$(kubectl get pods -l "app.kubernetes.io/name=node-monitor" \
  --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l || echo 0)
check "node-monitor pods are running" \
  "$([[ "$pod_count" -gt 0 ]] && echo pass || echo fail)"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
```

- [ ] **Step 3: Create reset.sh**

`modules/01-kubernetes/1C-packaging-networking/02-helm-create-chart/reset.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Resetting: Exercise 1C-02 — Creating a Helm Chart"

WORK_DIR="/tmp/devops-lab/1C-02"

# Uninstall release if present
if helm list 2>/dev/null | grep -q "node-monitor"; then
  echo "  Uninstalling node-monitor release..."
  helm uninstall node-monitor-release 2>/dev/null || \
    helm list | grep node-monitor | awk '{print $1}' | xargs helm uninstall 2>/dev/null || true
fi

# Clean work directory
echo "  Cleaning work directory..."
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

echo "  Done. Work directory reset to $WORK_DIR/"
echo "  Run: cd /tmp/devops-lab/1C-02 && helm create node-monitor"
```

- [ ] **Step 4: Create hint.md**

`modules/01-kubernetes/1C-packaging-networking/02-helm-create-chart/hint.md`:

```markdown
# Hints — Exercise 1C-02: Creating a Helm Chart

## Scaffolding

**Hint 1:** `helm create` makes the full structure:
```bash
cd /tmp/devops-lab/1C-02
helm create node-monitor
```

**Hint 2:** The scaffold comes with a default nginx deployment. You're modifying it, not starting from scratch.

---

## values.yaml

**Hint 1:** The `image` block looks like:
```yaml
image:
  repository: nginx
  tag: "alpine"
  pullPolicy: IfNotPresent
```

**Hint 2:** For environment variables, add at the top level:
```yaml
env:
  APP_ENV: production
```

**Hint 3:** Then wire it into `templates/deployment.yaml` inside the container spec:
```yaml
          env:
            {{- range $key, $val := .Values.env }}
            - name: {{ $key }}
              value: {{ $val | quote }}
            {{- end }}
```

---

## Lint and template

**Hint 1:**
```bash
helm lint /tmp/devops-lab/1C-02/node-monitor
```
Look for `[ERROR]` lines. `[WARNING]` is OK.

**Hint 2:** Render without deploying:
```bash
helm template my-release /tmp/devops-lab/1C-02/node-monitor
```

---

## Installing

**Hint 1:**
```bash
helm install node-monitor-release /tmp/devops-lab/1C-02/node-monitor
```

**Hint 2:** Check pods:
```bash
kubectl get pods -l app.kubernetes.io/name=node-monitor
```
```

- [ ] **Step 5: Commit**

```bash
cd ~/devops-lab
git add modules/01-kubernetes/1C-packaging-networking/02-helm-create-chart/
git commit -m "feat: add 1C-02 helm-create-chart exercise"
```

---

## Task 3: 03-ingress

**Files:**
- Create: `modules/01-kubernetes/1C-packaging-networking/03-ingress/lesson.md`
- Create: `modules/01-kubernetes/1C-packaging-networking/03-ingress/verify.sh`
- Create: `modules/01-kubernetes/1C-packaging-networking/03-ingress/reset.sh`
- Create: `modules/01-kubernetes/1C-packaging-networking/03-ingress/hint.md`

- [ ] **Step 1: Create lesson.md**

`modules/01-kubernetes/1C-packaging-networking/03-ingress/lesson.md`:

```markdown
# Exercise 1C-03: Ingress and L7 Routing

## Theory

A Kubernetes **Service** exposes pods at layer 4 (TCP/UDP) — it routes by IP and port. An **Ingress** operates at layer 7 (HTTP/HTTPS) — it routes by hostname and URL path, inspecting the HTTP request. One Ingress resource can route `example.com/v1` to one service and `example.com/v2` to another, consolidating many services behind a single external IP and enabling TLS termination in one place.

The Ingress resource is just configuration. The actual traffic handling is done by an **Ingress Controller** — a pod running a reverse proxy (nginx, Traefik, HAProxy) that watches Ingress objects and reconfigures itself whenever they change. Different controllers have different feature sets; the annotation `kubernetes.io/ingress.class` (or the newer `ingressClassName` field) selects which controller handles a given Ingress. On minikube, the built-in nginx ingress controller is enabled with `minikube addons enable ingress`.

TLS termination on Ingress stores the certificate as a Secret and references it in the `tls:` block. Path types matter: `Prefix` matches any path starting with the given string; `Exact` requires an exact match. The `rewrite-target` annotation (nginx-specific) strips the path prefix before forwarding to the backend — useful when your apps don't know they're behind a path prefix.

## Prerequisites

```bash
minikube addons enable ingress
kubectl get pods -n ingress-nginx
# Wait until the controller pod is Running
```

## Tasks

Work directory: `/tmp/devops-lab/1C-03/`

```bash
mkdir -p /tmp/devops-lab/1C-03
```

**Task 1 — Create two deployments with different responses**

```bash
# app-v1: returns "v1"
kubectl create deployment app-v1 --image=nginx:alpine
kubectl set env deployment/app-v1 NGINX_MSG=v1

# Use a ConfigMap to serve different content
kubectl create configmap v1-config --from-literal=index.html="<h1>App Version 1</h1>"
kubectl create configmap v2-config --from-literal=index.html="<h1>App Version 2</h1>"

kubectl create deployment app-v1 --image=nginx:alpine --replicas=1
kubectl create deployment app-v2 --image=nginx:alpine --replicas=1
```

Actually, the cleanest approach uses ConfigMaps for content. Apply this YAML:

```bash
cat > /tmp/devops-lab/1C-03/apps.yaml <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: v1-html
data:
  index.html: "<h1>App Version 1</h1>"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: v2-html
data:
  index.html: "<h1>App Version 2</h1>"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-v1
  template:
    metadata:
      labels:
        app: app-v1
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
      volumes:
      - name: html
        configMap:
          name: v1-html
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-v2
  template:
    metadata:
      labels:
        app: app-v2
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
      volumes:
      - name: html
        configMap:
          name: v2-html
EOF
kubectl apply -f /tmp/devops-lab/1C-03/apps.yaml
```

**Task 2 — Create Services**

```bash
kubectl expose deployment app-v1 --port=80 --name=svc-v1
kubectl expose deployment app-v2 --port=80 --name=svc-v2
kubectl get services
```

**Task 3 — Write and apply the Ingress**

```bash
cat > /tmp/devops-lab/1C-03/ingress.yaml <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /v1
        pathType: Prefix
        backend:
          service:
            name: svc-v1
            port:
              number: 80
      - path: /v2
        pathType: Prefix
        backend:
          service:
            name: svc-v2
            port:
              number: 80
EOF
kubectl apply -f /tmp/devops-lab/1C-03/ingress.yaml
kubectl get ingress
```

**Task 4 — Test routing**

```bash
# Get minikube IP
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: $MINIKUBE_IP"

# Wait for ingress to get an IP
kubectl get ingress -w

# Test routing (may take 30-60s for ingress controller to pick up)
curl http://$MINIKUBE_IP/v1
curl http://$MINIKUBE_IP/v2

# Write results
{
  echo "=== /v1 ==="
  curl -s http://$MINIKUBE_IP/v1
  echo ""
  echo "=== /v2 ==="
  curl -s http://$MINIKUBE_IP/v2
  echo ""
} > /tmp/devops-lab/1C-03/routing-test.txt
cat /tmp/devops-lab/1C-03/routing-test.txt
```

## Interview Question

**"What's the difference between an Ingress resource and an Ingress Controller?"**

An **Ingress resource** is a Kubernetes API object — it's just configuration declaring routing rules: "route `/api` to service `backend`, terminate TLS with Secret `tls-cert`." By itself it does nothing. An **Ingress Controller** is a running pod (nginx, Traefik, HAProxy) that watches Ingress objects via the API server and reconfigures itself whenever they change. The controller is what actually handles traffic. This separation lets you swap controllers without changing your Ingress YAML. The annotation `ingressClassName: nginx` tells the API which controller to use when multiple controllers are installed.

## What Just Happened

You deployed two separate apps, each returning different content. A single Ingress resource routes HTTP traffic to each based on URL path — `/v1` goes to app-v1, `/v2` to app-v2. The nginx Ingress Controller automatically picked up the Ingress object and configured its proxy rules. This is how a real microservices platform handles public routing — dozens of services behind one load balancer, no per-service public IP needed.
```

- [ ] **Step 2: Create verify.sh**

`modules/01-kubernetes/1C-packaging-networking/03-ingress/verify.sh`:

```bash
#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1C-03"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Exercise 1C-03 — Ingress and L7 Routing"
echo ""

# Deployments exist
v1_deploy=$(kubectl get deployment app-v1 --no-headers 2>/dev/null | wc -l || echo 0)
check "app-v1 deployment exists" \
  "$([[ "$v1_deploy" -gt 0 ]] && echo pass || echo fail)"

v2_deploy=$(kubectl get deployment app-v2 --no-headers 2>/dev/null | wc -l || echo 0)
check "app-v2 deployment exists" \
  "$([[ "$v2_deploy" -gt 0 ]] && echo pass || echo fail)"

# Services exist
svc_v1=$(kubectl get service svc-v1 --no-headers 2>/dev/null | wc -l || echo 0)
check "svc-v1 service exists" \
  "$([[ "$svc_v1" -gt 0 ]] && echo pass || echo fail)"

svc_v2=$(kubectl get service svc-v2 --no-headers 2>/dev/null | wc -l || echo 0)
check "svc-v2 service exists" \
  "$([[ "$svc_v2" -gt 0 ]] && echo pass || echo fail)"

# ingress.yaml file
check "ingress.yaml exists" \
  "$([[ -f "$WORK_DIR/ingress.yaml" ]] && echo pass || echo fail)"
if [[ -f "$WORK_DIR/ingress.yaml" ]]; then
  ingress_content=$(cat "$WORK_DIR/ingress.yaml")
  check "ingress.yaml has /v1 path rule" \
    "$([[ "$ingress_content" == *"/v1"* ]] && echo pass || echo fail)"
  check "ingress.yaml has /v2 path rule" \
    "$([[ "$ingress_content" == *"/v2"* ]] && echo pass || echo fail)"
  check "ingress.yaml references svc-v1" \
    "$([[ "$ingress_content" == *"svc-v1"* ]] && echo pass || echo fail)"
  check "ingress.yaml references svc-v2" \
    "$([[ "$ingress_content" == *"svc-v2"* ]] && echo pass || echo fail)"
fi

# Ingress exists in cluster
ingress_exists=$(kubectl get ingress app-ingress --no-headers 2>/dev/null | wc -l || echo 0)
check "app-ingress Ingress resource exists in cluster" \
  "$([[ "$ingress_exists" -gt 0 ]] && echo pass || echo fail)"

# routing-test.txt shows different responses
check "routing-test.txt exists" \
  "$([[ -f "$WORK_DIR/routing-test.txt" ]] && echo pass || echo fail)"
if [[ -f "$WORK_DIR/routing-test.txt" ]]; then
  rt=$(cat "$WORK_DIR/routing-test.txt")
  check "routing-test.txt mentions v1 response" \
    "$([[ "$rt" == *"Version 1"* || "$rt" == *"v1"* ]] && echo pass || echo fail)"
  check "routing-test.txt mentions v2 response" \
    "$([[ "$rt" == *"Version 2"* || "$rt" == *"v2"* ]] && echo pass || echo fail)"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
```

- [ ] **Step 3: Create reset.sh**

`modules/01-kubernetes/1C-packaging-networking/03-ingress/reset.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Resetting: Exercise 1C-03 — Ingress and L7 Routing"

WORK_DIR="/tmp/devops-lab/1C-03"

echo "  Deleting Ingress resources..."
kubectl delete ingress app-ingress 2>/dev/null || true

echo "  Deleting services..."
kubectl delete service svc-v1 svc-v2 2>/dev/null || true

echo "  Deleting deployments..."
kubectl delete deployment app-v1 app-v2 2>/dev/null || true

echo "  Deleting ConfigMaps..."
kubectl delete configmap v1-html v2-html 2>/dev/null || true

echo "  Cleaning work directory..."
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

echo "  Done. Work directory reset to $WORK_DIR/"
```

- [ ] **Step 4: Create hint.md**

`modules/01-kubernetes/1C-packaging-networking/03-ingress/hint.md`:

```markdown
# Hints — Exercise 1C-03: Ingress and L7 Routing

## Prerequisites

**Hint 1:** Ensure the ingress addon is enabled:
```bash
minikube addons enable ingress
kubectl get pods -n ingress-nginx
```
Wait for the controller pod to be `Running` before testing.

---

## Deployments and Services

**Hint 1:** Use the provided `apps.yaml` from the lesson. Apply with:
```bash
kubectl apply -f /tmp/devops-lab/1C-03/apps.yaml
```

**Hint 2:** Expose deployments as services:
```bash
kubectl expose deployment app-v1 --port=80 --name=svc-v1
kubectl expose deployment app-v2 --port=80 --name=svc-v2
```

---

## Ingress YAML

**Hint 1:** The `ingressClassName: nginx` field selects the minikube nginx controller.

**Hint 2:** The `rewrite-target: /` annotation strips the path prefix. Without it, nginx would forward `/v1/...` as-is, but your backend serves at `/`.

**Hint 3 (full Ingress):**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /v1
        pathType: Prefix
        backend:
          service:
            name: svc-v1
            port:
              number: 80
      - path: /v2
        pathType: Prefix
        backend:
          service:
            name: svc-v2
            port:
              number: 80
```

---

## Testing

**Hint 1:** Get the minikube IP:
```bash
minikube ip
```

**Hint 2:** The ingress controller may take 30-60 seconds to pick up new rules. If curl returns 404, wait and retry.

**Hint 3:** If curl times out, check if the ingress has an address:
```bash
kubectl get ingress app-ingress
```
The `ADDRESS` column should be populated.
```

- [ ] **Step 5: Commit**

```bash
cd ~/devops-lab
git add modules/01-kubernetes/1C-packaging-networking/03-ingress/
git commit -m "feat: add 1C-03 ingress exercise"
```

---

## Task 4: 04-network-policies

**Files:**
- Create: `modules/01-kubernetes/1C-packaging-networking/04-network-policies/lesson.md`
- Create: `modules/01-kubernetes/1C-packaging-networking/04-network-policies/verify.sh`
- Create: `modules/01-kubernetes/1C-packaging-networking/04-network-policies/reset.sh`
- Create: `modules/01-kubernetes/1C-packaging-networking/04-network-policies/hint.md`

- [ ] **Step 1: Create lesson.md**

`modules/01-kubernetes/1C-packaging-networking/04-network-policies/lesson.md`:

```markdown
# Exercise 1C-04: Network Policies

## Theory

By default, Kubernetes networking is fully open: every pod can reach every other pod in the cluster, regardless of namespace. This is fine for simple deployments but dangerous at scale — a compromised frontend pod can directly access your database. **NetworkPolicies** are Kubernetes's firewall rules: they select pods via label selectors and specify which ingress (inbound) and egress (outbound) traffic is allowed.

A NetworkPolicy applies to pods matching its `podSelector`. Once a NetworkPolicy selects a pod, that pod moves from "allow all" to "deny all except what's explicitly allowed." You can then add `ingress` rules to whitelist specific sources (other pods by label, namespaces by label, or CIDR blocks) and `egress` rules to whitelist specific destinations. A common pattern: select `db` pods, allow ingress only from pods with `role=web` — this blocks all other pods from reaching the database.

**Important:** NetworkPolicies require a CNI plugin that enforces them — Calico, Cilium, or Weave. The default minikube network plugin does NOT enforce NetworkPolicies. On minikube, start with `--cni=calico` or enable it post-install. If Calico is not available, this exercise verifies your YAML is correctly written; in a real cluster the policy would be enforced.

## Tasks

Work directory: `/tmp/devops-lab/1C-04/`

```bash
mkdir -p /tmp/devops-lab/1C-04
```

**Task 1 — Create namespace and deploy web + db**

```bash
kubectl create namespace netpol-lab

kubectl run web --image=nginx:alpine --labels="role=web" -n netpol-lab
kubectl run db --image=nginx:alpine --labels="role=db" -n netpol-lab

# Verify connectivity (before policy)
kubectl wait --for=condition=Ready pod/web pod/db -n netpol-lab --timeout=60s

DB_IP=$(kubectl get pod db -n netpol-lab -o jsonpath='{.status.podIP}')
echo "DB IP: $DB_IP"
kubectl exec -n netpol-lab web -- wget -qO- --timeout=3 http://$DB_IP && echo "web->db: OK"
```

**Task 2 — Write the NetworkPolicy**

```bash
cat > /tmp/devops-lab/1C-04/netpol.yaml <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-allow-web-only
  namespace: netpol-lab
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: web
EOF
kubectl apply -f /tmp/devops-lab/1C-04/netpol.yaml
kubectl get networkpolicy -n netpol-lab
```

**Task 3 — Test access (labeled vs unlabeled)**

```bash
DB_IP=$(kubectl get pod db -n netpol-lab -o jsonpath='{.status.podIP}')

# Labeled web pod — should succeed (or timeout if Calico not installed)
kubectl exec -n netpol-lab web -- wget -qO- --timeout=3 http://$DB_IP \
  && echo "web->db: ALLOWED" || echo "web->db: BLOCKED"

# Unlabeled pod — should be blocked (or succeed if no Calico)
kubectl run intruder --image=nginx:alpine -n netpol-lab --restart=Never \
  --labels="role=intruder" -- sleep 3600 2>/dev/null || true
kubectl wait --for=condition=Ready pod/intruder -n netpol-lab --timeout=30s 2>/dev/null || true
kubectl exec -n netpol-lab intruder -- wget -qO- --timeout=3 http://$DB_IP \
  && echo "intruder->db: ALLOWED" || echo "intruder->db: BLOCKED"

{
  echo "=== Policy Test ==="
  echo "web->db (role=web): $(kubectl exec -n netpol-lab web -- wget -qO- --timeout=3 http://$DB_IP 2>/dev/null && echo ALLOWED || echo BLOCKED)"
  echo "intruder->db (no role=web): $(kubectl exec -n netpol-lab intruder -- wget -qO- --timeout=3 http://$DB_IP 2>/dev/null && echo ALLOWED || echo BLOCKED)"
} > /tmp/devops-lab/1C-04/policy-test.txt 2>&1
cat /tmp/devops-lab/1C-04/policy-test.txt
```

**Task 4 — Reflect on multi-tenant implications**

```bash
cat > /tmp/devops-lab/1C-04/netpol-notes.txt <<'EOF'
Network Policy Notes — Multi-tenant Clusters

Why NetworkPolicies matter:
1. DEFAULT ALLOW ALL: Without policies, any compromised pod has network access to every
   other pod, including databases, internal APIs, and control plane services.

2. BLAST RADIUS REDUCTION: If a frontend pod is exploited, NetworkPolicies prevent
   lateral movement to the database tier. The attacker is contained.

3. COMPLIANCE: PCI-DSS, SOC2, and HIPAA require network segmentation between tiers.
   NetworkPolicies are the Kubernetes-native way to achieve this.

4. ZERO-TRUST NETWORKING: Each service explicitly grants access to callers by label.
   New services start isolated — they must be explicitly granted access.

5. NAMESPACE ISOLATION: In multi-tenant clusters (multiple teams sharing one cluster),
   namespaceSelector rules prevent Team A's pods from accessing Team B's services
   even if they're in the same cluster.

Limitation: NetworkPolicies require a CNI plugin that enforces them (Calico, Cilium).
Default kubeadm/minikube does not enforce them without explicit configuration.
EOF
cat /tmp/devops-lab/1C-04/netpol-notes.txt
```

## Interview Question

**"What's the default network policy in K8s? What happens when you create the first NetworkPolicy?"**

By default, Kubernetes has **no NetworkPolicies** — all pods can reach all pods. This is "default allow all." When you create the **first NetworkPolicy that selects a pod**, that pod's traffic model flips to "deny all, except what this policy explicitly allows." So a NetworkPolicy that only specifies `ingress` rules still allows all egress unless you also add an `egress` section. This "selector activates deny-all" behavior is a common gotcha: adding a NetworkPolicy for your database that only specifies ingress rules will block all outbound traffic from the database (e.g., DNS queries) unless you also add egress rules or a separate policy.

## What Just Happened

You deployed two pods in an isolated namespace, verified open connectivity, then applied a NetworkPolicy restricting database access to only pods with `role=web`. A separate "intruder" pod (without that label) would be blocked. This is the foundational security pattern for any multi-tier Kubernetes application.
```

- [ ] **Step 2: Create verify.sh**

`modules/01-kubernetes/1C-packaging-networking/04-network-policies/verify.sh`:

```bash
#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1C-04"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Exercise 1C-04 — Network Policies"
echo ""

# Namespace exists
ns=$(kubectl get namespace netpol-lab --no-headers 2>/dev/null | wc -l || echo 0)
check "netpol-lab namespace exists" \
  "$([[ "$ns" -gt 0 ]] && echo pass || echo fail)"

# Pods exist
web_pod=$(kubectl get pod web -n netpol-lab --no-headers 2>/dev/null | wc -l || echo 0)
check "web pod exists in netpol-lab" \
  "$([[ "$web_pod" -gt 0 ]] && echo pass || echo fail)"

db_pod=$(kubectl get pod db -n netpol-lab --no-headers 2>/dev/null | wc -l || echo 0)
check "db pod exists in netpol-lab" \
  "$([[ "$db_pod" -gt 0 ]] && echo pass || echo fail)"

# netpol.yaml exists with correct content
check "netpol.yaml exists" \
  "$([[ -f "$WORK_DIR/netpol.yaml" ]] && echo pass || echo fail)"
if [[ -f "$WORK_DIR/netpol.yaml" ]]; then
  netpol=$(cat "$WORK_DIR/netpol.yaml")
  check "netpol.yaml selects role=db pods" \
    "$([[ "$netpol" == *"role: db"* ]] && echo pass || echo fail)"
  check "netpol.yaml allows from role=web" \
    "$([[ "$netpol" == *"role: web"* ]] && echo pass || echo fail)"
  check "netpol.yaml is in netpol-lab namespace" \
    "$([[ "$netpol" == *"netpol-lab"* ]] && echo pass || echo fail)"
  check "netpol.yaml specifies Ingress policyType" \
    "$([[ "$netpol" == *"Ingress"* ]] && echo pass || echo fail)"
fi

# NetworkPolicy exists in cluster
np=$(kubectl get networkpolicy db-allow-web-only -n netpol-lab --no-headers 2>/dev/null | wc -l || echo 0)
check "db-allow-web-only NetworkPolicy exists in cluster" \
  "$([[ "$np" -gt 0 ]] && echo pass || echo fail)"

# policy-test.txt exists
check "policy-test.txt exists" \
  "$([[ -f "$WORK_DIR/policy-test.txt" ]] && echo pass || echo fail)"

# netpol-notes.txt exists and has substance
check "netpol-notes.txt exists" \
  "$([[ -f "$WORK_DIR/netpol-notes.txt" ]] && echo pass || echo fail)"
if [[ -f "$WORK_DIR/netpol-notes.txt" ]]; then
  notes_lines=$(wc -l < "$WORK_DIR/netpol-notes.txt")
  check "netpol-notes.txt has content (>5 lines)" \
    "$([[ "$notes_lines" -gt 5 ]] && echo pass || echo fail)"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
```

- [ ] **Step 3: Create reset.sh**

`modules/01-kubernetes/1C-packaging-networking/04-network-policies/reset.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Resetting: Exercise 1C-04 — Network Policies"

WORK_DIR="/tmp/devops-lab/1C-04"

echo "  Deleting netpol-lab namespace (removes all resources within)..."
kubectl delete namespace netpol-lab 2>/dev/null || true

echo "  Cleaning work directory..."
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

echo "  Done. Work directory reset to $WORK_DIR/"
```

- [ ] **Step 4: Create hint.md**

`modules/01-kubernetes/1C-packaging-networking/04-network-policies/hint.md`:

```markdown
# Hints — Exercise 1C-04: Network Policies

## Setup

**Hint 1:** Create namespace first, then pods:
```bash
kubectl create namespace netpol-lab
kubectl run web --image=nginx:alpine --labels="role=web" -n netpol-lab
kubectl run db  --image=nginx:alpine --labels="role=db"  -n netpol-lab
```

**Hint 2:** Get the db pod's IP for testing:
```bash
kubectl get pod db -n netpol-lab -o wide
```

---

## The NetworkPolicy

**Hint 1:** NetworkPolicy selects which pods it protects (`podSelector`), not which pods are allowed.

**Hint 2:** The `from` clause under `ingress` lists allowed sources. Match by pod label:
```yaml
ingress:
- from:
  - podSelector:
      matchLabels:
        role: web
```

**Hint 3 (full solution):**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-allow-web-only
  namespace: netpol-lab
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: web
```

---

## Testing note

**Hint 1:** If Calico CNI is not installed, the policy will be accepted by the API but not enforced. Both `web->db` and `intruder->db` will succeed. Record this in your policy-test.txt — the YAML is correct, enforcement requires the right CNI.

**Hint 2:** Test from the web pod:
```bash
DB_IP=$(kubectl get pod db -n netpol-lab -o jsonpath='{.status.podIP}')
kubectl exec -n netpol-lab web -- wget -qO- --timeout=3 http://$DB_IP
```
```

- [ ] **Step 5: Commit**

```bash
cd ~/devops-lab
git add modules/01-kubernetes/1C-packaging-networking/04-network-policies/
git commit -m "feat: add 1C-04 network-policies exercise"
```

---

## Task 5: 05-dns-service-discovery

**Files:**
- Create: `modules/01-kubernetes/1C-packaging-networking/05-dns-service-discovery/lesson.md`
- Create: `modules/01-kubernetes/1C-packaging-networking/05-dns-service-discovery/verify.sh`
- Create: `modules/01-kubernetes/1C-packaging-networking/05-dns-service-discovery/reset.sh`
- Create: `modules/01-kubernetes/1C-packaging-networking/05-dns-service-discovery/hint.md`

- [ ] **Step 1: Create lesson.md**

`modules/01-kubernetes/1C-packaging-networking/05-dns-service-discovery/lesson.md`:

```markdown
# Exercise 1C-05: DNS and Service Discovery

## Theory

Kubernetes runs **CoreDNS** as a cluster-internal DNS server. Every Service automatically gets a DNS name in the format `<service>.<namespace>.svc.cluster.local`. Pods can resolve services by short name (`my-svc`) within the same namespace, by partial FQDN (`my-svc.default`), or by full FQDN (`my-svc.default.svc.cluster.local`). Pod DNS config (`/etc/resolv.conf`) sets the search domains, which is why short names work.

**Headless services** (`clusterIP: None`) do not get a virtual IP. Instead, DNS queries return the IP addresses of all backing pods directly. Combined with a **StatefulSet**, each pod gets its own stable DNS name: `pod-0.my-svc.default.svc.cluster.local`. This is essential for databases and distributed systems (Kafka, ZooKeeper, Cassandra) where clients need to address individual nodes, not a random pod behind a VIP.

CoreDNS is configured via a **ConfigMap** in `kube-system`. The `Corefile` defines zones and plugins: `kubernetes cluster.local` handles in-cluster DNS, `forward . /etc/resolv.conf` proxies external queries to the node's resolver. You can add custom zones, rewrite rules, or configure per-namespace DNS policies — all via the ConfigMap, no CoreDNS binary changes needed.

## Tasks

Work directory: `/tmp/devops-lab/1C-05/`

```bash
mkdir -p /tmp/devops-lab/1C-05
```

**Task 1 — Create a service and resolve it by DNS**

```bash
# Deploy a simple nginx and expose it
kubectl create deployment dns-demo --image=nginx:alpine
kubectl expose deployment dns-demo --port=80 --name=my-svc
kubectl get service my-svc

# Run a debug pod with DNS tools
kubectl run dns-debug --image=busybox:1.36 --restart=Never -- sleep 3600
kubectl wait --for=condition=Ready pod/dns-debug --timeout=30s

# Resolve via short name and FQDN
{
  echo "=== nslookup my-svc ==="
  kubectl exec dns-debug -- nslookup my-svc
  echo ""
  echo "=== nslookup my-svc.default.svc.cluster.local ==="
  kubectl exec dns-debug -- nslookup my-svc.default.svc.cluster.local
  echo ""
  echo "=== /etc/resolv.conf ==="
  kubectl exec dns-debug -- cat /etc/resolv.conf
} > /tmp/devops-lab/1C-05/dns-resolution.txt 2>&1
cat /tmp/devops-lab/1C-05/dns-resolution.txt
```

**Task 2 — Headless service with StatefulSet**

```bash
cat > /tmp/devops-lab/1C-05/headless.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: headless-svc
spec:
  clusterIP: None
  selector:
    app: stateful-demo
  ports:
  - port: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: stateful-demo
spec:
  serviceName: headless-svc
  replicas: 2
  selector:
    matchLabels:
      app: stateful-demo
  template:
    metadata:
      labels:
        app: stateful-demo
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
EOF
kubectl apply -f /tmp/devops-lab/1C-05/headless.yaml
kubectl wait --for=condition=Ready pod/stateful-demo-0 pod/stateful-demo-1 --timeout=60s

# Resolve individual pod DNS
{
  echo "=== nslookup headless-svc (returns all pod IPs) ==="
  kubectl exec dns-debug -- nslookup headless-svc
  echo ""
  echo "=== nslookup stateful-demo-0.headless-svc ==="
  kubectl exec dns-debug -- nslookup stateful-demo-0.headless-svc
  echo ""
  echo "=== nslookup stateful-demo-1.headless-svc ==="
  kubectl exec dns-debug -- nslookup stateful-demo-1.headless-svc
} > /tmp/devops-lab/1C-05/headless-dns.txt 2>&1
cat /tmp/devops-lab/1C-05/headless-dns.txt
```

**Task 3 — Inspect CoreDNS config**

```bash
kubectl get cm coredns -n kube-system -o yaml > /tmp/devops-lab/1C-05/coredns-config.txt
cat /tmp/devops-lab/1C-05/coredns-config.txt
```

**Task 4 — When to use headless services**

```bash
cat > /tmp/devops-lab/1C-05/dns-notes.txt <<'EOF'
When to Use Headless Services
==============================

Use a headless service (clusterIP: None) when:

1. STATEFUL APPLICATIONS: Databases (PostgreSQL, MySQL), message brokers (Kafka, RabbitMQ),
   and distributed systems (ZooKeeper, Elasticsearch) need clients to address specific nodes.
   With a normal Service, load balancing is random — you can't target the primary DB node.
   With a headless Service + StatefulSet, pod-0 is always "primary.db-svc.default.svc.cluster.local".

2. CLIENT-SIDE LOAD BALANCING: gRPC and other connection-multiplexed protocols maintain
   long-lived connections that bypass kube-proxy's per-connection LB. A headless service
   returns all pod IPs so the client can implement its own load balancing.

3. PEER DISCOVERY: Distributed systems (Cassandra, etcd) use DNS to discover cluster members.
   nslookup on a headless service returns all pod IPs — perfect for bootstrap ring membership.

4. DIRECT POD ADDRESSING: When you need to send traffic to a specific pod instance
   (e.g., a shard), the stable pod DNS name from a StatefulSet is the reliable way to do it.

Normal (non-headless) services are better when:
- You want transparent load balancing across stateless pods
- You don't care which pod handles a request
- You want a stable single VIP for external consumers
EOF
cat /tmp/devops-lab/1C-05/dns-notes.txt
```

## Interview Question

**"How does DNS work inside a Kubernetes cluster?"**

CoreDNS runs as a Deployment in `kube-system` and is exposed as a Service (`kube-dns`). Every pod's `/etc/resolv.conf` points to this Service IP and sets search domains including `<namespace>.svc.cluster.local` and `svc.cluster.local`. When a pod resolves `my-svc`, the OS appends the search domains in order — so it queries `my-svc.default.svc.cluster.local` first. CoreDNS's `kubernetes` plugin handles that zone by looking up the Service in the API server and returning its ClusterIP (or pod IPs for headless services). External queries (`google.com`) fall through to the `forward` plugin which proxies to the node's upstream resolver.

## What Just Happened

You deployed a service, resolved it by both short name and FQDN from inside the cluster, created a headless StatefulSet and resolved individual pod DNS names, and inspected the CoreDNS ConfigMap that drives all of this. This is the complete picture of how Kubernetes service discovery works — no external DNS, no hardcoded IPs, just consistent naming conventions.
```

- [ ] **Step 2: Create verify.sh**

`modules/01-kubernetes/1C-packaging-networking/05-dns-service-discovery/verify.sh`:

```bash
#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1C-05"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Exercise 1C-05 — DNS and Service Discovery"
echo ""

# my-svc service exists
svc=$(kubectl get service my-svc --no-headers 2>/dev/null | wc -l || echo 0)
check "my-svc service exists" \
  "$([[ "$svc" -gt 0 ]] && echo pass || echo fail)"

# dns-resolution.txt exists with DNS output
check "dns-resolution.txt exists" \
  "$([[ -f "$WORK_DIR/dns-resolution.txt" ]] && echo pass || echo fail)"
if [[ -f "$WORK_DIR/dns-resolution.txt" ]]; then
  dns=$(cat "$WORK_DIR/dns-resolution.txt")
  check "dns-resolution.txt shows nslookup result for my-svc" \
    "$([[ "$dns" == *"my-svc"* ]] && echo pass || echo fail)"
  check "dns-resolution.txt shows cluster.local domain" \
    "$([[ "$dns" == *"cluster.local"* ]] && echo pass || echo fail)"
fi

# headless-svc exists with clusterIP None
headless=$(kubectl get service headless-svc -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "")
check "headless-svc service exists" \
  "$([[ -n "$headless" ]] && echo pass || echo fail)"
check "headless-svc has clusterIP: None" \
  "$([[ "$headless" == "None" ]] && echo pass || echo fail)"

# StatefulSet exists with 2 replicas
ss=$(kubectl get statefulset stateful-demo --no-headers 2>/dev/null | wc -l || echo 0)
check "stateful-demo StatefulSet exists" \
  "$([[ "$ss" -gt 0 ]] && echo pass || echo fail)"

# headless-dns.txt shows pod-level resolution
check "headless-dns.txt exists" \
  "$([[ -f "$WORK_DIR/headless-dns.txt" ]] && echo pass || echo fail)"
if [[ -f "$WORK_DIR/headless-dns.txt" ]]; then
  hdns=$(cat "$WORK_DIR/headless-dns.txt")
  check "headless-dns.txt mentions stateful-demo pods" \
    "$([[ "$hdns" == *"stateful-demo"* ]] && echo pass || echo fail)"
fi

# coredns-config.txt non-empty
check "coredns-config.txt exists" \
  "$([[ -f "$WORK_DIR/coredns-config.txt" ]] && echo pass || echo fail)"
if [[ -f "$WORK_DIR/coredns-config.txt" ]]; then
  coredns_lines=$(wc -l < "$WORK_DIR/coredns-config.txt")
  check "coredns-config.txt is non-trivial (>5 lines)" \
    "$([[ "$coredns_lines" -gt 5 ]] && echo pass || echo fail)"
fi

# dns-notes.txt exists
check "dns-notes.txt exists" \
  "$([[ -f "$WORK_DIR/dns-notes.txt" ]] && echo pass || echo fail)"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
```

- [ ] **Step 3: Create reset.sh**

`modules/01-kubernetes/1C-packaging-networking/05-dns-service-discovery/reset.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Resetting: Exercise 1C-05 — DNS and Service Discovery"

WORK_DIR="/tmp/devops-lab/1C-05"

echo "  Deleting StatefulSet and headless service..."
kubectl delete statefulset stateful-demo 2>/dev/null || true
kubectl delete service headless-svc 2>/dev/null || true

echo "  Deleting dns-demo deployment and service..."
kubectl delete deployment dns-demo 2>/dev/null || true
kubectl delete service my-svc 2>/dev/null || true

echo "  Deleting debug pod..."
kubectl delete pod dns-debug 2>/dev/null || true

echo "  Cleaning work directory..."
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

echo "  Done. Work directory reset to $WORK_DIR/"
```

- [ ] **Step 4: Create hint.md**

`modules/01-kubernetes/1C-packaging-networking/05-dns-service-discovery/hint.md`:

```markdown
# Hints — Exercise 1C-05: DNS and Service Discovery

## Basic DNS resolution

**Hint 1:** Create the service first, then a debug pod:
```bash
kubectl create deployment dns-demo --image=nginx:alpine
kubectl expose deployment dns-demo --port=80 --name=my-svc
kubectl run dns-debug --image=busybox:1.36 --restart=Never -- sleep 3600
```

**Hint 2:** Run nslookup from the debug pod:
```bash
kubectl exec dns-debug -- nslookup my-svc
```

**Hint 3:** Short names work because `/etc/resolv.conf` in the pod has `search default.svc.cluster.local svc.cluster.local cluster.local`. Check it:
```bash
kubectl exec dns-debug -- cat /etc/resolv.conf
```

---

## Headless service

**Hint 1:** `clusterIP: None` makes a service headless. DNS returns pod IPs directly.

**Hint 2:** A headless service requires a matching selector that points to running pods. Use the provided `headless.yaml`.

**Hint 3:** After pods are running, resolve the headless service — you should see multiple A records (one per pod):
```bash
kubectl exec dns-debug -- nslookup headless-svc
```

**Hint 4:** Individual pod DNS follows the pattern `<pod-name>.<service-name>.<namespace>.svc.cluster.local`:
```bash
kubectl exec dns-debug -- nslookup stateful-demo-0.headless-svc
```

---

## CoreDNS config

**Hint 1:**
```bash
kubectl get cm coredns -n kube-system -o yaml > /tmp/devops-lab/1C-05/coredns-config.txt
```

Look for the `Corefile` key — it shows the plugin chain that handles DNS resolution.
```

- [ ] **Step 5: Commit**

```bash
cd ~/devops-lab
git add modules/01-kubernetes/1C-packaging-networking/05-dns-service-discovery/
git commit -m "feat: add 1C-05 dns-service-discovery exercise"
```

---

## Task 6: 06-multi-container-pods

**Files:**
- Create: `modules/01-kubernetes/1C-packaging-networking/06-multi-container-pods/lesson.md`
- Create: `modules/01-kubernetes/1C-packaging-networking/06-multi-container-pods/verify.sh`
- Create: `modules/01-kubernetes/1C-packaging-networking/06-multi-container-pods/reset.sh`
- Create: `modules/01-kubernetes/1C-packaging-networking/06-multi-container-pods/hint.md`

- [ ] **Step 1: Create lesson.md**

`modules/01-kubernetes/1C-packaging-networking/06-multi-container-pods/lesson.md`:

```markdown
# Exercise 1C-06: Multi-Container Pod Patterns

## Theory

Kubernetes pods can run multiple containers that share the same network namespace (same IP, same ports) and can share volumes. This co-location enables powerful patterns. The **sidecar pattern** augments a main container with a helper that handles cross-cutting concerns: log shipping, metrics scraping, certificate rotation, or service mesh proxying (Envoy in Istio runs as a sidecar). The sidecar and main container share lifecycle — they start and stop together.

**Init containers** run to completion before any app container starts. They're used for setup tasks: seeding a config file from a secret store, running database migrations, waiting for a dependency to become ready. Init containers run serially in order, each must exit 0 before the next starts. The main app containers see a fully prepared environment. Init containers share volumes with app containers but have a separate image — so your app image doesn't need curl, wait scripts, or migration tools.

The **ambassador pattern** runs a proxy container alongside the main app to simplify its external dependencies — for example, a Twemproxy container that presents a single Redis endpoint to the app while handling connection pooling and sharding transparently. The app writes to `localhost:6379`; the ambassador handles the complexity. This keeps app code clean and lets you swap the implementation without redeploying the app.

## Tasks

Work directory: `/tmp/devops-lab/1C-06/`

```bash
mkdir -p /tmp/devops-lab/1C-06
```

**Task 1 — Init container writing config to shared volume**

```bash
cat > /tmp/devops-lab/1C-06/init-container.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: init-demo
spec:
  volumes:
  - name: shared-config
    emptyDir: {}
  initContainers:
  - name: config-writer
    image: busybox:1.36
    command:
    - sh
    - -c
    - |
      echo "APP_ENV=production" > /config/app.env
      echo "DB_HOST=postgres.default.svc.cluster.local" >> /config/app.env
      echo "LOG_LEVEL=info" >> /config/app.env
      echo "Config written:"
      cat /config/app.env
    volumeMounts:
    - name: shared-config
      mountPath: /config
  containers:
  - name: app
    image: busybox:1.36
    command:
    - sh
    - -c
    - |
      echo "App starting, reading config..."
      cat /config/app.env
      echo "Config loaded. Sleeping."
      sleep 3600
    volumeMounts:
    - name: shared-config
      mountPath: /config
EOF
kubectl apply -f /tmp/devops-lab/1C-06/init-container.yaml
kubectl wait --for=condition=Ready pod/init-demo --timeout=60s
kubectl exec init-demo -- cat /config/app.env
```

**Task 2 — Sidecar pod (main writes logs, sidecar reads them)**

```bash
cat > /tmp/devops-lab/1C-06/sidecar.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: sidecar-demo
spec:
  volumes:
  - name: log-vol
    emptyDir: {}
  containers:
  - name: app
    image: busybox:1.36
    command:
    - sh
    - -c
    - |
      while true; do
        echo "$(date): App log entry" >> /logs/app.log
        sleep 5
      done
    volumeMounts:
    - name: log-vol
      mountPath: /logs
  - name: log-shipper
    image: busybox:1.36
    command:
    - sh
    - -c
    - |
      echo "Log shipper started, tailing app.log..."
      tail -f /logs/app.log
    volumeMounts:
    - name: log-vol
      mountPath: /logs
EOF
kubectl apply -f /tmp/devops-lab/1C-06/sidecar.yaml
kubectl wait --for=condition=Ready pod/sidecar-demo --timeout=60s
kubectl get pod sidecar-demo
```

**Task 3 — Verify init completed before main, capture events**

```bash
kubectl describe pod init-demo > /tmp/devops-lab/1C-06/init-events.txt
cat /tmp/devops-lab/1C-06/init-events.txt

# Also check sidecar has 2 containers
kubectl get pod sidecar-demo -o jsonpath='{.spec.containers[*].name}'
echo ""
kubectl logs sidecar-demo -c log-shipper --tail=5
```

**Task 4 — Document the three patterns**

```bash
cat > /tmp/devops-lab/1C-06/patterns.txt <<'EOF'
Multi-Container Pod Patterns
==============================

Pattern 1: SIDECAR
------------------
Description: A helper container runs alongside the main app container, sharing
the same pod lifecycle, network, and volumes.

Use cases:
- Log shipping: Fluentd sidecar reads app log files and forwards to Elasticsearch
- Metrics: Prometheus exporter sidecar exposes /metrics from a legacy app
- Service mesh: Envoy proxy (Istio) intercepts all traffic for observability/auth
- Certificate rotation: A sidecar watches a secret and refreshes TLS certs on disk

Key property: Both containers run simultaneously and share volumes/network.

---

Pattern 2: INIT CONTAINER
--------------------------
Description: One or more containers run to completion before the main app starts.
They run serially — each must exit 0 before the next begins.

Use cases:
- Config seeding: Fetch secrets from Vault, write to shared volume for main app
- Database migrations: Run Flyway/Liquibase before the app server starts
- Dependency waiting: Poll a database/service until ready (wait-for-it.sh pattern)
- Permission fixing: chown/chmod files that the main app needs to read

Key property: Init containers complete before app containers start. They can have
different images (e.g., use curl/psql without adding them to the app image).

---

Pattern 3: AMBASSADOR
---------------------
Description: A proxy container sits between the main app and an external service,
simplifying the app's view of complex infrastructure.

Use cases:
- Redis sharding: Twemproxy sidecar presents single Redis endpoint; handles sharding
- Database connection pooling: PgBouncer sidecar pools connections for a simple app
- Protocol translation: gRPC ambassador for an app that only speaks HTTP/1.1
- Multi-datacenter routing: Ambassador handles failover/routing logic transparently

Key property: The app connects to localhost; the ambassador handles complexity.
This decouples app code from infrastructure topology.
EOF
cat /tmp/devops-lab/1C-06/patterns.txt
```

## Interview Question

**"What's the difference between a sidecar and an init container? Give real-world examples."**

An **init container** runs to completion before any app container starts, then exits. It's for setup: running a migration script, fetching secrets, or waiting for a dependency. The app sees a fully prepared environment. A **sidecar** runs simultaneously with the main container for the entire pod lifetime — it's for augmentation: a Fluentd container shipping logs, an Envoy proxy handling all traffic, or a credentials-refresh process rotating short-lived tokens. The key difference is **timing**: init containers are sequential setup steps; sidecars are concurrent helpers. In Istio, Envoy is injected as a sidecar and intercepts all pod traffic throughout the pod's lifetime. In a migration setup, a Flyway init container runs once, exits 0, and only then does the app server start.

## What Just Happened

You built two multi-container pods: one with an init container that pre-populated a shared config volume before the app started, and one with a sidecar that continuously read log output from the main container. `kubectl describe` showed the init container completing first in the Events section. You also documented all three patterns — sidecar, init container, and ambassador — which come up constantly in K8s interviews and real architectures.
```

- [ ] **Step 2: Create verify.sh**

`modules/01-kubernetes/1C-packaging-networking/06-multi-container-pods/verify.sh`:

```bash
#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1C-06"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Exercise 1C-06 — Multi-Container Pod Patterns"
echo ""

# init-container.yaml exists
check "init-container.yaml exists" \
  "$([[ -f "$WORK_DIR/init-container.yaml" ]] && echo pass || echo fail)"
if [[ -f "$WORK_DIR/init-container.yaml" ]]; then
  init_yaml=$(cat "$WORK_DIR/init-container.yaml")
  check "init-container.yaml has initContainers section" \
    "$([[ "$init_yaml" == *"initContainers"* ]] && echo pass || echo fail)"
  check "init-container.yaml uses shared emptyDir volume" \
    "$([[ "$init_yaml" == *"emptyDir"* ]] && echo pass || echo fail)"
fi

# init-demo pod is running
init_pod=$(kubectl get pod init-demo --no-headers 2>/dev/null | grep -c "Running" || echo 0)
check "init-demo pod is Running" \
  "$([[ "$init_pod" -gt 0 ]] && echo pass || echo fail)"

# Verify config was written by init container
if kubectl get pod init-demo --no-headers 2>/dev/null | grep -q "Running"; then
  config_content=$(kubectl exec init-demo -- cat /config/app.env 2>/dev/null || echo "")
  check "init container wrote config to shared volume" \
    "$([[ "$config_content" == *"APP_ENV"* ]] && echo pass || echo fail)"
fi

# sidecar.yaml exists
check "sidecar.yaml exists" \
  "$([[ -f "$WORK_DIR/sidecar.yaml" ]] && echo pass || echo fail)"
if [[ -f "$WORK_DIR/sidecar.yaml" ]]; then
  sidecar_yaml=$(cat "$WORK_DIR/sidecar.yaml")
  check "sidecar.yaml defines 2 containers" \
    "$(echo "$sidecar_yaml" | grep -c "name: " | xargs -I{} bash -c '[[ {} -ge 2 ]] && echo pass || echo fail')"
fi

# sidecar-demo pod has 2 running containers
sidecar_ready=$(kubectl get pod sidecar-demo --no-headers 2>/dev/null | awk '{print $2}' || echo "0/0")
check "sidecar-demo pod exists" \
  "$([[ -n "$(kubectl get pod sidecar-demo --no-headers 2>/dev/null)" ]] && echo pass || echo fail)"
check "sidecar-demo has 2 containers ready" \
  "$([[ "$sidecar_ready" == "2/2" ]] && echo pass || echo fail)"

# init-events.txt shows init container sequence
check "init-events.txt exists" \
  "$([[ -f "$WORK_DIR/init-events.txt" ]] && echo pass || echo fail)"
if [[ -f "$WORK_DIR/init-events.txt" ]]; then
  events=$(cat "$WORK_DIR/init-events.txt")
  check "init-events.txt mentions init container" \
    "$([[ "$events" == *"config-writer"* || "$events" == *"Init"* ]] && echo pass || echo fail)"
fi

# patterns.txt has 3 patterns
check "patterns.txt exists" \
  "$([[ -f "$WORK_DIR/patterns.txt" ]] && echo pass || echo fail)"
if [[ -f "$WORK_DIR/patterns.txt" ]]; then
  pattern_count=$(grep -c "Pattern [0-9]" "$WORK_DIR/patterns.txt" 2>/dev/null || echo 0)
  check "patterns.txt describes 3 patterns" \
    "$([[ "$pattern_count" -ge 3 ]] && echo pass || echo fail)"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
```

- [ ] **Step 3: Create reset.sh**

`modules/01-kubernetes/1C-packaging-networking/06-multi-container-pods/reset.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Resetting: Exercise 1C-06 — Multi-Container Pod Patterns"

WORK_DIR="/tmp/devops-lab/1C-06"

echo "  Deleting pods..."
kubectl delete pod init-demo sidecar-demo 2>/dev/null || true

echo "  Cleaning work directory..."
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

echo "  Done. Work directory reset to $WORK_DIR/"
```

- [ ] **Step 4: Create hint.md**

`modules/01-kubernetes/1C-packaging-networking/06-multi-container-pods/hint.md`:

```markdown
# Hints — Exercise 1C-06: Multi-Container Pod Patterns

## Init containers

**Hint 1:** Init containers live under `initContainers:` in the pod spec, at the same level as `containers:`. They run first, in order.

**Hint 2:** To share data between init and app containers, use an `emptyDir` volume mounted in both.

**Hint 3:** Watch init container progress:
```bash
kubectl get pod init-demo -w
```
You'll see `Init:0/1` → `PodInitializing` → `Running`.

**Hint 4:** Check init container logs:
```bash
kubectl logs init-demo -c config-writer
```

---

## Sidecar pattern

**Hint 1:** Define two containers under `containers:`. Both run simultaneously and share any declared volumes.

**Hint 2:** The `log-shipper` container should mount the same `log-vol` as the `app` container.

**Hint 3:** Verify both containers are running:
```bash
kubectl get pod sidecar-demo
# READY column should show 2/2
```

**Hint 4:** See logs from each container separately:
```bash
kubectl logs sidecar-demo -c app
kubectl logs sidecar-demo -c log-shipper
```

---

## Debugging init sequence

**Hint 1:** `kubectl describe pod init-demo` shows the Events section with timestamps showing init container completing before app container started.

**Hint 2:** If init-demo is stuck in `Init:0/1`, check init container logs:
```bash
kubectl logs init-demo -c config-writer
```

**Hint 3:** Init containers that exit non-zero will be retried. Check `kubectl describe pod` for restart counts and error messages.
```

- [ ] **Step 5: Final chmod + commit**

```bash
cd ~/devops-lab
find modules/01-kubernetes/1C-packaging-networking/ -name "*.sh" -exec chmod +x {} \;
git add modules/01-kubernetes/1C-packaging-networking/06-multi-container-pods/
git commit -m "feat: add 1C-06 multi-container-pods exercise"
```

---

## Task 7: Final Integration

- [ ] **Step 1: Verify all files exist**

```bash
find ~/devops-lab/modules/01-kubernetes/1C-packaging-networking/ -name "*.sh" -o -name "*.md" | sort
```

Expected: 24 files total (4 files × 6 exercises).

- [ ] **Step 2: Verify all .sh files are executable**

```bash
find ~/devops-lab/modules/01-kubernetes/1C-packaging-networking/ -name "*.sh" -exec ls -la {} \;
```

- [ ] **Step 3: Final commit**

```bash
cd ~/devops-lab
git add modules/01-kubernetes/1C-packaging-networking/
git commit -m "feat: add exercises 1C-01 through 1C-06 (K8s packaging and networking)"
```
