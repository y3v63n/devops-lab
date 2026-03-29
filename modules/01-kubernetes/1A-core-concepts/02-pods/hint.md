# Hints — Exercise 1A-02: Pods

## Task 1 — Generate YAML
`--dry-run=client` prevents kubectl from sending the request to the API server. `-o yaml` outputs the object as YAML. Together they let you preview exactly what object would be created.

```bash
# If you just want to see the YAML without saving:
kubectl run lab-nginx --image=nginx:alpine --dry-run=client -o yaml

# Save and then apply:
kubectl run lab-nginx --image=nginx:alpine --dry-run=client -o yaml \
  | tee /tmp/devops-lab/1A-02/pod.yaml
kubectl apply -f /tmp/devops-lab/1A-02/pod.yaml
```

If the pod already exists (from a previous attempt), delete it first:
```bash
kubectl delete pod lab-nginx --ignore-not-found
```

## Task 2 — Exec Into Pod
Wait for the pod to be Ready before trying to exec:
```bash
kubectl get pod lab-nginx -w   # watch until Running
# Ctrl+C when Running, then:
kubectl exec -it lab-nginx -- sh
# Inside the shell:
echo "Hello K8s" > /usr/share/nginx/html/devops.html
exit
```

Or do it non-interactively with `-c`:
```bash
kubectl exec lab-nginx -- sh -c 'echo "Hello K8s" > /usr/share/nginx/html/devops.html'
```

## Task 3 — Port-Forward
The `&` runs port-forward in the background. If port 8088 is already in use, try a different local port (e.g., 8089:80).

```bash
kubectl port-forward pod/lab-nginx 8088:80 &
sleep 2
curl http://localhost:8088/devops.html
```

If curl returns a 404, the HTML file was not written correctly in Task 2. Check:
```bash
kubectl exec lab-nginx -- ls /usr/share/nginx/html/
```

## Task 4 — Logs
nginx logs each HTTP request. After the curl in Task 3, you should see GET requests in the logs.

```bash
kubectl logs lab-nginx | tee /tmp/devops-lab/1A-02/pod-logs.txt
kubectl delete pod lab-nginx
```

## General Tips
- `kubectl describe pod lab-nginx` shows events, which are invaluable for debugging why a pod won't start (image pull errors, resource limits, etc.).
- `kubectl get pod lab-nginx -o yaml` shows the full live manifest including status fields.
- The `initContainers` field in a Pod spec lets you run setup containers before the main container starts.
