# Hints — Exercise 1B-04: Rolling Updates

## Hint 1 (Try this first)
The rolling update strategy must be nested correctly in the deployment spec:
```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```
This is at the `spec` level of the Deployment, not inside the pod template.

## Hint 2
For Task 2, `kubectl set image` is the fastest way to trigger an update:
```bash
kubectl set image deployment/rolling-demo nginx=nginx:1.25
```
The container name (`nginx`) must match the name in your YAML. Check with:
```bash
kubectl get deployment rolling-demo -o jsonpath='{.spec.template.spec.containers[*].name}'
```

## Hint 3
`kubectl rollout status` blocks until complete or times out. For Task 3 (the bad image), it will hang. Use a timeout:
```bash
kubectl rollout status deployment/rolling-demo --timeout=30s || echo "Rollout timed out/failed"
```
The `|| true` prevents your script from exiting on failure.

## Hint 4
During the bad rollout, you'll see the new pods stuck in `ImagePullBackOff` but the old pods still running. This is because `maxUnavailable=0` — Kubernetes won't kill the working pods until the new ones are ready.

## Hint 5
For rollback, `undo` rolls back one step:
```bash
kubectl rollout undo deployment/rolling-demo
```
For a specific revision:
```bash
kubectl rollout undo deployment/rolling-demo --to-revision=1
```
Check revision numbers with `kubectl rollout history deployment/rolling-demo`.

## Common Mistakes
- `maxSurge: 0` AND `maxUnavailable: 0` is invalid — Kubernetes will reject it
- `kubectl rollout status` exits 0 on success, non-zero on failure — useful in CI pipelines
- The revision history only shows revisions if you annotated changes with `--record` (deprecated) or if there were actual spec changes
