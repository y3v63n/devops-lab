# Exercise 1C-06: Multi-Container Pods

## Theory

### Why Multiple Containers in One Pod?

Kubernetes pods are the smallest deployable unit and can contain multiple containers. While single-container pods are the norm, multi-container pods solve specific architectural problems through established patterns.

Containers in the same pod:
- Share the same network namespace (same IP, can talk via localhost)
- Can share volumes (filesystem data)
- Are scheduled together on the same node
- Start and stop together

### Three Patterns

#### 1. Init Container Pattern

Init containers run to completion BEFORE the main application container starts. They're used for:
- Pre-flight checks (wait for dependencies)
- Configuration generation (write config files to shared volume)
- Database schema migrations
- Secret fetching/transformation

```yaml
spec:
  initContainers:
  - name: init-config
    image: busybox
    command: ['sh', '-c', 'echo "config data" > /shared/config.txt']
    volumeMounts:
    - name: shared-data
      mountPath: /shared
  containers:
  - name: main-app
    image: nginx
    volumeMounts:
    - name: shared-data
      mountPath: /config
  volumes:
  - name: shared-data
    emptyDir: {}
```

Key behaviors:
- If an init container fails, the pod restarts (respects restartPolicy)
- Init containers run sequentially — each must succeed before the next starts
- Init containers can have different images/tools than the main app
- Main container doesn't start until ALL init containers complete

#### 2. Sidecar Pattern

Sidecar containers run alongside the main container for the pod's lifetime. They extend or enhance the main container's functionality without changing it.

Use cases:
- **Log shipping**: Main app writes to a file; sidecar streams logs to Elasticsearch/Splunk
- **Proxy**: Istio/Linkerd inject a sidecar proxy to handle all network traffic
- **Sync**: Pull configuration updates from a remote source and write to a shared volume
- **Monitoring**: Collect metrics from a shared socket

```yaml
spec:
  containers:
  - name: app
    image: myapp
    volumeMounts:
    - name: log-volume
      mountPath: /var/log/app
  - name: log-shipper
    image: fluentd
    volumeMounts:
    - name: log-volume
      mountPath: /var/log/app
  volumes:
  - name: log-volume
    emptyDir: {}
```

#### 3. Ambassador Pattern

An ambassador container acts as a proxy between the main container and the outside world. The main app talks to `localhost:port` as if connecting locally; the ambassador handles the complexity of connecting to the real service.

Use cases:
- Abstracting service discovery (app always talks to localhost, ambassador handles the real connection)
- Connection pooling to a database
- Adding TLS to a service that doesn't support it natively

```yaml
spec:
  containers:
  - name: app
    image: myapp
    # app connects to localhost:6379 thinking it's Redis
  - name: ambassador
    image: envoyproxy/envoy
    # ambassador proxies localhost:6379 to the real Redis cluster
```

---

## Tasks

### Setup
```bash
mkdir -p /tmp/devops-lab/1C-06
```

### Task 1 — Init container writing config to shared volume

Create `/tmp/devops-lab/1C-06/init-container.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-demo
spec:
  initContainers:
  - name: init-writer
    image: busybox
    command:
    - sh
    - -c
    - |
      echo "APP_MODE=production" > /shared/app.conf
      echo "LOG_LEVEL=info" >> /shared/app.conf
      echo "Init container: config written"
    volumeMounts:
    - name: shared-config
      mountPath: /shared
  containers:
  - name: main-app
    image: busybox
    command:
    - sh
    - -c
    - |
      echo "Main container starting..."
      echo "Config contents:"
      cat /config/app.conf
      sleep 3600
    volumeMounts:
    - name: shared-config
      mountPath: /config
  volumes:
  - name: shared-config
    emptyDir: {}
```

```bash
kubectl apply -f /tmp/devops-lab/1C-06/init-container.yaml
kubectl wait --for=condition=ready pod/init-demo --timeout=60s
kubectl logs init-demo -c main-app
```

### Task 2 — Sidecar pod for log forwarding

Create `/tmp/devops-lab/1C-06/sidecar.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sidecar-demo
spec:
  containers:
  - name: log-writer
    image: busybox
    command:
    - sh
    - -c
    - |
      while true; do
        echo "$(date) - Application log entry" >> /var/log/app.log
        sleep 2
      done
    volumeMounts:
    - name: log-volume
      mountPath: /var/log
  - name: log-reader
    image: busybox
    command:
    - sh
    - -c
    - |
      tail -f /var/log/app.log
    volumeMounts:
    - name: log-volume
      mountPath: /var/log
  volumes:
  - name: log-volume
    emptyDir: {}
```

```bash
kubectl apply -f /tmp/devops-lab/1C-06/sidecar.yaml
kubectl wait --for=condition=ready pod/sidecar-demo --timeout=60s
# Watch the sidecar reading logs written by the main container
kubectl logs sidecar-demo -c log-reader --tail=5
```

### Task 3 — Capture init container event sequence

```bash
kubectl describe pod init-demo > /tmp/devops-lab/1C-06/init-events.txt
cat /tmp/devops-lab/1C-06/init-events.txt
```

Look for the Events section at the bottom — you'll see the init container start and complete, then the main container start.

### Task 4 — Describe the three patterns

```bash
cat > /tmp/devops-lab/1C-06/patterns.txt <<'EOF'
## Multi-Container Pod Patterns

### 1. Init Container Pattern
Purpose: Run setup tasks before the main application starts.
The init container(s) run to completion sequentially, each must succeed
before the next begins. Only after all init containers complete does the
main container start.

Example use cases:
- Write configuration to a shared volume before the app reads it
- Wait for a database to be ready (using a health check loop)
- Run database migrations before the application server starts
- Fetch secrets from Vault and write them to a shared volume

### 2. Sidecar Pattern
Purpose: Extend or support the main container throughout its lifetime.
Runs in parallel with the main container, sharing network and/or volumes.

Example use cases:
- Log shipping: app writes logs to a file, sidecar streams to aggregator
- Service mesh proxy: Istio injects Envoy sidecar to intercept all traffic
- Configuration sync: pull config updates and write to shared volume
- Metrics collection: scrape app metrics via shared socket

### 3. Ambassador Pattern
Purpose: Proxy connections from the main container to external services.
The main app connects to localhost, unaware of external complexity.

Example use cases:
- Database proxy: app connects to localhost, ambassador connects to RDS
- Connection pooling: ambassador pools connections to reduce overhead
- TLS termination: app doesn't support TLS, ambassador handles it
- Service discovery abstraction: ambassador resolves dynamic endpoints
EOF
```

---

## What Just Happened

1. You created a pod where an init container wrote config to a shared `emptyDir` volume. The main container couldn't start until init completed — you saw this sequencing in `kubectl describe`.
2. You built a sidecar pattern where two containers share a volume in real time. The log-reader sidecar "sees" files as soon as log-writer creates them.
3. `kubectl describe` showed the event timeline: init container pull → init container start → init container complete → main container start. This is the guarantee init containers provide.
4. You articulated the three patterns — understanding WHEN to use each is what separates junior from senior Kubernetes engineers.

---

## Interview Questions

**Q: "What is the difference between a sidecar container and an init container?"**

An **init container** runs to completion BEFORE the main container starts. It's for one-time setup tasks: writing config, waiting for dependencies, running migrations. Init containers do not run during the pod's normal lifecycle — they start, succeed, and are done.

A **sidecar container** runs ALONGSIDE the main container for the pod's entire lifetime. It's for ongoing support functionality: log shipping, proxying, metrics collection. Sidecars are regular containers listed under `spec.containers` alongside the main app.

The key difference: **lifecycle**. Init containers run before and complete; sidecars run during and keep running. This affects restartPolicy, resource consumption, and pod termination behavior.

In Kubernetes 1.29+, "native sidecars" were introduced as `initContainers` with `restartPolicy: Always` — they start before main containers but continue running, combining properties of both patterns.
