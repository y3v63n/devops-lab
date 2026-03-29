# Kubernetes & Helm Cheatsheet

Quick reference for kubectl and helm commands used throughout Module 1.

---

## Cluster & Context

```bash
kubectl cluster-info                                    # show cluster endpoint info
kubectl config current-context                          # show active context
kubectl config get-contexts                             # list all contexts
kubectl config use-context NAME                         # switch to a different context
kubectl config set-context --current --namespace=NAME   # set default namespace for current context
kubectl config view                                     # show full kubeconfig
```

### minikube

```bash
minikube start                          # start local cluster (default driver)
minikube start --driver=docker          # start with Docker driver
minikube start --cpus=4 --memory=8192   # start with custom resources
minikube stop                           # stop the cluster (preserves state)
minikube delete                         # destroy the cluster
minikube status                         # show component status
minikube dashboard                      # open web UI in browser
minikube tunnel                         # expose LoadBalancer services to localhost
minikube service NAME --url             # print NodePort service URL
minikube addons list                    # list available addons
minikube addons enable metrics-server   # enable metrics-server addon
minikube addons enable ingress          # enable NGINX ingress controller
minikube ip                             # print cluster IP
minikube logs                           # view minikube logs
```

---

## Pods

```bash
kubectl run NAME --image=IMAGE                          # create a standalone pod
kubectl run NAME --image=IMAGE --port=8080              # pod with port exposed
kubectl run NAME --image=IMAGE --env="KEY=VAL"          # pod with env var
kubectl get pods                                        # list pods in current namespace
kubectl get pods -o wide                                # include node and IP columns
kubectl get pods -o yaml                                # full YAML output
kubectl get pods -o json                                # full JSON output
kubectl get pods -w                                     # watch for changes
kubectl describe pod NAME                               # detailed info: events, conditions, mounts
kubectl logs NAME                                       # stdout logs
kubectl logs NAME -f                                    # follow/stream logs
kubectl logs NAME -c CONTAINER                          # logs from specific container (multi-container pod)
kubectl logs NAME --previous                            # logs from last (crashed) container run
kubectl logs NAME --tail=100                            # last 100 lines
kubectl exec -it NAME -- /bin/sh                        # interactive shell into pod
kubectl exec -it NAME -c CONTAINER -- /bin/bash         # shell into specific container
kubectl exec NAME -- env                                # run one-off command (list env vars)
kubectl delete pod NAME                                 # delete pod (ReplicaSet will recreate it)
kubectl delete pod NAME --force --grace-period=0        # force delete stuck pod
kubectl port-forward pod/NAME 8080:80                   # forward local:remote port
kubectl cp pod/NAME:/remote/path ./local-path            # copy file from pod to local
kubectl cp ./local-path pod/NAME:/remote/path           # copy file from local to pod
```

---

## Deployments

```bash
kubectl create deployment NAME --image=IMAGE                        # create deployment (1 replica)
kubectl create deployment NAME --image=IMAGE --replicas=3           # create with N replicas
kubectl get deployments                                             # list deployments
kubectl get deployments -o wide                                     # include image column
kubectl describe deployment NAME                                    # detailed deployment info
kubectl scale deployment NAME --replicas=N                          # scale up or down
kubectl set image deployment/NAME CONTAINER=IMAGE:TAG               # update container image
kubectl rollout status deployment/NAME                              # watch rollout progress
kubectl rollout history deployment/NAME                             # list revision history
kubectl rollout history deployment/NAME --revision=2                # details of specific revision
kubectl rollout undo deployment/NAME                                # rollback to previous revision
kubectl rollout undo deployment/NAME --to-revision=N                # rollback to specific revision
kubectl rollout pause deployment/NAME                               # pause (stop mid-rollout)
kubectl rollout resume deployment/NAME                              # resume paused rollout
kubectl autoscale deployment NAME --min=2 --max=10 --cpu-percent=80 # create HPA
kubectl get hpa                                                     # list HorizontalPodAutoscalers
kubectl delete deployment NAME                                      # delete deployment
```

---

## Services

```bash
kubectl expose deployment NAME --port=80 --target-port=8080                 # ClusterIP service (default)
kubectl expose deployment NAME --port=80 --target-port=8080 --type=NodePort # NodePort service
kubectl expose deployment NAME --port=80 --type=LoadBalancer                # LoadBalancer service
kubectl get svc                                                              # list services
kubectl get svc -o wide                                                      # include selector column
kubectl describe svc NAME                                                    # detailed service info
kubectl get endpoints NAME                                                   # list endpoints (pod IPs) for service
kubectl delete svc NAME                                                      # delete service
```

### Service Types

| Type         | Accessibility                  | Use Case                          |
|--------------|--------------------------------|-----------------------------------|
| ClusterIP    | Internal cluster only (default)| Service-to-service communication  |
| NodePort     | External via `<NodeIP>:<Port>` | Dev/testing, direct node access   |
| LoadBalancer | External via cloud LB          | Production, cloud environments    |
| ExternalName | DNS alias to external service  | Routing to external dependencies  |

---

## ConfigMaps & Secrets

```bash
# ConfigMaps
kubectl create configmap NAME --from-literal=key=val                # single key-value pair
kubectl create configmap NAME --from-literal=k1=v1 --from-literal=k2=v2  # multiple pairs
kubectl create configmap NAME --from-file=path/to/file              # file content as value
kubectl create configmap NAME --from-file=key=path/to/file          # file with custom key
kubectl create configmap NAME --from-env-file=.env                  # from .env file
kubectl get configmap NAME -o yaml                                   # view configmap content
kubectl describe configmap NAME                                      # view configmap details
kubectl edit configmap NAME                                          # live-edit configmap
kubectl delete configmap NAME                                        # delete configmap

# Secrets
kubectl create secret generic NAME --from-literal=key=val           # generic secret
kubectl create secret generic NAME --from-file=path/to/file         # secret from file
kubectl create secret docker-registry NAME \
  --docker-server=REGISTRY \
  --docker-username=USER \
  --docker-password=PASS                                             # image pull secret
kubectl get secret NAME -o yaml                                      # view secret (base64 encoded)
kubectl describe secret NAME                                         # view secret metadata (no values)

# Encode/decode base64 (secrets are stored base64 encoded)
echo -n "my-value" | base64                                         # encode value for secret
echo "bXktdmFsdWU=" | base64 -d                                    # decode secret value
kubectl get secret NAME -o jsonpath='{.data.KEY}' | base64 -d      # decode specific secret field
```

---

## Volumes & Storage

```bash
kubectl get pv                          # list PersistentVolumes (cluster-wide)
kubectl get pvc                         # list PersistentVolumeClaims (namespaced)
kubectl get sc                          # list StorageClasses
kubectl describe pvc NAME               # check PVC binding status
kubectl describe pv NAME                # check PV details and reclaim policy
kubectl delete pvc NAME                 # delete PVC (may trigger PV deletion based on policy)
```

### Volume Types (in pod spec)

| Type          | Use Case                                        |
|---------------|-------------------------------------------------|
| emptyDir      | Temp storage, shared between containers in pod  |
| hostPath      | Mount host node path (dev only, not portable)   |
| configMap     | Mount configmap as files                        |
| secret        | Mount secret as files                           |
| persistentVolumeClaim | Durable storage via PVC               |

---

## Namespaces

```bash
kubectl create namespace NAME           # create namespace (long form)
kubectl create ns NAME                  # create namespace (short form)
kubectl get namespaces                  # list all namespaces
kubectl get ns                          # list namespaces (short form)
kubectl get pods -n NAME                # list pods in specific namespace
kubectl get pods --all-namespaces       # list pods across all namespaces
kubectl get pods -A                     # same as --all-namespaces (short form)
kubectl get all -n NAME                 # all resources in a namespace
kubectl delete namespace NAME           # delete namespace and all its resources
kubectl config set-context --current --namespace=NAME  # set default namespace
```

---

## Resource Management

```bash
kubectl top pods                                        # pod CPU/memory usage (needs metrics-server)
kubectl top pods -n NAME                                # pods in specific namespace
kubectl top pods --sort-by=cpu                          # sort by CPU usage
kubectl top pods --sort-by=memory                       # sort by memory usage
kubectl top nodes                                       # node CPU/memory usage
kubectl describe node NAME | grep -A5 "Allocated"       # node resource allocation summary
kubectl get resourcequota -n NAME                       # list resource quotas in namespace
kubectl describe resourcequota NAME -n NAME             # show quota usage vs limits
kubectl get limitrange -n NAME                          # list default resource limits
```

### Resource Request/Limit Quick Reference

```yaml
resources:
  requests:
    memory: "64Mi"    # guaranteed minimum
    cpu: "250m"       # 0.25 cores
  limits:
    memory: "128Mi"   # hard cap (OOMKilled if exceeded)
    cpu: "500m"       # throttled if exceeded (not killed)
```

---

## Health Checks (Probes)

```yaml
# Liveness probe — restart container if failing
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 3

# Readiness probe — remove from service endpoints if failing
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 3

# Startup probe — allow slow-starting containers
startupProbe:
  httpGet:
    path: /healthz
    port: 8080
  failureThreshold: 30
  periodSeconds: 10
```

---

## Jobs & CronJobs

```bash
kubectl create job NAME --image=IMAGE -- COMMAND ARGS       # run one-off job
kubectl create job NAME --from=cronjob/CRONJOB-NAME         # manually trigger a cronjob
kubectl get jobs                                             # list jobs
kubectl get jobs -w                                          # watch job completion
kubectl describe job NAME                                    # job details and pod status
kubectl logs job/NAME                                        # view job logs
kubectl delete job NAME                                      # delete job (also deletes pods)

kubectl create cronjob NAME \
  --image=IMAGE \
  --schedule="*/5 * * * *" \
  -- COMMAND ARGS                                            # create cronjob (every 5 min)
kubectl get cronjobs                                         # list cronjobs
kubectl describe cronjob NAME                                # cronjob details
kubectl delete cronjob NAME                                  # delete cronjob
```

### Cron Schedule Reference

```
# ┌───── minute (0-59)
# │ ┌─── hour (0-23)
# │ │ ┌─ day of month (1-31)
# │ │ │ ┌ month (1-12)
# │ │ │ │ ┌ day of week (0-6, Sun=0)
# │ │ │ │ │
  * * * * *

*/5 * * * *     every 5 minutes
0 * * * *       every hour (on the hour)
0 0 * * *       daily at midnight
0 0 * * 0       weekly on Sunday midnight
```

---

## Debugging

```bash
# Pod inspection
kubectl describe pod NAME                               # events, conditions, container states
kubectl logs NAME --previous                            # logs from last crashed container
kubectl logs NAME -f --since=1h                         # stream logs from past hour
kubectl get pod NAME -o yaml                            # full pod spec + status
kubectl get pod NAME -o yaml | grep -A10 "status:"     # status section only

# Cluster-wide events
kubectl get events                                      # recent events (current namespace)
kubectl get events -A                                   # events across all namespaces
kubectl get events --sort-by=.lastTimestamp             # sorted by most recent
kubectl get events --field-selector type=Warning        # warnings only

# Temporary debug pods
kubectl run debug --image=busybox -it --rm -- sh        # busybox debug shell (auto-removed on exit)
kubectl run debug --image=nicolaka/netshoot -it --rm -- bash  # full networking debug toolkit
kubectl run debug --image=alpine -it --rm -- sh         # Alpine debug shell

# Debug a specific node
kubectl debug node/NODE-NAME -it --image=ubuntu         # privileged node debug pod

# Copy & exec
kubectl exec -it NAME -- wget -qO- http://SVC-NAME      # test service connectivity from inside pod
kubectl exec -it NAME -- nslookup SVC-NAME              # DNS lookup from inside pod
kubectl exec -it NAME -- env | sort                     # list all env vars in pod
```

### Common Pod Status States

| Status               | Meaning                                              | Action                              |
|----------------------|------------------------------------------------------|-------------------------------------|
| Pending              | Not yet scheduled or pulling image                   | Check events, node resources        |
| ContainerCreating    | Image pulled, container starting                     | Usually transient, wait briefly     |
| Running              | Container running normally                           | -                                   |
| CrashLoopBackOff     | Container keeps crashing and restarting              | Check logs --previous, check config |
| ImagePullBackOff     | Can't pull container image                           | Check image name, registry access   |
| ErrImagePull         | Image pull failed (first attempt)                    | Check image name, tag, credentials  |
| OOMKilled            | Container exceeded memory limit                      | Increase memory limit               |
| Terminating          | Pod being deleted (stuck = finalizer issue)          | Force delete if stuck               |
| Evicted              | Evicted due to node pressure                         | Check node disk/memory              |

---

## Helm

```bash
# Repository management
helm repo add NAME URL                              # add a chart repository
helm repo add stable https://charts.helm.sh/stable # add stable repo (example)
helm repo add bitnami https://charts.bitnami.com/bitnami  # add bitnami repo
helm repo update                                    # refresh repo index (always run before install)
helm repo list                                      # list configured repos
helm repo remove NAME                               # remove a repo

# Searching
helm search repo KEYWORD                            # search all configured repos
helm search repo KEYWORD --versions                 # include all chart versions
helm search hub KEYWORD                             # search Artifact Hub (public registry)
helm show chart CHART                               # show chart metadata
helm show values CHART                              # show default values.yaml

# Installing & managing releases
helm install RELEASE CHART                          # install with all defaults
helm install RELEASE CHART --set key=val            # install with inline value override
helm install RELEASE CHART --set key=val,key2=val2  # multiple inline overrides
helm install RELEASE CHART -f values.yaml           # install with custom values file
helm install RELEASE CHART -n NAMESPACE             # install into specific namespace
helm install RELEASE CHART --create-namespace       # create namespace if it doesn't exist
helm install RELEASE CHART --dry-run                # simulate install (no changes)
helm install RELEASE CHART --debug                  # verbose output during install

# Upgrading
helm upgrade RELEASE CHART                          # upgrade release to latest chart version
helm upgrade RELEASE CHART --set key=val            # upgrade with value override
helm upgrade RELEASE CHART -f values.yaml           # upgrade with values file
helm upgrade --install RELEASE CHART                # install if not present, upgrade if present
helm upgrade RELEASE CHART --reset-values           # reset to chart defaults before applying overrides
helm upgrade RELEASE CHART --reuse-values           # keep existing values, apply only new overrides

# Inspecting releases
helm list                                           # list releases in current namespace
helm list -A                                        # list releases across all namespaces
helm list --failed                                  # list failed releases
helm status RELEASE                                 # show release status and notes
helm get values RELEASE                             # show user-supplied values for release
helm get values RELEASE --all                       # show all values (user + defaults)
helm get manifest RELEASE                           # show rendered Kubernetes manifests
helm history RELEASE                                # show upgrade history

# Rollback & uninstall
helm rollback RELEASE                               # rollback to previous revision
helm rollback RELEASE N                             # rollback to revision N
helm uninstall RELEASE                              # remove release and all its resources
helm uninstall RELEASE --keep-history               # remove but keep history

# Chart development
helm create NAME                                    # scaffold new chart directory
helm lint CHART                                     # validate chart for errors/warnings
helm template RELEASE CHART                         # render templates locally (no install)
helm template RELEASE CHART -f values.yaml          # render with custom values
helm package CHART                                  # package chart into .tgz archive
```

---

## YAML Generation Shortcuts

Generate YAML without creating resources using `--dry-run=client -o yaml`:

```bash
# Deployment YAML
kubectl create deployment NAME --image=IMAGE --replicas=2 \
  --dry-run=client -o yaml > deploy.yaml

# Service YAML
kubectl expose deployment NAME --port=80 --target-port=8080 \
  --dry-run=client -o yaml > svc.yaml

# Pod YAML
kubectl run NAME --image=IMAGE --port=8080 \
  --dry-run=client -o yaml > pod.yaml

# ConfigMap YAML
kubectl create configmap NAME --from-literal=key=val \
  --dry-run=client -o yaml > configmap.yaml

# Namespace YAML
kubectl create namespace NAME --dry-run=client -o yaml > ns.yaml
```

### Applying & Diffing

```bash
kubectl apply -f file.yaml              # create or update resources from file
kubectl apply -f ./directory/           # apply all YAML files in a directory
kubectl apply -f https://url/file.yaml  # apply from URL
kubectl delete -f file.yaml            # delete resources defined in file
kubectl diff -f file.yaml              # show what would change before applying
kubectl replace -f file.yaml           # replace resource (fails if not exists)
kubectl replace --force -f file.yaml   # delete and recreate resource
```

---

## Labels & Selectors

```bash
kubectl get pods -l app=NAME                        # filter by single label
kubectl get pods -l app=NAME,env=prod               # filter by multiple labels (AND)
kubectl get pods -l 'env in (prod,staging)'         # set-based selector
kubectl get pods -l 'env notin (dev)'               # negative set selector
kubectl label pod NAME key=val                      # add or update label on pod
kubectl label pod NAME key-                         # remove label from pod (note the dash)
kubectl label node NAME role=worker                 # label a node
kubectl get pods --show-labels                      # show all labels as a column
kubectl get all -l app=NAME                         # get all resource types with label
kubectl annotate pod NAME key=val                   # add annotation to resource
```

---

## Networking

```bash
kubectl get ingress                                 # list ingress resources
kubectl get ingress -o wide                         # include address column
kubectl describe ingress NAME                       # ingress details and rules
kubectl get networkpolicies                         # list network policies
kubectl get netpol                                  # list network policies (short form)
kubectl describe netpol NAME                        # network policy details
```

### DNS Resolution Inside the Cluster

```bash
# Service DNS (accessible from any pod in the cluster)
<svc-name>.<namespace>.svc.cluster.local
<svc-name>.<namespace>           # short form (works across namespaces)
<svc-name>                       # shortest form (same namespace only)

# Pod DNS
<pod-ip-with-dashes>.<namespace>.pod.cluster.local
# Example: 10-244-0-5.default.pod.cluster.local

# Headless service (StatefulSet) — individual pod DNS
<pod-name>.<svc-name>.<namespace>.svc.cluster.local
```

### Testing DNS from Inside a Pod

```bash
kubectl exec -it NAME -- nslookup kubernetes.default    # resolve default service
kubectl exec -it NAME -- nslookup SVC-NAME              # resolve a service by name
kubectl exec -it NAME -- wget -qO- http://SVC-NAME/     # HTTP request to service
kubectl exec -it NAME -- wget -qO- http://SVC-NAME.NAMESPACE/  # cross-namespace
```

---

## Multi-Container Pods

```bash
# Specify container when pod has multiple
kubectl logs POD-NAME -c CONTAINER-NAME
kubectl exec -it POD-NAME -c CONTAINER-NAME -- sh
kubectl describe pod POD-NAME  # lists all containers and their states
```

### Sidecar Patterns

| Pattern    | Purpose                                               | Example                        |
|------------|-------------------------------------------------------|--------------------------------|
| Sidecar    | Extends main container with a support process         | Log shipper, proxy             |
| Ambassador | Proxy for external service access                     | Envoy, nginx proxy             |
| Adapter    | Normalizes output format of main container            | Prometheus exporter            |
| Init       | Runs to completion before main containers start       | DB migration, config setup     |

---

## Quick One-Liners

```bash
# Get all resource types in a namespace
kubectl get all -n NAMESPACE

# Watch pods update during a rollout
kubectl get pods -w -l app=NAME

# Force restart a deployment (no config changes)
kubectl rollout restart deployment/NAME

# Get image currently used by a deployment
kubectl get deployment NAME -o jsonpath='{.spec.template.spec.containers[*].image}'

# List all images running in the cluster
kubectl get pods -A -o jsonpath='{range .items[*]}{.spec.containers[*].image}{"\n"}{end}' | sort -u

# Delete all pods in CrashLoopBackOff
kubectl get pods | grep CrashLoopBackOff | awk '{print $1}' | xargs kubectl delete pod

# Port-forward a service (not just pods)
kubectl port-forward svc/NAME 8080:80

# Scale all deployments in a namespace to 0 (useful for saving resources)
kubectl scale deployment --all --replicas=0 -n NAMESPACE

# Get pod node assignment
kubectl get pods -o wide

# Show resource usage sorted by memory
kubectl top pods --sort-by=memory -A

# Quickly check what's wrong with a pod
kubectl describe pod NAME | tail -20   # shows recent events at the bottom
```
