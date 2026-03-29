# Exercise 1C-02: Creating a Helm Chart

## Theory

### Chart Structure

When you run `helm create myapp`, Helm scaffolds this directory layout:

```
myapp/
├── Chart.yaml          # Chart metadata (name, version, description)
├── values.yaml         # Default configuration values
├── charts/             # Dependencies (sub-charts)
└── templates/          # Kubernetes manifest templates
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── _helpers.tpl    # Named template partials (reusable snippets)
    ├── hpa.yaml
    ├── serviceaccount.yaml
    └── NOTES.txt       # Post-install usage notes shown to user
```

### Go Templating in Helm

Helm uses Go's `text/template` package extended with the Sprig function library.

**Key objects available in templates:**

| Object | Description |
|--------|-------------|
| `.Values` | Values from values.yaml and --set flags |
| `.Release.Name` | The name given at helm install |
| `.Release.Namespace` | The namespace being deployed to |
| `.Chart.Name` | The chart name from Chart.yaml |
| `.Chart.Version` | The chart version |

**Common patterns:**

```yaml
# Access a value
image: {{ .Values.image.repository }}:{{ .Values.image.tag }}

# Conditional block
{{- if .Values.ingress.enabled }}
# ingress yaml here
{{- end }}

# Named template (defined in _helpers.tpl)
{{- include "myapp.fullname" . | indent 4 }}

# Default value
replicas: {{ .Values.replicaCount | default 1 }}

# Range over a list
{{- range .Values.env }}
- name: {{ .name }}
  value: {{ .value | quote }}
{{- end }}
```

### Useful Commands

```bash
helm create <name>              # Scaffold a new chart
helm template <release> <chart> # Render templates without installing
helm lint <chart>               # Check chart for errors
helm install --dry-run          # Simulate install, show what would be applied
helm package <chart>            # Package chart into a .tgz archive
```

---

## Tasks

### Setup
```bash
mkdir -p /tmp/devops-lab/1C-02
```

### Task 1 — Create the chart scaffold

```bash
cd /tmp/devops-lab/1C-02
helm create node-monitor
ls node-monitor/
```

### Task 2 — Customize values.yaml

Edit `/tmp/devops-lab/1C-02/node-monitor/values.yaml` to set:
- Image: `nginx:alpine` (repository: `nginx`, tag: `alpine`)
- Replica count: `2`
- Add environment variables under a custom `env` key:

```yaml
image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "alpine"

replicaCount: 2

env:
  - name: APP_ENV
    value: "production"
  - name: LOG_LEVEL
    value: "info"
```

### Task 3 — Render and lint

```bash
helm template my-node-monitor /tmp/devops-lab/1C-02/node-monitor \
  > /tmp/devops-lab/1C-02/rendered.yaml

helm lint /tmp/devops-lab/1C-02/node-monitor
```

Review the rendered output — you'll see actual Kubernetes YAML, not templates.

### Task 4 — Install on minikube

```bash
helm install my-node-monitor /tmp/devops-lab/1C-02/node-monitor
kubectl get pods
kubectl get svc
```

---

## What Just Happened

1. `helm create` generated a production-grade chart scaffold with best practices baked in: resource limits placeholders, liveness probes, service account support, and an HPA stub.
2. You modified `values.yaml` — this is the contract between chart developers and operators. Operators customize values; they never touch the templates.
3. `helm template` rendered the Go templates to pure Kubernetes YAML. This is invaluable for debugging and for GitOps workflows where you want to see exactly what will be applied.
4. `helm lint` caught any structural errors before they hit the cluster — like a syntax checker for charts.
5. Installing a local chart works identically to installing from a repo — the `chart/` directory is a valid chart source.

---

## Interview Questions

**Q: "Explain Go templating in Helm — specifically .Values, .Release, and include."**

`.Values` is a map built from `values.yaml` merged with `--set` and `-f` overrides. It's how you parameterize templates.

`.Release` is an object injected by Helm containing metadata about the current release: `.Release.Name` (the release identifier), `.Release.Namespace`, `.Release.IsInstall`, `.Release.IsUpgrade`, etc. This lets templates behave differently on first install vs upgrade.

`include` is a function that renders a named template (defined in `_helpers.tpl` with `{{- define "name" }}`) and returns its output as a string. Unlike `template`, `include` can be piped to other functions:
```yaml
labels:
  {{- include "myapp.labels" . | nindent 4 }}
```
`nindent 4` adds 4 spaces of indentation with a leading newline — essential for proper YAML structure.
