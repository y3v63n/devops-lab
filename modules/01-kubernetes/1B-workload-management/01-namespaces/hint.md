# Hints — Exercise 1B-01: Namespaces

## Hint 1 (Try this first)
For Task 1, namespaces are created with `kubectl create namespace <name>`. To redirect output to a file, use `>` after the command.

## Hint 2
For Task 2, the `-n` flag specifies a namespace: `kubectl create deployment ... -n dev`. Don't forget to do this for both deployments separately.

## Hint 3
For Task 3, you need a service to expose the dev nginx deployment first:
```bash
kubectl expose deployment nginx --port=80 -n dev
```
Then the FQDN becomes: `nginx.dev.svc.cluster.local`

## Hint 4
For the cross-namespace curl, run a temporary busybox pod in staging:
```bash
kubectl run test-pod --image=busybox:1.35 -n staging --rm -it --restart=Never \
  -- wget -qO- http://nginx.dev.svc.cluster.local
```
Redirect the output to `/tmp/devops-lab/1B-01/cross-ns.txt`. If the command hangs, the service might not be ready yet — check `kubectl get pods -n dev`.

## Hint 5
For Task 4, setting the context namespace:
```bash
kubectl config set-context --current --namespace=dev
```
Verify with: `kubectl config view --minify | grep namespace`

## Stuck on DNS?
Cross-namespace DNS requires CoreDNS running in kube-system. Check:
```bash
kubectl get pods -n kube-system | grep coredns
```

## Common Mistakes
- Forgetting `-n <namespace>` when creating deployments — they'll land in `default`
- The FQDN format: it's `service.namespace.svc.cluster.local` (not `namespace.service...`)
- Namespace deletion cascades — all pods/services inside are deleted too
