# Hints — Exercise 1C-04: Network Policies

## Setup Hints

<details>
<summary>Hint: NetworkPolicies not working (traffic not blocked)</summary>

NetworkPolicy enforcement requires a CNI plugin that supports it. The default minikube CNI does not enforce policies.

To use Calico:
```bash
# Stop current minikube if running
minikube stop
minikube delete

# Start with Calico CNI
minikube start --network-plugin=cni --cni=calico

# Wait for Calico to be ready
kubectl wait --for=condition=ready pod \
  -l k8s-app=calico-node -n kube-system --timeout=120s
```

Note: You can still complete the exercise with the default CNI — policies will be created in the cluster, but blocking behavior won't be enforced. The verify.sh checks file existence and cluster resources, not actual enforcement.
</details>

---

## Task 1 Hints

<details>
<summary>Hint 1: Creating labeled pods</summary>

```bash
kubectl run web-pod --image=nginx --labels="role=web" -n netpol-lab
kubectl run db-pod --image=nginx --labels="role=db" -n netpol-lab
```

Verify labels were applied:
```bash
kubectl get pods -n netpol-lab --show-labels
```
</details>

---

## Task 2 Hints

<details>
<summary>Hint 1: NetworkPolicy podSelector vs ingress from podSelector</summary>

There are TWO podSelectors in a NetworkPolicy:

1. `spec.podSelector` — selects which pods this policy **applies to** (the db pods being protected)
2. `spec.ingress[].from[].podSelector` — selects which pods are **allowed** to connect (the web pods)

It's a common mistake to confuse these two.
</details>

<details>
<summary>Hint 2: Verifying the policy was applied</summary>

```bash
kubectl get networkpolicy -n netpol-lab
kubectl describe networkpolicy allow-web-to-db -n netpol-lab
```
The describe output shows which pods are selected and what traffic is allowed.
</details>

---

## Task 3 Hints

<details>
<summary>Hint 1: Getting the db pod IP</summary>

```bash
DB_IP=$(kubectl get pod db-pod -n netpol-lab -o jsonpath='{.status.podIP}')
echo "DB pod IP: $DB_IP"
```
</details>

<details>
<summary>Hint 2: Testing connectivity from pods</summary>

```bash
# From web-pod (should work)
kubectl exec web-pod -n netpol-lab -- wget -qO- --timeout=3 http://$DB_IP

# From test-pod (should be blocked with Calico)
kubectl exec test-pod -n netpol-lab -- wget -qO- --timeout=3 http://$DB_IP
```

If test-pod doesn't exist yet, create it:
```bash
kubectl run test-pod --image=busybox --labels="role=test" \
  -n netpol-lab -- sleep 3600
```
</details>

---

## Task 4 Hints

<details>
<summary>Hint: What to write in netpol-notes.txt</summary>

Write 3-5 sentences or bullet points explaining WHY network policies matter in production. Consider:
- What happens if a pod is compromised?
- What is "lateral movement" in a security context?
- How do NetworkPolicies relate to the principle of least privilege?

There's no automated content check — just make sure the file is non-empty.
</details>
