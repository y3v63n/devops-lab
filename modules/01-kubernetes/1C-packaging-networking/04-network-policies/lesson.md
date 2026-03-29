# Exercise 1C-04: Network Policies

## Theory

### What are NetworkPolicies?

By default, Kubernetes has an **open network model**: every pod can communicate with every other pod, regardless of namespace. This is convenient for development but dangerous in production.

**NetworkPolicy** is a Kubernetes object that defines rules controlling which pods can communicate with which other pods (and external endpoints) at the IP/port level.

Think of NetworkPolicies as **firewall rules for pod-to-pod traffic**.

### Important: Requires a CNI with NetworkPolicy support

NetworkPolicy rules are enforced by the Container Network Interface (CNI) plugin, not by Kubernetes itself. Common CNI plugins that support NetworkPolicy:

- **Calico** — most common in production
- **Cilium** — eBPF-based, very performant
- **Weave** — simpler setup
- **Antrea** — VMware-backed

The default CNI in minikube does NOT enforce NetworkPolicies. You need to start minikube with Calico:
```bash
minikube start --network-plugin=cni --cni=calico
```

Without a compatible CNI, you can still create NetworkPolicy objects (Kubernetes accepts them), but they won't be enforced.

### NetworkPolicy Structure

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-to-db
  namespace: netpol-lab
spec:
  podSelector:              # Which pods this policy applies TO
    matchLabels:
      role: db
  policyTypes:
  - Ingress                 # Control incoming traffic to selected pods
  ingress:
  - from:
    - podSelector:          # Allow traffic FROM pods with this label
        matchLabels:
          role: web
    ports:
    - protocol: TCP
      port: 5432
```

### How Policies Stack

- **Default**: No policies = allow all traffic
- **First policy applied**: Any pod selected by a NetworkPolicy now has **default deny** for the policy type (Ingress/Egress)
- **Additional policies**: Each policy adds an **allow** rule — policies are additive (OR logic), never subtractive

This means: once you apply any Ingress NetworkPolicy to a pod, all ingress traffic is denied EXCEPT what the policies explicitly allow.

### Selectors

```yaml
# Allow from pods with matching labels in same namespace
- podSelector:
    matchLabels:
      role: web

# Allow from pods in specific namespace
- namespaceSelector:
    matchLabels:
      kubernetes.io/metadata.name: prod

# Allow from specific CIDR (external IP ranges)
- ipBlock:
    cidr: 10.0.0.0/8
    except:
    - 10.1.0.0/16
```

---

## Tasks

### Setup
```bash
mkdir -p /tmp/devops-lab/1C-04

# If using Calico:
# minikube start --network-plugin=cni --cni=calico
```

### Task 1 — Create namespace and deploy pods

```bash
kubectl create namespace netpol-lab

# Web pod (will be allowed to access db)
kubectl run web-pod --image=nginx --labels="role=web" -n netpol-lab

# DB pod (simulates a database)
kubectl run db-pod --image=nginx --labels="role=db" -n netpol-lab

# Test pod (no role label — should be blocked)
kubectl run test-pod --image=busybox --labels="role=test" \
  -n netpol-lab -- sleep 3600

kubectl get pods -n netpol-lab
```

### Task 2 — Write and apply NetworkPolicy

Create `/tmp/devops-lab/1C-04/netpol.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-to-db
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
    ports:
    - protocol: TCP
      port: 80
```

```bash
kubectl apply -f /tmp/devops-lab/1C-04/netpol.yaml
kubectl get networkpolicy -n netpol-lab
```

### Task 3 — Test policy enforcement

```bash
DB_IP=$(kubectl get pod db-pod -n netpol-lab -o jsonpath='{.status.podIP}')

{
  echo "=== Testing from web-pod (should succeed) ==="
  kubectl exec web-pod -n netpol-lab -- wget -qO- --timeout=3 "http://$DB_IP" 2>&1 || echo "BLOCKED"

  echo ""
  echo "=== Testing from test-pod (should be blocked) ==="
  kubectl exec test-pod -n netpol-lab -- wget -qO- --timeout=3 "http://$DB_IP" 2>&1 || echo "BLOCKED"
} > /tmp/devops-lab/1C-04/policy-test.txt

cat /tmp/devops-lab/1C-04/policy-test.txt
```

### Task 4 — Write your analysis

```bash
cat > /tmp/devops-lab/1C-04/netpol-notes.txt <<'EOF'
## Why Network Policies Matter

1. Defense in depth: Even if an attacker gains access to one pod,
   NetworkPolicies limit lateral movement across the cluster.

2. Least privilege for networking: Pods only get the network access
   they need, nothing more. This is the network equivalent of RBAC.

3. Compliance requirements: PCI-DSS, HIPAA, and SOC2 require network
   segmentation. NetworkPolicies are often the Kubernetes mechanism
   for demonstrating this.

4. Blast radius reduction: A compromised frontend pod cannot directly
   reach database pods or internal admin services.

5. Zero-trust networking: NetworkPolicies enable "never trust, always
   verify" at the pod level — all traffic must be explicitly permitted.
EOF
```

---

## What Just Happened

1. You created an isolated namespace as a security boundary.
2. You deployed pods with labels — labels are how NetworkPolicies select which pods to protect.
3. You wrote a NetworkPolicy targeting `role=db` pods: this immediately made them unreachable by default. Only pods matching `role=web` were granted access.
4. Testing showed the policy in action — the test-pod (no `role=web` label) was blocked, while web-pod got through.

This pattern — labeling pods and writing NetworkPolicies — is a fundamental security primitive in production Kubernetes.

---

## Interview Questions

**Q: "What is the default network policy behavior in Kubernetes?"**

By default, Kubernetes has **no NetworkPolicies**, which means all pods can communicate with all other pods and external endpoints without restriction — a flat, open network.

Once you apply a NetworkPolicy that selects a pod, behavior changes: the pod now has **implicit deny** for the policy types covered (Ingress and/or Egress). You must explicitly allow every type of traffic you want permitted.

Key nuances:
- The default-deny only kicks in when a pod is selected by at least one NetworkPolicy
- Pods not selected by any NetworkPolicy remain fully open
- NetworkPolicies are namespace-scoped
- Without a CNI that supports NetworkPolicy (like Calico or Cilium), policies are created but not enforced — this is a common production gotcha
