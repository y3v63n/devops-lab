# Hints — Exercise 1B-02: Resource Limits

## Hint 1 (Try this first)
For Task 1, write the YAML to the file first, then apply it:
```bash
kubectl apply -f /tmp/devops-lab/1B-02/resource-pod.yaml
```
The YAML needs both `requests` and `limits` nested under `resources`.

## Hint 2
The resource block structure looks like:
```yaml
resources:
  requests:
    cpu: "100m"
    memory: "64Mi"
  limits:
    cpu: "200m"
    memory: "128Mi"
```
Make sure indentation is correct — YAML is whitespace-sensitive.

## Hint 3
For Task 2, if you don't want to use `--overrides`, write a YAML file instead:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: memory-hog
spec:
  containers:
  - name: memory-hog
    image: nginx:1.25
    resources:
      requests:
        memory: "999Gi"
```
The pod will stay Pending because no node can provide 999Gi.

## Hint 4
For the describe output, look at the Events section at the bottom:
```
Events:
  Warning  FailedScheduling  ...  0/1 nodes are available: 1 Insufficient memory
```
This is the key line to capture in pending-reason.txt.

## Hint 5
For Task 3, if `kubectl top pods` returns an error about metrics not being available, metrics-server may not be installed. Check:
```bash
kubectl get deployment metrics-server -n kube-system
```
It's okay to write an error message to metrics.txt — the verify script just checks the file has content.

## Common Mistakes
- CPU requests/limits use millicores (`m`) — `100m` not `100`
- Memory uses `Mi` (mebibytes) or `Gi` (gibibytes) — avoid just `M` or `G`
- Requests are for scheduling; limits are runtime enforcement
- A pod can be Pending even if a node exists — the node must have enough *available* resources
