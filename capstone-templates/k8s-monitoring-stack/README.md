# Blockchain Monitoring Stack — Helm Chart

A production-grade Kubernetes monitoring stack for blockchain validator nodes, packaged as a Helm chart.

## Components

- **Prometheus** — metrics collection and storage (pull-based scraping)
- **Grafana** — dashboards and visualization
- **Node Health Checker** — custom service exposing validator metrics at `/metrics`
- **Ingress** — external access to Grafana dashboard

## Quick Start

```bash
# Prerequisites
minikube start --cpus=4 --memory=8192 --addons=ingress,metrics-server

# Install
helm install blockchain-monitor ./chart/ -n monitoring --create-namespace

# Access Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80
# Open http://localhost:3000 (admin/devops-lab)
```

## Configuration

Key values in `values.yaml`:

```yaml
prometheus:
  scrapeInterval: 15s
  retention: 24h

grafana:
  adminPassword: devops-lab
  service:
    type: ClusterIP

healthChecker:
  replicas: 1
  image: nginx:alpine

ingress:
  enabled: true
  host: monitoring.local
```

## Chart Structure

```
chart/
├── Chart.yaml          # Chart metadata and dependencies
├── values.yaml         # Default configuration
├── templates/
│   ├── health-checker-deployment.yaml
│   ├── health-checker-service.yaml
│   ├── ingress.yaml
│   └── NOTES.txt
└── charts/             # Subchart dependencies (Prometheus, Grafana)
```

## Skills Demonstrated

- Kubernetes cluster management (minikube)
- Helm chart development (templates, values, dependencies, subcharts)
- Prometheus monitoring architecture (scrape configs, targets)
- Grafana dashboard creation and data source configuration
- Ingress routing and TLS
- Infrastructure as Code for monitoring stacks
- Blockchain validator monitoring concepts
