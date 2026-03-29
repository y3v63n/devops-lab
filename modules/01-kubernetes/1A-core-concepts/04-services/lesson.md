# Exercise 1A-04: Services

## Theory

Pods are ephemeral — they come and go, and each new Pod gets a new IP address. A **Service** provides a stable network endpoint (a fixed IP and DNS name) that routes traffic to a dynamic set of Pods, selected by labels.

### How Services Route Traffic

A Service uses a **label selector** to find its target Pods. kube-proxy on each node watches for Service and Endpoints objects and programs iptables (or ipvs) rules to intercept traffic destined for the Service's ClusterIP and forward it to one of the healthy Pod IPs. The Endpoints controller continuously updates the list of Pod IPs as Pods are added, removed, or fail readiness checks.

```
Client Pod
    │
    │ curl http://backend-svc:80
    ▼
iptables/ipvs rule (kube-proxy)
    │  Service ClusterIP: 10.96.45.12:80
    │
    ├── Pod 10.244.1.5:80
    ├── Pod 10.244.2.8:80
    └── Pod 10.244.1.9:80
```

### Service Types

**ClusterIP** (default): Exposes the Service on an internal IP within the cluster. Only reachable from within the cluster. Use for internal microservice communication.

**NodePort**: Exposes the Service on each Node's IP at a static port (range 30000–32767). Traffic to `<NodeIP>:<NodePort>` is forwarded to the Service. Builds on top of ClusterIP — a NodePort Service also creates a ClusterIP. Use for direct external access in dev/test environments.

**LoadBalancer**: Exposes the Service externally using a cloud provider's load balancer. Builds on top of NodePort — a LoadBalancer Service also creates a NodePort and ClusterIP. Use for production external traffic on cloud providers (AWS ELB, GCP LB, Azure LB).

**ExternalName**: Maps the Service to an external DNS name. No proxying — returns a CNAME record. Use to integrate external services into cluster DNS.

```
LoadBalancer
└── NodePort (30080)
    └── ClusterIP (10.96.45.12:80)
        └── Pod IPs (10.244.x.x:80)
```

### DNS Resolution

CoreDNS assigns every Service a DNS name: `<service-name>.<namespace>.svc.cluster.local`. Pods in the same namespace can use just `<service-name>`. This is the correct way for microservices to discover each other — not by IP.

---

## Tasks

### Setup
```bash
mkdir -p /tmp/devops-lab/1A-04
```

### Task 1 — Create Deployment and ClusterIP Service
```bash
kubectl create deployment backend --image=nginx:alpine --replicas=2

# Expose with ClusterIP (default):
kubectl expose deployment backend --port=80 --target-port=80 --name=backend-svc

# Verify:
kubectl get svc backend-svc
kubectl get endpoints backend-svc
```

### Task 2 — Create NodePort Service and Record URL
```bash
# Create a NodePort service:
kubectl expose deployment backend --port=80 --target-port=80 \
  --name=backend-nodeport --type=NodePort

# Get the assigned NodePort:
NODE_PORT=$(kubectl get svc backend-nodeport -o jsonpath='{.spec.ports[0].nodePort}')
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')

echo "NodePort URL: http://${NODE_IP}:${NODE_PORT}" \
  | tee /tmp/devops-lab/1A-04/nodeport-url.txt
```

### Task 3 — Test Internal Access by Service Name
Launch a debug pod, curl the ClusterIP service by DNS name, and save the result.
```bash
kubectl run debug-pod --image=curlimages/curl:latest --restart=Never \
  --command -- sleep 300

kubectl wait pod/debug-pod --for=condition=Ready --timeout=30s

kubectl exec debug-pod -- curl -s http://backend-svc:80 \
  | tee /tmp/devops-lab/1A-04/internal-access.txt

kubectl delete pod debug-pod
```

### Task 4 — Explain Service Types
```bash
cat > /tmp/devops-lab/1A-04/service-types.txt << 'EOF'
ClusterIP:
  - Default type. Exposes service on an internal cluster IP only.
  - Not reachable from outside the cluster.
  - Use case: internal microservice-to-microservice communication.
  - DNS: <svc-name>.<namespace>.svc.cluster.local

NodePort:
  - Exposes service on each node's IP at a static port (30000-32767).
  - Reachable from outside at <NodeIP>:<NodePort>.
  - Also creates a ClusterIP automatically.
  - Use case: dev/test external access without a cloud load balancer.

LoadBalancer:
  - Provisions a cloud provider load balancer (AWS ELB, GCP LB, etc.).
  - Gets an external IP that routes to the NodePort, then to ClusterIP.
  - Most expensive — creates cloud resources.
  - Use case: production internet-facing services on cloud clusters.

ExternalName:
  - Maps service name to an external DNS CNAME.
  - No proxying — pure DNS alias.
  - Use case: abstracting external dependencies (e.g., managed databases).
EOF
```

---

## Interview Question

**"How does a Kubernetes Service actually route traffic to Pods?"**

Think about:
- Label selectors and the Endpoints object (list of Pod IPs)
- kube-proxy's role: watches API server, programs iptables/ipvs rules on each node
- What happens when a Pod fails its readiness probe (removed from Endpoints)
- The difference between kube-proxy iptables mode and ipvs mode (performance at scale)
- Why ClusterIP is "virtual" — no process actually listens on that IP; iptables intercepts at kernel level

---

## What Just Happened

When you ran `kubectl expose`, Kubernetes created both a Service object (with the ClusterIP) and an Endpoints object (with the IP addresses of matching Pods). kube-proxy on each node detected the new Service and Endpoints, then added iptables DNAT rules so that any traffic to the ClusterIP gets rewritten to one of the Pod IPs before it leaves the network stack.

When your debug pod ran `curl http://backend-svc:80`, CoreDNS resolved `backend-svc` to the ClusterIP. kube-proxy's iptables rules intercepted the packet and randomly selected one of the two backend Pod IPs to forward it to — that's the built-in round-robin load balancing.
