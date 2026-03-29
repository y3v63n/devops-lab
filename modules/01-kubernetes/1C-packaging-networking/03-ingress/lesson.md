# Exercise 1C-03: Kubernetes Ingress

## Theory

### What is Ingress?

An **Ingress** is a Kubernetes API object that manages external HTTP/HTTPS access to services in a cluster. It provides Layer 7 (application layer) routing — making routing decisions based on HTTP hostname and URL path, not just TCP port.

```
Internet → LoadBalancer → Ingress Controller → Ingress Rules → Service → Pods
```

Without Ingress, you'd need a separate LoadBalancer (and cloud IP) for every service. With Ingress, one LoadBalancer handles many services.

### Ingress Resource vs Ingress Controller

This is a critical distinction that trips up many engineers:

| | Ingress Resource | Ingress Controller |
|---|---|---|
| What | A Kubernetes API object (YAML) | A running pod/deployment |
| Role | Declares routing rules | Implements those rules |
| Created by | You (kubectl apply) | Cluster admin (separate install) |
| Examples | Your ingress.yaml | nginx-ingress, Traefik, HAProxy, AWS ALB |

The Ingress Resource is just a configuration declaration. Without an Ingress Controller watching for these resources and programming a reverse proxy, Ingress rules do nothing.

### Ingress Rule Structure

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com        # optional: route by hostname
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
```

### Path Types

- `Prefix` — matches any path starting with the prefix (`/v1` matches `/v1`, `/v1/users`, `/v1/anything`)
- `Exact` — matches only the exact path
- `ImplementationSpecific` — behavior defined by the controller

---

## Tasks

### Setup
```bash
mkdir -p /tmp/devops-lab/1C-03

# Enable ingress addon on minikube
minikube addons enable ingress
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

### Task 1 — Create two app deployments

```bash
# app-v1: returns "Hello from V1"
kubectl create deployment app-v1 --image=hashicorp/http-echo -- \
  /http-echo -text="Hello from V1" -listen=:5678

# app-v2: returns "Hello from V2"
kubectl create deployment app-v2 --image=hashicorp/http-echo -- \
  /http-echo -text="Hello from V2" -listen=:5678
```

### Task 2 — Expose as services

```bash
kubectl expose deployment app-v1 --port=80 --target-port=5678
kubectl expose deployment app-v2 --port=80 --target-port=5678
```

### Task 3 — Write Ingress YAML and apply it

Create `/tmp/devops-lab/1C-03/ingress.yaml`:

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
            name: app-v1
            port:
              number: 80
      - path: /v2
        pathType: Prefix
        backend:
          service:
            name: app-v2
            port:
              number: 80
```

```bash
kubectl apply -f /tmp/devops-lab/1C-03/ingress.yaml
```

### Task 4 — Test routing

```bash
MINIKUBE_IP=$(minikube ip)

{
  echo "=== Testing /v1 route ==="
  curl -s "http://$MINIKUBE_IP/v1"
  echo ""
  echo "=== Testing /v2 route ==="
  curl -s "http://$MINIKUBE_IP/v2"
  echo ""
} > /tmp/devops-lab/1C-03/routing-test.txt

cat /tmp/devops-lab/1C-03/routing-test.txt
```

---

## What Just Happened

1. You deployed two independent applications (app-v1, app-v2) as separate Deployments with separate Services.
2. You created a single Ingress resource that routes traffic based on URL path — `/v1` to one app, `/v2` to another.
3. The minikube ingress addon (NGINX Ingress Controller) watched for the Ingress resource and automatically configured its internal NGINX to proxy traffic accordingly.
4. A single IP (minikube IP) now routes to multiple different backends purely based on the request path.

This is the foundation of traffic splitting, blue-green deployments, and API gateway patterns in Kubernetes.

---

## Interview Questions

**Q: "What is the difference between an Ingress resource and an Ingress Controller?"**

An **Ingress resource** is a declarative YAML object in the Kubernetes API that defines routing rules: "traffic to /api goes to service api-svc, traffic to / goes to frontend-svc." It's just data — like a routing table stored in etcd.

An **Ingress Controller** is an actual running workload (pod) that watches the Kubernetes API for Ingress resources and translates those rules into real proxy configuration. NGINX Ingress Controller, for example, dynamically rewrites its nginx.conf whenever Ingress resources change.

Without an Ingress Controller, Ingress resources are ignored. The split design lets you swap controllers (e.g., from NGINX to Traefik) without changing your Ingress YAML.
