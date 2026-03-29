# Exercise 1D-01: Capstone — Monitoring Stack (Prometheus + Grafana)

## Theory

Production Kubernetes clusters generate a continuous stream of metrics: CPU, memory, pod restarts, request latency, error rates. **Prometheus** and **Grafana** are the industry-standard pair for collecting and visualising those metrics.

### The Pull-Based Model

Prometheus uses a **pull** (scrape) model. Rather than each application pushing data to a central server, Prometheus reaches out to each target on a configured interval and fetches a text-format snapshot of metrics from an HTTP endpoint — typically `/metrics`. This means:

- Targets do not need to know Prometheus's address.
- Prometheus knows immediately if a target is unreachable (scrape fails), which itself is a signal.
- You can test any target by just `curl`-ing its `/metrics` endpoint.

Contrast with **push-based** systems (e.g. StatsD, InfluxDB's Telegraf): each application sends data to a central aggregator. Push is simpler for short-lived jobs (a batch run that finishes before Prometheus scrapes) but couples the application to the monitoring backend.

### Blockchain Validator Use Case

A blockchain validator node exposes metrics such as:
- `validator_attestation_hits_total` / `validator_attestation_misses_total`
- `peer_count` — if this drops, the node may be isolated from the network.
- `sync_status` — 0 = synced, 1 = behind.

Grafana dashboards let on-call engineers see at a glance whether validators are performing, and Prometheus alerting rules can fire PagerDuty/Slack notifications when thresholds are breached.

### Helm for Monitoring

Both Prometheus and Grafana ship as Helm charts maintained by the community. A `values.yaml` file customises retention period, scrape interval, admin credentials, and which sub-components to enable. For a minikube lab you disable heavyweight components (Alertmanager, Pushgateway) to save RAM.

---

## Tasks

Work directory: `/tmp/devops-lab/1D-01/`

### Task 1 — Create the `monitoring` namespace

```bash
kubectl create namespace monitoring
```

Verify:
```bash
kubectl get namespace monitoring
```

### Task 2 — Deploy Prometheus via Helm

Add the Prometheus community Helm repo and write a values file:

```bash
mkdir -p /tmp/devops-lab/1D-01
```

Write `/tmp/devops-lab/1D-01/prometheus-values.yaml`:

```yaml
server:
  retention: 2h
  global:
    scrape_interval: 15s

alertmanager:
  enabled: false

prometheus-pushgateway:
  enabled: false

kube-state-metrics:
  enabled: true

nodeExporter:
  enabled: true
```

Then install:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/prometheus \
  -n monitoring \
  -f /tmp/devops-lab/1D-01/prometheus-values.yaml
```

Wait for pods:
```bash
kubectl rollout status deployment/prometheus-server -n monitoring --timeout=120s
```

### Task 3 — Deploy Grafana via Helm

Write `/tmp/devops-lab/1D-01/grafana-values.yaml`:

```yaml
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
        url: http://prometheus-server.monitoring.svc.cluster.local
        access: proxy
        isDefault: true
```

Then install:

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install grafana grafana/grafana \
  -n monitoring \
  -f /tmp/devops-lab/1D-01/grafana-values.yaml
```

Wait for pods:
```bash
kubectl rollout status deployment/grafana -n monitoring --timeout=120s
```

### Task 4 — Deploy the Node Health Checker

The health checker is a minimal HTTP service that exposes a `/metrics` endpoint in Prometheus text format. Write `/tmp/devops-lab/1D-01/health-checker.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: health-checker-config
  namespace: monitoring
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
  name: health-checker
  namespace: monitoring
  labels:
    app: health-checker
spec:
  replicas: 1
  selector:
    matchLabels:
      app: health-checker
  template:
    metadata:
      labels:
        app: health-checker
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      containers:
        - name: health-checker
          image: nginx:alpine
          ports:
            - containerPort: 8080
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
            name: health-checker-config
---
apiVersion: v1
kind: Service
metadata:
  name: health-checker
  namespace: monitoring
  labels:
    app: health-checker
spec:
  selector:
    app: health-checker
  ports:
    - name: metrics
      port: 8080
      targetPort: 8080
```

Apply it:

```bash
kubectl apply -f /tmp/devops-lab/1D-01/health-checker.yaml
kubectl rollout status deployment/health-checker -n monitoring --timeout=60s
```

### Task 5 — Port-Forward Grafana and Verify Access

```bash
kubectl port-forward -n monitoring svc/grafana 3000:80 &
```

Wait a moment, then verify:
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/health
```

Write the URL to a file:
```bash
echo "http://localhost:3000" > /tmp/devops-lab/1D-01/grafana-url.txt
```

Grafana login: **admin** / **devops-lab**

### Task 6 — Verify Prometheus Data Source and Dashboard

Grafana was pre-configured with a Prometheus datasource via the `datasources.yaml` in your values file. Confirm it works:

```bash
# Test the datasource via Grafana's API
curl -s -u admin:devops-lab \
  http://localhost:3000/api/datasources \
  | python3 -m json.tool | grep '"name"'
```

You should see `"name": "Prometheus"` in the output.

To explore metrics, open `http://localhost:3000/explore` and run a PromQL query:
```
node_health_status
```

---

## What Just Happened

You deployed a full observability stack using Helm, the Kubernetes package manager. Prometheus was installed with a 2-hour retention window and a 15-second scrape interval — fine for a development lab. Its `kube-state-metrics` subchart automatically starts exporting Kubernetes object state (pod phases, deployment replica counts) as metrics. The `node-exporter` DaemonSet collects OS-level metrics from every node.

The health-checker pod uses nginx to serve a hand-crafted Prometheus metrics file. It carries the annotations `prometheus.io/scrape: "true"` — these are read by Prometheus's Kubernetes service discovery configuration, which automatically adds annotated pods to its scrape targets. No manual target configuration was needed.

Grafana was pre-wired to Prometheus via the `datasources.yaml` values key. When the Grafana pod started, it mounted that configuration and registered Prometheus as the default datasource, so the Explore view immediately had data.

Port-forwarding created a tunnel from your local port 3000 to the Grafana ClusterIP service inside the cluster — the standard way to access internal services during development without exposing them via a LoadBalancer or Ingress.

---

## Interview Question

**"Explain the pull-based monitoring model that Prometheus uses. How is it different from push-based?"**

Prometheus scrapes (pulls) metrics from targets on a scheduled interval. Each target runs an HTTP endpoint — typically `/metrics` — that returns current metric values in a plain-text format. Prometheus polls each endpoint, stores the timestamped values in its time-series database, and moves on.

In a **push-based** model, each application sends its metrics to a central aggregator whenever it has data. Tools like StatsD and the Prometheus Pushgateway work this way. Push is natural for batch jobs that terminate before Prometheus would scrape them, but it couples the application to the monitoring endpoint.

Pull has several operational advantages: Prometheus can immediately detect a failed scrape (the target may be down), you can manually test any target with `curl`, and targets do not need to be configured with the monitoring server's address. The trade-off is that short-lived jobs disappear before they can be scraped — solved with the Pushgateway as an intermediary for batch workloads.
