# Hints — Exercise 1D-01: Capstone Monitoring Stack

## Task 1 — Creating the namespace

**Hint 1:** Namespaces are created with a single `kubectl` command:
```bash
kubectl create namespace monitoring
```

**Hint 2:** Verify it exists and is Active:
```bash
kubectl get namespace monitoring
```

---

## Task 2 — Prometheus values file

**Hint 1:** The values file controls which Prometheus sub-components are enabled. For a minikube lab you want to disable Alertmanager and Pushgateway to save resources.

**Hint 2:** The `server` block controls the Prometheus server itself. `global.scrape_interval` sets how often Prometheus polls each target.

**Hint 3 (full values file):**
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

Save to `/tmp/devops-lab/1D-01/prometheus-values.yaml`, then:
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/prometheus \
  -n monitoring \
  -f /tmp/devops-lab/1D-01/prometheus-values.yaml
```

---

## Task 3 — Grafana values file

**Hint 1:** You need to set `adminPassword` and pre-configure Prometheus as a datasource so you do not have to do it manually in the UI.

**Hint 2:** The `datasources` key in the Grafana chart expects a `datasources.yaml` sub-key with the Grafana datasource provisioning format. The Prometheus server's cluster-internal DNS name is `prometheus-server.monitoring.svc.cluster.local`.

**Hint 3 (full values file):**
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

Save to `/tmp/devops-lab/1D-01/grafana-values.yaml`, then:
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install grafana grafana/grafana \
  -n monitoring \
  -f /tmp/devops-lab/1D-01/grafana-values.yaml
```

---

## Task 4 — Health checker deployment

**Hint 1:** The key requirement is an HTTP endpoint at `/metrics` returning Prometheus text format. You can achieve this with nginx serving a static text file.

**Hint 2:** The pod needs `prometheus.io/scrape: "true"` annotation so Prometheus auto-discovers it.

**Hint 3 (full YAML):**
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
spec:
  selector:
    app: health-checker
  ports:
    - port: 8080
      targetPort: 8080
```

Save to `/tmp/devops-lab/1D-01/health-checker.yaml`, then:
```bash
kubectl apply -f /tmp/devops-lab/1D-01/health-checker.yaml
```

---

## Task 5 — Port-forwarding Grafana

**Hint 1:** Port-forwarding maps a local port to a service inside the cluster. The `&` runs it in the background so your terminal stays usable.

**Hint 2:**
```bash
kubectl port-forward -n monitoring svc/grafana 3000:80 &
sleep 2
curl http://localhost:3000/api/health
echo "http://localhost:3000" > /tmp/devops-lab/1D-01/grafana-url.txt
```

**Hint 3:** If port 3000 is already in use, kill the existing process first:
```bash
pkill -f "port-forward.*3000" 2>/dev/null || true
```

---

## Task 6 — Verify datasource

**Hint 1:** Grafana exposes a REST API. You can verify the datasource is registered without opening a browser:
```bash
curl -s -u admin:devops-lab http://localhost:3000/api/datasources | python3 -m json.tool
```

**Hint 2:** If you see an empty array `[]`, the datasource provisioning didn't take effect. Check Grafana pod logs:
```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana | grep -i datasource
```

---

## General Troubleshooting

- **Pods stuck in Pending:** Check resource pressure with `kubectl describe pod <name> -n monitoring`. Minikube may need more memory: `minikube stop && minikube start --memory=4096`.
- **ImagePullBackOff:** Run `kubectl describe pod <name> -n monitoring` to see the exact pull error. Check internet connectivity from the node.
- **Helm install fails with "cannot re-use a name":** A previous release exists. Either `helm uninstall <name> -n monitoring` or use `helm upgrade --install` instead of `helm install`.
- **Port-forward drops:** Port-forwarding is not persistent. If it drops, re-run the `kubectl port-forward` command.
