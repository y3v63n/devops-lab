# Exercise 1A-02: Pods

## Theory

A **Pod** is the smallest deployable unit in Kubernetes. It represents a single instance of a running process in your cluster. Pods encapsulate one or more containers, storage resources, a unique network IP, and options that govern how the container(s) should run.

### Key Pod Concepts

**Single vs. multi-container pods**: Most Pods run a single container. Multi-container Pods are used for tightly coupled helper processes — the sidecar pattern (log shipper alongside app), the ambassador pattern (proxy that handles network routing), and the adapter pattern (transform output for monitoring). All containers in a Pod share the same network namespace and can communicate via `localhost`. This is precisely why two containers in the same Pod cannot bind to the same port — they share one network stack, just like two processes on the same host cannot both listen on port 80.

**Pod lifecycle**: Pods are ephemeral. They have phases: `Pending` (scheduled but not yet running), `Running` (at least one container running), `Succeeded` (all containers exited with code 0), `Failed` (at least one container exited non-zero), `Unknown` (node unreachable). When a Pod dies, Kubernetes does not restart it automatically unless managed by a higher-level controller like a Deployment or ReplicaSet.

**Pod networking**: Every Pod gets its own IP address. Containers within the same Pod communicate via `localhost`. Containers in different Pods communicate via Pod IPs or, preferably, via Services. The Pod IP is ephemeral — it changes when a Pod is replaced.

**Pod storage**: Containers within a Pod can share data via `volumes` defined in the Pod spec. Each container mounts the volume at its own path. Volume lifetime is tied to the Pod — when the Pod is deleted, non-persistent volumes are gone.

```
┌─────────────────────────────────────────┐
│                   POD                   │
│  Shared network namespace (IP + ports)  │
│  Shared volumes (optional)              │
│                                         │
│  ┌──────────────┐  ┌──────────────────┐ │
│  │  Container A │  │   Container B    │ │
│  │  (app)       │  │   (log-shipper)  │ │
│  │  port: 8080  │  │  (no port clash) │ │
│  └──────────────┘  └──────────────────┘ │
│         │                  │            │
│         └────── Volume ────┘            │
└─────────────────────────────────────────┘
```

---

## Tasks

### Setup
```bash
mkdir -p /tmp/devops-lab/1A-02
```

### Task 1 — Generate Pod YAML
Use `--dry-run=client` to generate the YAML without creating the Pod, inspect it, then apply it.
```bash
kubectl run lab-nginx --image=nginx:alpine \
  --dry-run=client -o yaml \
  | tee /tmp/devops-lab/1A-02/pod.yaml

# Review the YAML, then create the Pod:
kubectl apply -f /tmp/devops-lab/1A-02/pod.yaml
```

### Task 2 — Exec Into the Pod
Wait for the Pod to be Running, then exec in and create a custom HTML page.
```bash
# Wait until Running:
kubectl wait pod/lab-nginx --for=condition=Ready --timeout=60s

# Exec in and create a file:
kubectl exec -it lab-nginx -- sh -c \
  'echo "Hello K8s" > /usr/share/nginx/html/devops.html'

# Verify inside the pod:
kubectl exec lab-nginx -- cat /usr/share/nginx/html/devops.html
```

### Task 3 — Port-Forward and Test
```bash
# Start port-forward in the background:
kubectl port-forward pod/lab-nginx 8088:80 &
PF_PID=$!

# Give it a moment to establish:
sleep 2

# Curl the custom page:
curl -s http://localhost:8088/devops.html | tee /tmp/devops-lab/1A-02/response.txt

# Stop the port-forward:
kill $PF_PID 2>/dev/null || true
```

### Task 4 — Logs, then Cleanup
```bash
# Capture logs:
kubectl logs lab-nginx | tee /tmp/devops-lab/1A-02/pod-logs.txt

# Delete the pod:
kubectl delete pod lab-nginx
```

---

## Interview Question

**"Why can't two containers in the same Pod listen on the same port?"**

Think about:
- All containers in a Pod share a single network namespace (same IP address, same port space)
- This is identical to two processes on the same Linux host — if process A binds port 80, process B cannot also bind port 80
- Port conflicts would cause the second container to crash immediately on startup
- This is intentional: it forces clear separation of concerns (run one service per container)
- Contrast with different Pods: each Pod has its own IP, so two Pods on the same node *can* both use port 80

---

## What Just Happened

`--dry-run=client` made kubectl generate the API object locally without ever sending it to the API server. This is extremely useful for generating base YAML to modify, understanding what kubectl commands actually produce, and validating manifests offline.

`kubectl exec` works by the API server proxying your terminal session through the kubelet on the node, which tells the container runtime to attach to the running container's process namespace. Your keystrokes travel: terminal → kubectl → API server → kubelet → container runtime → container PID 1 shell.

`kubectl port-forward` similarly proxies a TCP connection: your local port 8088 → API server → kubelet → Pod's port 80. It is not a production traffic path — it is a debugging tool.
