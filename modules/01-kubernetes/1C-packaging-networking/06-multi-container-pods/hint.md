# Hints — Exercise 1C-06: Multi-Container Pods

## Task 1 Hints

<details>
<summary>Hint 1: Pod is stuck in Init:0/1 state</summary>

This means the init container is still running or failed. Check its status:
```bash
kubectl describe pod init-demo
kubectl logs init-demo -c init-writer
```

If the init container failed, look for the error in the logs. Common issues:
- Command syntax error in the shell script
- Wrong volume mount path
</details>

<details>
<summary>Hint 2: Main container doesn't see the config file</summary>

Verify the volume mount paths in the YAML:
- Init container writes to `/shared/app.conf` (mountPath: `/shared`)
- Main container reads from `/config/app.conf` (mountPath: `/config`)

Both must mount the SAME volume (`shared-config`). The mount paths can differ — that's the point.
</details>

<details>
<summary>Hint 3: YAML indentation for initContainers</summary>

`initContainers` is at the same level as `containers`:
```yaml
spec:
  initContainers:   # ← same indent level as containers
  - name: init-writer
    ...
  containers:
  - name: main-app
    ...
  volumes:
  - name: shared-config
    emptyDir: {}
```
</details>

---

## Task 2 Hints

<details>
<summary>Hint 1: How to see both containers running</summary>

```bash
kubectl get pod sidecar-demo
# READY column shows 2/2 when both containers are running

kubectl describe pod sidecar-demo
# Shows both containers in the Containers section
```
</details>

<details>
<summary>Hint 2: tail -f won't show output in kubectl logs immediately</summary>

The log-reader uses `tail -f`. kubectl logs follows the container's stdout. Give it a few seconds:
```bash
kubectl logs sidecar-demo -c log-reader --tail=10
# Wait a few seconds, then run again to see new entries
kubectl logs sidecar-demo -c log-reader -f
# Or follow in real time (Ctrl+C to stop)
```
</details>

---

## Task 3 Hints

<details>
<summary>Hint 1: What to look for in kubectl describe output</summary>

The key section is at the bottom of `kubectl describe pod init-demo`:
```
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  2m    default-scheduler  Successfully assigned default/init-demo to minikube
  Normal  Pulling    2m    kubelet            Pulling image "busybox" (init container)
  Normal  Started    2m    kubelet            Started container init-writer
  Normal  Completed  2m    kubelet            ...init container exited
  Normal  Started    1m    kubelet            Started container main-app
```

This sequence proves init ran before main.
</details>

---

## Task 4 Hints

<details>
<summary>Hint: Ambassador pattern clarification</summary>

The ambassador pattern is about **network proxying**. The main container connects to `localhost:PORT` (simple), and the ambassador container handles the complexity of the real connection (service discovery, TLS, connection pooling).

This differs from sidecar:
- Sidecar: enhances/extends (logging, metrics)
- Ambassador: proxies/abstracts (network connectivity)

For patterns.txt, write 3-5 sentences per pattern. No automated content check — just ensure the file is non-empty.
</details>

---

## Verify Troubleshooting

<details>
<summary>verify.sh says "init-demo pod is Running" fails</summary>

The init container may have failed, leaving the pod in `Init:Error` or `CrashLoopBackOff`. Check:
```bash
kubectl get pod init-demo
kubectl logs init-demo -c init-writer
kubectl describe pod init-demo | tail -20
```

Fix the YAML, delete the pod, and reapply:
```bash
kubectl delete pod init-demo
kubectl apply -f /tmp/devops-lab/1C-06/init-container.yaml
```
</details>

<details>
<summary>verify.sh says "sidecar.yaml defines 2 containers" fails</summary>

The check counts lines matching `^\s*- name:` in the YAML. Make sure each container has a `- name:` entry under `containers:`. The check requires at least 2 such entries.
</details>
