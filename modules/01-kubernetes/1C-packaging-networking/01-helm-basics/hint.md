# Hints — Exercise 1C-01: Helm Basics

## Task 1 Hints

<details>
<summary>Hint 1: Adding the repo</summary>

The exact command is:
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```
If you get an error about the repo already existing, that's fine — it means it was already added.
</details>

<details>
<summary>Hint 2: Redirecting search output</summary>

Use `>` to redirect stdout to a file:
```bash
helm search repo nginx > /tmp/devops-lab/1C-01/search-results.txt
```
Make sure the directory exists first: `mkdir -p /tmp/devops-lab/1C-01`
</details>

---

## Task 2 Hints

<details>
<summary>Hint 1: helm install syntax</summary>

```bash
helm install <release-name> <chart-name>
# Example:
helm install my-nginx bitnami/nginx
```
The release name (`my-nginx`) is how you refer to this installation going forward.
</details>

<details>
<summary>Hint 2: Capturing helm list output</summary>

```bash
helm list > /tmp/devops-lab/1C-01/releases.txt
```
</details>

---

## Task 3 Hints

<details>
<summary>Hint 1: --set vs values file</summary>

`--set key=value` overrides individual values inline. For the custom-values.yaml file, you can write it manually and also use `--set` flags on upgrade — they are not mutually exclusive. The task just wants the YAML file to exist with NodePort and replicaCount defined.
</details>

<details>
<summary>Hint 2: Writing the YAML file</summary>

```yaml
# /tmp/devops-lab/1C-01/custom-values.yaml
service:
  type: NodePort
replicaCount: 2
```
</details>

---

## Task 4 Hints

<details>
<summary>Hint 1: helm history</summary>

```bash
helm history my-nginx > /tmp/devops-lab/1C-01/helm-history.txt
```
Run this BEFORE `helm uninstall` — history is deleted when a release is removed (by default).
</details>

<details>
<summary>Hint 2: Order of operations</summary>

Do it in this order:
1. `helm upgrade my-nginx bitnami/nginx --set service.type=NodePort --set replicaCount=2`
2. `helm history my-nginx > /tmp/devops-lab/1C-01/helm-history.txt`
3. `helm uninstall my-nginx`
</details>

---

## Verify Troubleshooting

<details>
<summary>verify.sh says "search-results.txt has no content"</summary>

The file exists but is empty. This usually means the redirect failed or `helm search repo` returned nothing. Try:
```bash
helm repo update
helm search repo nginx
```
If no results, check internet connectivity and whether the bitnami repo was added: `helm repo list`
</details>
