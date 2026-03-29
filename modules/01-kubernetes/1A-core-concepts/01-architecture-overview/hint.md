# Hints — Exercise 1A-01: Architecture Overview

## Task 1 — cluster-info
`kubectl cluster-info` shows the addresses of the API server and CoreDNS. If it hangs, your kubeconfig may be pointing at an unreachable cluster — check `kubectl config current-context`.

```bash
# If you need to redirect and display simultaneously, use tee:
kubectl cluster-info | tee /tmp/devops-lab/1A-01/cluster-info.txt
```

## Task 2 — nodes
The `-o wide` flag adds columns for internal IP, OS image, kernel version, and container runtime. Look at the ROLES column — control-plane nodes show `control-plane`, worker nodes show `<none>`.

```bash
kubectl get nodes -o wide | tee /tmp/devops-lab/1A-01/nodes.txt
```

## Task 3 — system pods
The `-n kube-system` flag scopes the query to the `kube-system` namespace. Try to match each pod to a component:
- `etcd-*` → etcd
- `kube-apiserver-*` → API server
- `kube-scheduler-*` → scheduler
- `kube-controller-manager-*` → controller manager
- `coredns-*` → cluster DNS
- `kube-proxy-*` → per-node network proxy

```bash
kubectl get pods -n kube-system | tee /tmp/devops-lab/1A-01/system-pods.txt
```

## Task 4 — architecture explanation
You don't need to be perfect — the goal is to demonstrate you understand the flow. Mention: kubectl → API server → etcd → controller manager → scheduler → kubelet → container runtime. A numbered list is fine.

```bash
# Write directly with a heredoc:
cat > /tmp/devops-lab/1A-01/architecture.txt << 'EOF'
Your explanation here...
EOF

# Or open an editor:
nano /tmp/devops-lab/1A-01/architecture.txt
```

## General Tips
- `kubectl explain <resource>` gives built-in documentation for any resource type.
- `kubectl describe node <node-name>` shows detailed node info including allocated resources.
- All control plane pods in a kubeadm cluster are **static pods** — their manifests live in `/etc/kubernetes/manifests/` on the control plane node.
