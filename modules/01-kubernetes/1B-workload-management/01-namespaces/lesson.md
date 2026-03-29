# Exercise 1B-01: Kubernetes Namespaces

## Concept

Namespaces provide virtual clusters within a single physical Kubernetes cluster. They enable multi-team isolation, resource quotas, and scoped RBAC — without needing separate clusters.

### Key Defaults
- `default` — where resources land without a namespace specified
- `kube-system` — Kubernetes internal components
- `kube-public` — readable by all users
- `kube-node-lease` — node heartbeat leases

### Why Namespaces Matter
- Teams share a cluster without stepping on each other
- Apply resource quotas per namespace
- RBAC: give team-A access only to `team-a` namespace
- DNS isolation: `service.namespace.svc.cluster.local`

---

## Tasks

### Setup
```bash
mkdir -p /tmp/devops-lab/1B-01
```

### Task 1 — Create Namespaces
Create `dev` and `staging` namespaces, then list all namespaces to a file:
```bash
kubectl create namespace dev
kubectl create namespace staging
kubectl get namespaces > /tmp/devops-lab/1B-01/namespaces.txt
```

### Task 2 — Deploy Workloads in Each Namespace
Deploy nginx in `dev` (2 replicas) and `staging` (1 replica):
```bash
kubectl create deployment nginx --image=nginx:1.25 --replicas=2 -n dev
kubectl create deployment nginx --image=nginx:1.25 --replicas=1 -n staging

kubectl get pods -n dev > /tmp/devops-lab/1B-01/dev-pods.txt
kubectl get pods -n staging > /tmp/devops-lab/1B-01/staging-pods.txt
```

### Task 3 — Cross-Namespace Service Access
Create a service for the dev deployment, then access it from a pod in staging using the FQDN:
```bash
kubectl expose deployment nginx --port=80 -n dev

# Run a temporary pod in staging and curl the dev service via FQDN
kubectl run test-pod --image=busybox:1.35 -n staging --rm -it --restart=Never \
  -- wget -qO- http://nginx.dev.svc.cluster.local > /tmp/devops-lab/1B-01/cross-ns.txt 2>&1
```

The FQDN pattern is: `<service>.<namespace>.svc.cluster.local`

### Task 4 — Set Default Namespace
Change your active context to use `dev` as the default namespace:
```bash
kubectl config set-context --current --namespace=dev
kubectl config view --minify | grep namespace
```

Verify it worked:
```bash
kubectl get pods  # should show dev pods without -n flag
```

---

## What Just Happened

- You created isolated virtual clusters within the same physical cluster
- Pods in `staging` accessed services in `dev` using cross-namespace DNS
- The FQDN `nginx.dev.svc.cluster.local` resolves because CoreDNS serves all namespaces
- Setting the context namespace avoids typing `-n dev` repeatedly

---

## Interview Question

**"How do namespaces help with multi-team Kubernetes environments?"**

Strong answer: Namespaces provide logical isolation — each team gets their own namespace with RBAC policies restricting access to only their resources. Combined with ResourceQuotas, you prevent one team from consuming all cluster capacity. NetworkPolicies can further restrict cross-namespace communication. It's not hard isolation (a privileged pod can still escape), but it's the standard operational boundary in shared clusters.
