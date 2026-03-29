# Hints — Exercise 1B-03: Health Checks

## Hint 1 (Try this first)
For Task 1, liveness probes go inside the container spec, at the same level as `image`:
```yaml
containers:
- name: nginx
  image: nginx:1.25
  livenessProbe:
    httpGet:
      path: /
      port: 80
```
Use `/` as the path since nginx serves the default page at root.

## Hint 2
For Task 2, the readiness probe uses `exec` to run a shell command. The pod will show `0/1` in the READY column until the file exists. This is intentional — observe it before moving to Task 3.

To see the Not Ready state clearly:
```bash
kubectl get pods -l app=readiness-demo
# Should show: 0/1   Running   0   ...
```

## Hint 3
For Task 3, you need the pod name to exec into it:
```bash
POD=$(kubectl get pod -l app=readiness-demo -o jsonpath='{.items[0].metadata.name}')
echo "Pod name: $POD"
kubectl exec $POD -- touch /tmp/ready
```
Then wait for the `periodSeconds` (5 seconds in the example) before checking again.

## Hint 4
For Task 4, the failing liveness pod has no `/tmp/alive` file, so every probe fails. After `failureThreshold` (2) failures, Kubernetes restarts the container. Watch the RESTARTS column go up:
```bash
kubectl get pods -l app=failing-liveness -w
```
Press Ctrl+C after you see at least 1 restart.

## Hint 5
If `kubectl describe pod` output is too long, filter it:
```bash
kubectl describe pod -l app=failing-liveness | grep -E "Restart Count|Liveness|Warning|Killing" | head -20
```

## Common Mistakes
- `httpGet` probes: nginx returns 404 for `/healthz` — 404 is a failure. Use `/` or set up a proper health endpoint
- `exec` probes: the command must exit with code 0 to be healthy; any non-zero exit = unhealthy
- `initialDelaySeconds` must be long enough for your app to start, or it'll be killed before it's ready
- Readiness and liveness are independent — both can be configured on the same container
