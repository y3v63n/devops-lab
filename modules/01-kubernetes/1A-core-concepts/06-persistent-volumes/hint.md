# Hints — Exercise 1A-06: Persistent Volumes

## Task 1 — Create PVC
If the PVC stays in `Pending` state, it means no PV matches the request. This can happen if:
- No default StorageClass is configured (check: `kubectl get storageclass`)
- The requested size is larger than any available PV
- The access mode doesn't match

```bash
# Check StorageClasses:
kubectl get storageclass

# In minikube, the default StorageClass is 'standard' (hostPath provisioner)
# In kind, you may need to install a local provisioner
# In cloud clusters, a default StorageClass is usually pre-configured

kubectl get pvc data-pvc -w   # watch for Bound status
```

## Task 2 — Pod with PVC
The Pod references the PVC by `claimName`. The volume is mounted at `/data`. The `command` writes the file immediately on startup.

```bash
# If Pod is stuck in Pending, it may be because the PVC is still Pending:
kubectl describe pod writer-pod
# Look for: "volume data-pvc is not yet available"

# After the pod is running, verify:
kubectl exec writer-pod -- cat /data/test.txt
# Should output: persistent data
```

## Task 3 — Prove Persistence
This is the core of the exercise. The old pod is gone, but the data must survive.

```bash
# Delete old pod:
kubectl delete pod writer-pod

# Create reader pod with the same PVC (data-pvc):
# (apply the reader-pod manifest from lesson.md)

kubectl wait pod/reader-pod --for=condition=Ready --timeout=60s
kubectl exec reader-pod -- cat /data/test.txt | tee /tmp/devops-lab/1A-06/persistence-proof.txt
```

If the file is gone, the PVC may have been accidentally deleted or the cluster uses ephemeral storage. Check: `kubectl get pvc data-pvc` — it should still show `Bound`.

## Task 4 — Storage Notes
Cover the three concepts and their relationship. Mention both reclaim policies with their use cases.

## General Tips
- `kubectl get pv` (no namespace — PVs are cluster-scoped) shows all PersistentVolumes and which PVC they're bound to.
- `kubectl describe pvc data-pvc` shows the bound PV name, capacity, and events.
- `kubectl get storageclass` shows available storage classes; the one marked `(default)` is used when no class is specified in the PVC.
- For local development without a cloud provider, `hostPath` volumes or `local` PVs work but are node-specific (not portable).
- **StatefulSets** are the right controller for databases — they create numbered, stable Pods (pod-0, pod-1) and automatically create one PVC per Pod via `volumeClaimTemplates`.
