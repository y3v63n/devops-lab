# Exercise 1D-02: Capstone — Custom Helm Chart (`blockchain-monitor`)

## Theory

### Why Package as a Helm Chart?

Deploying a monitoring stack by running a sequence of `kubectl apply` and `helm install` commands works once, but it does not scale. If a teammate wants to deploy the same stack in their environment, they need to reproduce every step in the right order. If you want separate dev, staging, and prod deployments with slightly different settings, you need to track those differences somewhere.

A **Helm chart** bundles all Kubernetes manifests and Helm sub-chart dependencies into a single versioned artefact. Values files provide the customisation layer — a single chart can deploy to any environment, with environment-specific values passed at install time:

```
helm install blockchain-monitor ./chart/ -f values-prod.yaml
helm install blockchain-monitor ./chart/ -f values-staging.yaml
```

### Chart Anatomy

```
blockchain-monitor/
├── Chart.yaml          # Chart metadata: name, version, description, dependencies
├── values.yaml         # Default values (overridden by -f or --set at install time)
├── templates/          # Go-template YAML files that render into Kubernetes manifests
│   ├── _helpers.tpl    # Named templates reused across other templates
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── NOTES.txt       # Printed after install — usage instructions
└── charts/             # Unpacked sub-chart dependencies (populated by helm dep update)
```

### Sub-chart Dependencies

Rather than copy-pasting Prometheus and Grafana YAML into your chart, you declare them as **dependencies** in `Chart.yaml`. When you run `helm dependency update`, Helm downloads those charts into the `charts/` directory. During install, Helm renders the parent chart and all sub-charts together. You configure sub-charts by nesting their values under the sub-chart name in `values.yaml`:

```yaml
# values.yaml
prometheus:
  server:
    retention: 2h

grafana:
  adminPassword: devops-lab
```

### Ingress

An Ingress resource routes HTTP traffic from outside the cluster to internal services. An Ingress controller (nginx, traefik, etc.) watches Ingress resources and programs its load balancer accordingly. In minikube, run `minikube addons enable ingress` to get the nginx Ingress controller. Ingress rules can route by host (`api.example.com`) or path (`/grafana`).

### Multi-Environment Management

The recommended pattern is one chart + one values file per environment:

```
environments/
  dev.yaml      # low replicas, short retention, debug logging
  staging.yaml  # production-like but smaller instance sizes
  prod.yaml     # full replicas, long retention, strict resource limits
```

CI/CD pipelines select the right values file based on the deployment target branch.

---

## Tasks

Work directory: `/tmp/devops-lab/1D-02/`

### Task 1 — Scaffold the Chart

```bash
mkdir -p /tmp/devops-lab/1D-02
cd /tmp/devops-lab/1D-02
helm create blockchain-monitor
```

This creates the chart skeleton at `/tmp/devops-lab/1D-02/blockchain-monitor/`.

Inspect the generated structure:
```bash
find /tmp/devops-lab/1D-02/blockchain-monitor -type f | sort
```

### Task 2 — Configure Chart.yaml with Dependencies

Replace `/tmp/devops-lab/1D-02/blockchain-monitor/Chart.yaml` with:

```yaml
apiVersion: v2
name: blockchain-monitor
description: >
  Full observability stack for blockchain validator nodes.
  Deploys Prometheus (metrics collection), Grafana (visualisation),
  and a health-checker service with a Prometheus-scrapeable /metrics endpoint.
type: application
version: 0.1.0
appVersion: "1.0.0"

dependencies:
  - name: prometheus
    version: "25.x.x"
    repository: https://prometheus-community.github.io/helm-charts
    condition: prometheus.enabled

  - name: grafana
    version: "7.x.x"
    repository: https://grafana.github.io/helm-charts
    condition: grafana.enabled
```

Pull the dependencies:
```bash
cd /tmp/devops-lab/1D-02/blockchain-monitor
helm dependency update
```

### Task 3 — Write values.yaml

Replace `/tmp/devops-lab/1D-02/blockchain-monitor/values.yaml` with:

```yaml
# ── Health Checker ─────────────────────────────────────────────────────────────
replicaCount: 1

image:
  repository: nginx
  tag: alpine
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 8080

# ── Ingress ────────────────────────────────────────────────────────────────────
ingress:
  enabled: true
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
  hosts:
    - host: ""
      paths:
        - path: /grafana(/|$)(.*)
          pathType: ImplementationSpecific
  tls: []

# ── Prometheus sub-chart values ────────────────────────────────────────────────
prometheus:
  enabled: true
  server:
    retention: 2h
    global:
      scrape_interval: 15s
  alertmanager:
    enabled: false
  prometheus-pushgateway:
    enabled: false

# ── Grafana sub-chart values ───────────────────────────────────────────────────
grafana:
  enabled: true
  adminPassword: devops-lab
  persistence:
    enabled: false
  service:
    type: ClusterIP
  datasources:
    datasources.yaml:
      apiVersion: 1
      datasources:
        - name: Prometheus
          type: prometheus
          url: http://{{ .Release.Name }}-prometheus-server
          access: proxy
          isDefault: true
```

### Task 4 — Add the Health Checker Template

Remove the default generated templates and add the health checker. Delete the generated deployment, service, hpa, serviceaccount templates and replace with targeted ones:

```bash
rm -f /tmp/devops-lab/1D-02/blockchain-monitor/templates/deployment.yaml
rm -f /tmp/devops-lab/1D-02/blockchain-monitor/templates/service.yaml
rm -f /tmp/devops-lab/1D-02/blockchain-monitor/templates/hpa.yaml
rm -f /tmp/devops-lab/1D-02/blockchain-monitor/templates/serviceaccount.yaml
rm -f /tmp/devops-lab/1D-02/blockchain-monitor/templates/ingress.yaml
```

Write `/tmp/devops-lab/1D-02/blockchain-monitor/templates/health-checker.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "blockchain-monitor.fullname" . }}-config
  labels:
    {{- include "blockchain-monitor.labels" . | nindent 4 }}
data:
  metrics: |
    # HELP node_health_status 1 if node is healthy, 0 if not
    # TYPE node_health_status gauge
    node_health_status{node="validator-1"} 1
    # HELP node_peer_count Current number of peers
    # TYPE node_peer_count gauge
    node_peer_count{node="validator-1"} 12
    # HELP node_sync_lag_seconds Seconds behind chain head
    # TYPE node_sync_lag_seconds gauge
    node_sync_lag_seconds{node="validator-1"} 0
  nginx.conf: |
    events {}
    http {
      server {
        listen 8080;
        location /metrics {
          default_type text/plain;
          alias /etc/nginx/metrics;
        }
        location /healthz {
          return 200 'ok\n';
          add_header Content-Type text/plain;
        }
      }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "blockchain-monitor.fullname" . }}-health-checker
  labels:
    {{- include "blockchain-monitor.labels" . | nindent 4 }}
    app.kubernetes.io/component: health-checker
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "blockchain-monitor.selectorLabels" . | nindent 6 }}
      app.kubernetes.io/component: health-checker
  template:
    metadata:
      labels:
        {{- include "blockchain-monitor.selectorLabels" . | nindent 8 }}
        app.kubernetes.io/component: health-checker
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      containers:
        - name: health-checker
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: metrics
              containerPort: 8080
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 10
          volumeMounts:
            - name: config
              mountPath: /etc/nginx/nginx.conf
              subPath: nginx.conf
            - name: config
              mountPath: /etc/nginx/metrics
              subPath: metrics
      volumes:
        - name: config
          configMap:
            name: {{ include "blockchain-monitor.fullname" . }}-config
---
apiVersion: v1
kind: Service
metadata:
  name: {{ include "blockchain-monitor.fullname" . }}-health-checker
  labels:
    {{- include "blockchain-monitor.labels" . | nindent 4 }}
    app.kubernetes.io/component: health-checker
spec:
  type: {{ .Values.service.type }}
  ports:
    - name: metrics
      port: {{ .Values.service.port }}
      targetPort: metrics
  selector:
    {{- include "blockchain-monitor.selectorLabels" . | nindent 4 }}
    app.kubernetes.io/component: health-checker
```

Write `/tmp/devops-lab/1D-02/blockchain-monitor/templates/ingress.yaml`:

```yaml
{{- if .Values.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "blockchain-monitor.fullname" . }}-grafana
  labels:
    {{- include "blockchain-monitor.labels" . | nindent 4 }}
  {{- with .Values.ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if .Values.ingress.className }}
  ingressClassName: {{ .Values.ingress.className }}
  {{- end }}
  rules:
    {{- range .Values.ingress.hosts }}
    - http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: {{ include "blockchain-monitor.fullname" $ }}-grafana
                port:
                  number: 80
          {{- end }}
    {{- end }}
{{- end }}
```

### Task 5 — Lint and Template Rendering

```bash
helm lint /tmp/devops-lab/1D-02/blockchain-monitor/
```

Render the templates and save to a file:
```bash
helm template blockchain-monitor /tmp/devops-lab/1D-02/blockchain-monitor/ \
  > /tmp/devops-lab/1D-02/rendered.yaml
```

Check the rendered output:
```bash
grep "^kind:" /tmp/devops-lab/1D-02/rendered.yaml | sort | uniq -c
```

You should see Deployments, Services, ConfigMaps, and an Ingress.

### Task 6 — Write the Chart README

Write `/tmp/devops-lab/1D-02/blockchain-monitor/README.md` — this file becomes your portfolio piece.

Include all six sections detailed in the task spec:
1. Project description
2. Features
3. Prerequisites
4. Install instructions
5. Customisation via values
6. Skills Demonstrated

See the full example below. You can expand it with your own notes, but include all sections.

**Example README:**

```markdown
# blockchain-monitor

A production-ready Helm chart that deploys a full observability stack for
blockchain validator node monitoring. Packages Prometheus, Grafana, and a
custom health-checker service into a single reusable chart.

## Features

- **Prometheus** — pull-based metrics collection with configurable retention and scrape interval
- **Grafana** — pre-wired to Prometheus; admin password set via values
- **Health Checker** — nginx pod exposing `/metrics` in Prometheus text format with validator node metrics
- **Ingress** — optional nginx Ingress routing Grafana to `/grafana`
- **Sub-chart dependencies** — Prometheus and Grafana managed as versioned Helm dependencies
- **Configurable** — replica counts, scrape interval, admin password, and component toggles all exposed in `values.yaml`

## Prerequisites

- Kubernetes 1.24+ (minikube works)
- Helm 3.x
- nginx Ingress controller (`minikube addons enable ingress` for local testing)

## Install

```bash
# Add required Helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana              https://grafana.github.io/helm-charts
helm repo update

# Pull sub-chart dependencies
helm dependency update ./blockchain-monitor

# Install into the monitoring namespace
kubectl create namespace monitoring
helm install blockchain-monitor ./blockchain-monitor -n monitoring
```

## Access Grafana

```bash
kubectl port-forward -n monitoring svc/blockchain-monitor-grafana 3000:80
# Open http://localhost:3000  (admin / devops-lab)
```

## Customisation

| Value | Default | Description |
|---|---|---|
| `replicaCount` | `1` | Health checker replica count |
| `prometheus.server.retention` | `2h` | Prometheus metric retention period |
| `prometheus.server.global.scrape_interval` | `15s` | How often Prometheus scrapes targets |
| `grafana.adminPassword` | `devops-lab` | Grafana admin password |
| `grafana.enabled` | `true` | Deploy Grafana |
| `prometheus.enabled` | `true` | Deploy Prometheus |
| `ingress.enabled` | `true` | Create Ingress for Grafana |

Override at install time:
```bash
helm install blockchain-monitor ./blockchain-monitor \
  --set grafana.adminPassword=mysecretpassword \
  --set prometheus.server.retention=7d
```

Or with an environment-specific values file:
```bash
helm install blockchain-monitor ./blockchain-monitor -f environments/prod.yaml
```

## Skills Demonstrated

- **Helm chart authoring** — Chart.yaml, values.yaml, Go-template manifests
- **Sub-chart dependencies** — declarative dependency management with `helm dep update`
- **Prometheus + Grafana integration** — datasource provisioning, scrape annotations
- **Kubernetes Ingress** — path-based routing with nginx rewrite rules
- **Environment management** — single chart deployable to dev/staging/prod via values files
- **Observability patterns** — pull-based monitoring model, Prometheus text format
```

Save this to `/tmp/devops-lab/1D-02/blockchain-monitor/README.md`.

---

## What Just Happened

You created a Helm chart from scratch that packages a complete monitoring stack as a versioned, reusable artefact. `helm create` gave you the scaffold — metadata, default templates, and a values file — which you then shaped to your use case.

By declaring Prometheus and Grafana as sub-chart dependencies in `Chart.yaml`, you avoided copy-pasting their entire manifest sets. `helm dependency update` downloaded those charts into `charts/`, and `helm template` rendered the whole tree — your templates plus every sub-chart — into a single YAML stream. `helm lint` ran a set of correctness checks (required fields, template syntax, deprecated APIs) before you ever touched a cluster.

The `values.yaml` file is the chart's public API. Any value in `values.yaml` can be overridden with `-f environment.yaml` or `--set key=value`. This is how the same chart drives multiple environments: CI/CD passes `environments/prod.yaml` for production and `environments/dev.yaml` for development, with different replica counts, resource limits, and retention periods. The chart itself never changes between environments.

---

## Interview Question

**"How would you manage multiple environments (dev, staging, prod) with the same Helm chart?"**

The standard pattern is one chart, multiple values files. The chart defines sane defaults in `values.yaml`. Separate files — `environments/dev.yaml`, `environments/staging.yaml`, `environments/prod.yaml` — each contain only the overrides relevant to that environment: lower replica counts and shorter retention in dev, production-sized resources and longer retention in prod.

CI/CD pipelines select the right file based on the target branch or deployment context:
```bash
helm upgrade --install blockchain-monitor ./chart \
  -n monitoring \
  -f environments/prod.yaml \
  --set image.tag=$CI_COMMIT_SHA
```

For more complex scenarios, Helmfile or ArgoCD ApplicationSets can manage the mapping of environments to value files declaratively, allowing you to see the full intended state of all environments in version control.

Secrets (database passwords, API keys) should never live in values files committed to git. Use `helm secrets` (backed by SOPS or Vault) or inject them from a secret manager at deploy time via `--set`.
