# Exercise 1A-03: Deployments

## Theory

A **Deployment** is the standard way to run stateless applications in Kubernetes. It provides declarative updates, rolling upgrades, rollback, and self-healing for your Pods. Understanding the three-layer hierarchy is essential.

### The Hierarchy: Deployment → ReplicaSet → Pod

**Pod** is the leaf node — it runs your containers. Pods are mortal; they don't reschedule themselves if they die.

**ReplicaSet** ensures that a specified number of Pod replicas are running at any given time. If a Pod is deleted or crashes, the ReplicaSet creates a new one. You rarely interact with ReplicaSets directly.

**Deployment** manages ReplicaSets. When you update a Deployment (e.g., new image), it creates a *new* ReplicaSet and gradually scales it up while scaling the old one down. This is the rolling update mechanism. The old ReplicaSet is retained (scaled to 0) to enable rollback.

```
Deployment (web-app)
│  desired: 3 replicas, nginx:1.25
│
├── ReplicaSet (web-app-7d6b8c9f4)   ← current (nginx:1.25, 3 pods)
│   ├── Pod (web-app-7d6b8c9f4-abc12)
│   ├── Pod (web-app-7d6b8c9f4-def34)
│   └── Pod (web-app-7d6b8c9f4-ghi56)
│
└── ReplicaSet (web-app-5c4d3b2a1)   ← previous (nginx:1.24, 0 pods)
    └── (scaled to 0 — kept for rollback)
```

### Rolling Update Strategy

The default update strategy is `RollingUpdate`. Two parameters control it:
- `maxUnavailable`: max number of Pods that can be unavailable during the update (default: 25%)
- `maxSurge`: max number of extra Pods that can be created above desired count (default: 25%)

This means K8s never takes down more than 25% of Pods at once, and never creates more than 125% total — ensuring zero downtime.

### Rollback

Every update creates a new entry in the deployment's revision history. `kubectl rollout undo` reverts to the previous revision by scaling the old ReplicaSet back up. You can view the full history with `kubectl rollout history`.

---

## Tasks

### Setup
```bash
mkdir -p /tmp/devops-lab/1A-03
```

### Task 1 — Create a Deployment
```bash
kubectl create deployment web-app \
  --image=nginx:1.24 \
  --replicas=3 \
  --dry-run=client -o yaml \
  | tee /tmp/devops-lab/1A-03/deployment.yaml

kubectl apply -f /tmp/devops-lab/1A-03/deployment.yaml

# Wait for rollout:
kubectl rollout status deployment/web-app
```

### Task 2 — Scale to 5 Replicas
```bash
kubectl scale deployment web-app --replicas=5

# Wait and then record pod names:
kubectl rollout status deployment/web-app
kubectl get pods -l app=web-app -o name | tee /tmp/devops-lab/1A-03/scaled-pods.txt
```

### Task 3 — Rolling Update to nginx:1.25
```bash
kubectl set image deployment/web-app nginx=nginx:1.25

# Watch the rollout (Ctrl+C when complete):
kubectl rollout status deployment/web-app | tee /tmp/devops-lab/1A-03/rollout.txt

# See the ReplicaSets to understand what happened:
kubectl get rs -l app=web-app
```

### Task 4 — Rollback and Record History
```bash
# View rollout history:
kubectl rollout history deployment/web-app

# Roll back to previous version:
kubectl rollout undo deployment/web-app

# Wait and record full history:
kubectl rollout status deployment/web-app
kubectl rollout history deployment/web-app | tee /tmp/devops-lab/1A-03/history.txt

# Confirm image reverted:
kubectl get deployment web-app -o jsonpath='{.spec.template.spec.containers[0].image}'
```

---

## Interview Question

**"Explain the relationship between a Deployment, a ReplicaSet, and a Pod."**

Think about:
- Deployment owns ReplicaSets; ReplicaSet owns Pods (via `ownerReferences`)
- Why Kubernetes uses this three-layer hierarchy instead of one layer
- What `kubectl rollout undo` actually does at the ReplicaSet level (rescales old RS up, new RS down)
- What happens to Pods when you `kubectl delete deployment web-app` (cascade delete: RS deleted → Pods deleted)
- How `--cascade=orphan` changes that behavior

---

## What Just Happened

When you ran `kubectl set image`, the Deployment controller noticed the desired state changed. It created a new ReplicaSet with the updated Pod template (a new template hash = new RS). Then it began the rolling update: incrementally scaling new RS up and old RS down, respecting `maxUnavailable` and `maxSurge` at each step.

`kubectl rollout undo` did not create a new ReplicaSet — it reused the existing old ReplicaSet (scaled back from 0 to 5), which is why rollback is fast. The revision history records these transitions.

The label selector on the Deployment (e.g., `app=web-app`) is how the Deployment finds its ReplicaSets, and how ReplicaSets find their Pods. This is why you must never change the `.spec.selector` of a Deployment after creation — it is immutable.
