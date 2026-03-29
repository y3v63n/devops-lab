# Hints — Exercise 1C-02: Creating a Helm Chart

## Task 1 Hints

<details>
<summary>Hint 1: helm create must be run in the right directory</summary>

```bash
mkdir -p /tmp/devops-lab/1C-02
cd /tmp/devops-lab/1C-02
helm create node-monitor
```
This creates `/tmp/devops-lab/1C-02/node-monitor/` with all scaffold files.
</details>

---

## Task 2 Hints

<details>
<summary>Hint 1: Where is values.yaml?</summary>

```
/tmp/devops-lab/1C-02/node-monitor/values.yaml
```
Open it in your editor. You'll see pre-populated defaults — you just need to modify the relevant sections.
</details>

<details>
<summary>Hint 2: Setting the image to nginx:alpine</summary>

Find the `image:` block and set:
```yaml
image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "alpine"
```
</details>

<details>
<summary>Hint 3: Adding env vars</summary>

Add a top-level `env` key in values.yaml:
```yaml
env:
  - name: APP_ENV
    value: "production"
  - name: LOG_LEVEL
    value: "info"
```
Note: the default scaffold doesn't wire `env` into the deployment template. That's OK for this exercise — we're verifying values.yaml content, not that the env vars appear in pods.
</details>

---

## Task 3 Hints

<details>
<summary>Hint 1: helm template command</summary>

```bash
helm template my-node-monitor /tmp/devops-lab/1C-02/node-monitor \
  > /tmp/devops-lab/1C-02/rendered.yaml
```
The first argument is the release name (used for `.Release.Name` in templates), the second is the chart path.
</details>

<details>
<summary>Hint 2: helm lint shows errors</summary>

If `helm lint` fails, read the output carefully. Common issues:
- Indentation errors in values.yaml (YAML is indent-sensitive)
- Missing required fields in Chart.yaml

Run with verbose output: `helm lint /tmp/devops-lab/1C-02/node-monitor --debug`
</details>

---

## Task 4 Hints

<details>
<summary>Hint 1: Installing a local chart</summary>

```bash
helm install my-node-monitor /tmp/devops-lab/1C-02/node-monitor
```
Use the directory path, not a repo reference. Helm treats it identically.
</details>

<details>
<summary>Hint 2: Pods are pending or crashing</summary>

This is OK for the exercise — we're verifying Helm's install succeeded, not that nginx is fully running. Check with:
```bash
helm list
kubectl get pods
```
</details>

---

## Verify Troubleshooting

<details>
<summary>verify.sh says "replicaCount is not 2"</summary>

The Python check reads values.yaml and checks that `replicaCount` equals the integer `2`, not the string `"2"`. Make sure your values.yaml has:
```yaml
replicaCount: 2
```
(no quotes around the number)
</details>
