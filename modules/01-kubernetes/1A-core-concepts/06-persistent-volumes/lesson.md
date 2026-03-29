# Exercise 1A-06: Persistent Volumes

## Theory

Containers are stateless by design — when a container restarts, its filesystem is wiped clean. For stateful workloads (databases, file uploads, message queues), Kubernetes provides a storage abstraction layer that decouples how storage is provisioned from how it is consumed.

### The Three-Layer Storage Model

**PersistentVolume (PV)** represents a piece of actual storage — an NFS share, a cloud disk (AWS EBS, GCP PD), or a local path. PVs are cluster-scoped (not namespaced). An admin provisions them manually or a StorageClass provisions them dynamically. A PV has a lifecycle independent of any Pod.

**PersistentVolumeClaim (PVC)** is a request for storage by a user. It specifies the size, access mode, and optionally a StorageClass. Kubernetes binds a PVC to a matching PV. PVCs are namespace-scoped. Pods reference PVCs (not PVs directly), which decouples app developers from infrastructure details.

**StorageClass** defines the type and properties of storage. It enables **dynamic provisioning** — when a PVC requests a storage class, the cluster automatically creates a PV. Different classes can represent tiers (fast SSD vs slow HDD) or different backup policies.

```
Developer                     Infrastructure
─────────                     ──────────────
PVC                           PV
(request 100Mi fast storage)  (actual AWS EBS volume)
       │                             │
       └─────── StorageClass ────────┘
                (standard/fast/cold)
                enables dynamic provisioning
```

### Access Modes

- **ReadWriteOnce (RWO)**: Mounted read-write by a single node. Most block storage (EBS, GCE PD).
- **ReadOnlyMany (ROX)**: Mounted read-only by many nodes. NFS, cloud file storage.
- **ReadWriteMany (RWX)**: Mounted read-write by many nodes. NFS, cloud file storage (EFS, Filestore).
- **ReadWriteOncePod (RWOP)**: Mounted read-write by a single pod (K8s 1.22+).

### Reclaim Policy

What happens to a PV when its PVC is deleted?
- **Retain**: PV is kept with all data. Requires manual cleanup before it can be reused.
- **Delete**: PV and underlying storage are automatically deleted. Common for dynamically provisioned volumes.
- **Recycle** (deprecated): Data is scrubbed (`rm -rf`) and PV is made available again.

---

## Tasks

### Setup
```bash
mkdir -p /tmp/devops-lab/1A-06
```

### Task 1 — Create a PVC
```bash
cat << 'EOF' | tee /tmp/devops-lab/1A-06/pvc.yaml | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
EOF

# Watch for it to bind (may take a moment for dynamic provisioning):
kubectl get pvc data-pvc -w
# Ctrl+C when STATUS shows Bound
```

### Task 2 — Pod Mounting the PVC
```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: writer-pod
spec:
  containers:
  - name: writer
    image: busybox:latest
    command: ["sh", "-c", "echo 'persistent data' > /data/test.txt && sleep 300"]
    volumeMounts:
    - name: data-vol
      mountPath: /data
  volumes:
  - name: data-vol
    persistentVolumeClaim:
      claimName: data-pvc
EOF

kubectl wait pod/writer-pod --for=condition=Ready --timeout=60s

# Verify data was written:
kubectl exec writer-pod -- cat /data/test.txt
```

### Task 3 — Prove Persistence Across Pod Deletion
```bash
# Delete the first pod:
kubectl delete pod writer-pod

# Create a new pod using the SAME PVC:
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: reader-pod
spec:
  containers:
  - name: reader
    image: busybox:latest
    command: ["sleep", "300"]
    volumeMounts:
    - name: data-vol
      mountPath: /data
  volumes:
  - name: data-vol
    persistentVolumeClaim:
      claimName: data-pvc
EOF

kubectl wait pod/reader-pod --for=condition=Ready --timeout=60s

# Read the data — it should survive pod deletion:
kubectl exec reader-pod -- cat /data/test.txt \
  | tee /tmp/devops-lab/1A-06/persistence-proof.txt
```

### Task 4 — Explain Storage Concepts
```bash
cat > /tmp/devops-lab/1A-06/storage-notes.txt << 'EOF'
PersistentVolume (PV):
  - Cluster-scoped storage resource provisioned by an admin or dynamically by StorageClass.
  - Represents actual backing storage (EBS volume, NFS export, local disk).
  - Lifecycle is independent of Pods.

PersistentVolumeClaim (PVC):
  - Namespace-scoped storage request by a user/developer.
  - Specifies size and access mode; Kubernetes binds it to a matching PV.
  - Pods reference PVCs — developers never need to know the underlying storage details.

StorageClass:
  - Defines storage "types" (fast-ssd, standard, cold).
  - Enables dynamic provisioning: PVC request → StorageClass → auto-created PV.
  - Different classes can have different reclaim policies, replication, encryption settings.

Reclaim Policies:
  - Retain: PV persists after PVC deletion; manual cleanup required before reuse.
  - Delete: PV and backing storage are automatically deleted when PVC is deleted.
  - Use Retain for critical data; Delete for ephemeral/dev workloads.
EOF
```

---

## Interview Question

**"What happens to a PersistentVolume when its PersistentVolumeClaim is deleted? How does the Retain policy differ from Delete?"**

Think about:
- With **Retain**: PV moves to `Released` phase. The data is still there. The PV cannot be automatically rebound — an admin must manually remove the `claimRef` before it can be claimed again. Safe for production databases.
- With **Delete**: PV and the underlying storage asset (e.g., EBS volume) are both deleted. Data is gone. Suitable for scratch/cache volumes.
- The `kubectl get pv` output shows the `RECLAIM POLICY` and `STATUS` columns — practice reading them.
- **StatefulSets** use `volumeClaimTemplates` to automatically create a PVC per Pod replica, giving each replica its own persistent storage. This is how you run databases in K8s.

---

## What Just Happened

When you deleted `writer-pod`, Kubernetes removed the Pod object and released the container's writable layer. But the PVC still existed, meaning the PV was still bound and the data on it was intact. When `reader-pod` started and mounted the same PVC, it got the same underlying volume — and `test.txt` was right there. This is the fundamental guarantee of PersistentVolumes: storage outlives individual Pods.

In a cloud environment, the `data-pvc` would have triggered dynamic provisioning — a StorageClass provisioner (e.g., the AWS EBS CSI driver) would have created an actual EBS volume, formatted it, and attached it to the node where your Pod was scheduled.
