# Hints — Exercise 1A-03: Deployments

## Task 1 — Create Deployment
The `--replicas` flag sets the initial replica count. Without it, the default is 1.

```bash
kubectl create deployment web-app --image=nginx:1.24 --replicas=3 \
  --dry-run=client -o yaml | tee /tmp/devops-lab/1A-03/deployment.yaml
kubectl apply -f /tmp/devops-lab/1A-03/deployment.yaml
```

If the deployment already exists, delete it first:
```bash
kubectl delete deployment web-app --ignore-not-found
```

## Task 2 — Scale
Scaling is immediate — kubectl sends a PATCH to the Deployment spec, and the ReplicaSet controller reconciles.

```bash
kubectl scale deployment web-app --replicas=5
# Watch pods come up:
kubectl get pods -l app=web-app -w
# Record names once all are Running:
kubectl get pods -l app=web-app -o name | tee /tmp/devops-lab/1A-03/scaled-pods.txt
```

Note the `-l app=web-app` label selector — this is how you filter to only this deployment's Pods.

## Task 3 — Rolling Update
`kubectl set image` takes the form: `deployment/<name> <container-name>=<new-image>`.

```bash
# Find the container name from the deployment spec:
kubectl get deployment web-app -o jsonpath='{.spec.template.spec.containers[0].name}'

# Then update (container name is usually same as deployment name or 'nginx'):
kubectl set image deployment/web-app nginx=nginx:1.25

# Watch in real time:
kubectl rollout status deployment/web-app
```

You can also trigger a rollout by editing the deployment:
```bash
kubectl edit deployment web-app
# Change .spec.template.spec.containers[0].image to nginx:1.25
```

## Task 4 — Rollback
```bash
# See all revisions (use --record flag next time to add change-cause):
kubectl rollout history deployment/web-app

# Roll back to the immediately previous version:
kubectl rollout undo deployment/web-app

# Roll back to a specific revision number:
kubectl rollout undo deployment/web-app --to-revision=1
```

To see what image each revision used:
```bash
kubectl rollout history deployment/web-app --revision=1
kubectl rollout history deployment/web-app --revision=2
```

## General Tips
- `kubectl get rs` shows all ReplicaSets; look for the old one with 0 desired/current/ready — that's your rollback target.
- `kubectl describe deployment web-app` shows Events including scaling activity.
- Add `--record` to update commands to populate the CHANGE-CAUSE column in history (deprecated in newer K8s, use annotations instead).
