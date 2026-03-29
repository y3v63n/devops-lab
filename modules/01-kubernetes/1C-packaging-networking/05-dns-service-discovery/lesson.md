# Exercise 1C-05: DNS and Service Discovery

## Theory

### How DNS Works Inside Kubernetes

Kubernetes runs **CoreDNS** as the cluster DNS server — a deployment in the `kube-system` namespace. Every pod is automatically configured to use CoreDNS as its DNS resolver (via `/etc/resolv.conf`).

When a pod queries a hostname, CoreDNS resolves it against the cluster's service registry.

### Service DNS Names

Every Service gets a DNS record automatically:

```
<service-name>.<namespace>.svc.cluster.local
```

Examples:
- `my-svc.default.svc.cluster.local` — full qualified name
- `my-svc.default` — from any namespace
- `my-svc` — shorthand, only works from the same namespace

This is how microservices find each other without hardcoding IPs. A frontend service calls `http://api-service` and DNS resolves it to the Service's ClusterIP, which then load-balances to pods.

### Headless Services

A regular Service has a ClusterIP — a stable virtual IP that load-balances across pod IPs.

A **headless service** has `clusterIP: None`. Instead of returning a single VIP, DNS returns the individual pod IPs directly:

```
Regular service:  my-svc.default → 10.96.0.50 (ClusterIP → load balanced)
Headless service: my-svc.default → 10.244.1.5, 10.244.2.3, 10.244.1.8 (pod IPs)
```

Headless services are used with **StatefulSets** where each pod needs a stable, unique DNS name:

```
pod-0.my-svc.default.svc.cluster.local → 10.244.1.5 (always pod-0)
pod-1.my-svc.default.svc.cluster.local → 10.244.2.3 (always pod-1)
```

This is critical for stateful applications like databases where you need to connect to a specific replica (e.g., always write to the primary, read from replicas).

### CoreDNS Configuration

CoreDNS is configured via a ConfigMap in `kube-system`. The Corefile defines:
- Which domains to serve (cluster.local)
- Upstream resolvers for external names
- Caching behavior
- Health checks

```
# Example Corefile
.:53 {
    errors
    health
    ready
    kubernetes cluster.local in-addr.arpa ip6.arpa {
       pods insecure
       fallthrough in-addr.arpa ip6.arpa
    }
    prometheus :9153
    forward . /etc/resolv.conf
    cache 30
    loop
    reload
    loadbalance
}
```

---

## Tasks

### Setup
```bash
mkdir -p /tmp/devops-lab/1C-05
```

### Task 1 — Create a service and resolve its DNS

```bash
# Create a deployment and service
kubectl create deployment web-app --image=nginx
kubectl expose deployment web-app --port=80 --name=my-svc

# Run a debug pod and do DNS lookup
kubectl run dns-test --image=busybox:1.35 --restart=Never -- \
  nslookup my-svc.default.svc.cluster.local

# Wait for pod to complete and capture output
kubectl wait --for=condition=ready pod/dns-test --timeout=30s
kubectl logs dns-test > /tmp/devops-lab/1C-05/dns-resolution.txt

cat /tmp/devops-lab/1C-05/dns-resolution.txt
kubectl delete pod dns-test
```

### Task 2 — Headless service with StatefulSet

```bash
# Create headless service
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: headless-svc
spec:
  clusterIP: None
  selector:
    app: stateful-app
  ports:
  - port: 80
EOF

# Create StatefulSet
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: stateful-app
spec:
  serviceName: headless-svc
  replicas: 2
  selector:
    matchLabels:
      app: stateful-app
  template:
    metadata:
      labels:
        app: stateful-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
EOF

kubectl wait --for=condition=ready pod/stateful-app-0 --timeout=60s

# Resolve individual pod DNS
kubectl run headless-test --image=busybox:1.35 --restart=Never -- sh -c \
  "nslookup stateful-app-0.headless-svc.default.svc.cluster.local; \
   nslookup stateful-app-1.headless-svc.default.svc.cluster.local"

kubectl wait --for=condition=ready pod/headless-test --timeout=30s
kubectl logs headless-test > /tmp/devops-lab/1C-05/headless-dns.txt

cat /tmp/devops-lab/1C-05/headless-dns.txt
kubectl delete pod headless-test
```

### Task 3 — Capture CoreDNS configuration

```bash
kubectl get configmap coredns -n kube-system -o yaml \
  > /tmp/devops-lab/1C-05/coredns-config.txt

cat /tmp/devops-lab/1C-05/coredns-config.txt
```

### Task 4 — Write your DNS notes

```bash
cat > /tmp/devops-lab/1C-05/dns-notes.txt <<'EOF'
## Headless Services Explained

A regular Kubernetes Service has a ClusterIP — a virtual IP that acts
as a stable endpoint and load-balances traffic across pod IPs via kube-proxy.

A headless service (clusterIP: None) has no virtual IP. Instead:
- DNS returns A records for each pod IP directly
- No load balancing happens at the Service level
- Clients receive all pod IPs and choose themselves

## Why Use Headless Services?

1. StatefulSets need stable pod identity: pod-0.svc, pod-1.svc, etc.
   Regular services can't provide per-pod DNS names.

2. Database clusters: When connecting to Postgres replication, you must
   distinguish between the primary (pod-0) and replicas. Headless DNS
   makes this possible.

3. Client-side load balancing: gRPC and some databases implement their
   own load balancing. They need all pod IPs, not a single VIP.

4. Service mesh discovery: Istio and Linkerd use headless DNS to
   enumerate pods for their sidecar proxy configurations.
EOF
```

---

## What Just Happened

1. You saw CoreDNS resolve `my-svc.default.svc.cluster.local` to a ClusterIP — the standard path for inter-service communication.
2. You created a headless service and observed that DNS returned individual pod IPs instead of a VIP.
3. You saw StatefulSet pods get stable, predictable DNS names: `pod-name.service-name.namespace.svc.cluster.local`.
4. You read the CoreDNS Corefile — the configuration that makes all cluster DNS work.

---

## Interview Questions

**Q: "How does DNS work inside Kubernetes?"**

Every pod's `/etc/resolv.conf` is automatically configured to point to the CoreDNS ClusterIP (typically `10.96.0.10`). When a pod resolves a hostname, it queries CoreDNS.

CoreDNS handles two categories:
1. **Cluster names** (`.cluster.local` suffix): CoreDNS looks up the hostname in its internal registry (backed by Kubernetes service and pod data) and returns the appropriate IP — ClusterIP for regular services, pod IPs for headless services.
2. **External names**: CoreDNS forwards to upstream resolvers (the node's `/etc/resolv.conf` or configured forwarders).

DNS search domains in pod's resolv.conf allow shorthand names:
- `my-svc` resolves because search domain `default.svc.cluster.local` is appended
- This is why services in the same namespace are reachable by short name
