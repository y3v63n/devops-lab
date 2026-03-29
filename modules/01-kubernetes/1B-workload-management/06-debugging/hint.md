# Hints — Exercise 1B-06: Debugging

## Hint 1 — General Debugging Workflow
Always start with this sequence:
```bash
# 1. See the symptom
kubectl get pods

# 2. Get details and events
kubectl describe pod <pod-name>

# 3. Read logs
kubectl logs <pod-name>
kubectl logs <pod-name> --previous   # if it keeps restarting

# 4. Fix and verify
kubectl rollout status deployment/<name>
```

## Hint 2 — broken-image (ImagePullBackOff)
Look in `kubectl describe pod` for this event:
```
Failed to pull image "nginx:99.99.99": ... manifest unknown
```
The fix is simple — change the image to a valid tag:
```bash
kubectl set image deployment/broken-image nginx=nginx:1.25
```

## Hint 3 — broken-probe (CrashLoopBackOff from probe)
The pod starts successfully (nginx is running on port 80), but the liveness probe checks port 9999, which nothing listens on. Kubernetes thinks the container is dead and kills it.

Look for in `describe pod`:
```
Liveness probe failed: Get "http://10.x.x.x:9999/": dial tcp ... connection refused
```

Fix by patching the probe port:
```bash
kubectl patch deployment broken-probe --type=json -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/livenessProbe/httpGet/port", "value": 80}
]'
```

## Hint 4 — broken-selector (no endpoints)
The deployment pods are healthy. The problem is the Service.

Check for endpoints:
```bash
kubectl get endpoints broken-selector-svc
# Shows: broken-selector-svc   <none>   ...
```

Check what labels the pods have:
```bash
kubectl get pods -l app=broken-selector --show-labels
# Shows labels: app=broken-selector
```

Check what the service is selecting:
```bash
kubectl describe service broken-selector-svc | grep Selector
# Shows: Selector: label=wrong
```

Fix the selector:
```bash
kubectl patch service broken-selector-svc --type=merge \
  -p '{"spec":{"selector":{"app":"broken-selector"}}}'
```

## Hint 5 — Connectivity Test
If `kubectl run debug-pod` with `--rm -it` is timing out, use the non-interactive form:
```bash
kubectl run debug --image=busybox:1.35 --restart=Never \
  -- wget -qO- --timeout=5 http://broken-image-svc
sleep 5
kubectl logs debug
kubectl delete pod debug
```

## Common Mistakes
- `kubectl describe` shows events at the bottom — scroll down!
- `--previous` flag on logs is essential for CrashLoopBackOff — current logs may be empty
- Service selectors are AND conditions — ALL key=value pairs must match
- `kubectl get endpoints` showing `<none>` always means selector mismatch
