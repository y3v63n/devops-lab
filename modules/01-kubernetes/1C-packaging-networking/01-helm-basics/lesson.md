# Exercise 1C-01: Helm Basics

## Theory

Helm is the package manager for Kubernetes. It simplifies deploying and managing applications by bundling Kubernetes manifests into reusable packages called **charts**.

### Core Concepts

**Chart** — A collection of files that describe a related set of Kubernetes resources. Think of it like an apt/yum package for Kubernetes.

**Release** — A running instance of a chart. You can install the same chart multiple times, each creates a separate release with a unique name.

**Repository** — A place where charts are stored and shared. Like a package registry (npm, PyPI) for Helm charts.

**Values** — Configuration parameters that customize a chart installation. Defined in `values.yaml` and overridable at install time.

### How Helm Works

```
Chart (template) + Values → Kubernetes manifests → kubectl apply
```

Helm renders Go templates in the chart using your values, then communicates with the Kubernetes API server to create/update resources.

### Key Commands

```bash
helm repo add <name> <url>       # Add a chart repository
helm repo update                 # Fetch latest chart metadata
helm search repo <keyword>       # Search for charts
helm install <release> <chart>   # Install a chart
helm upgrade <release> <chart>   # Upgrade a running release
helm uninstall <release>         # Remove a release
helm list                        # Show installed releases
helm history <release>           # Show release history
helm rollback <release> <rev>    # Roll back to a previous revision
```

---

## Tasks

### Setup
```bash
mkdir -p /tmp/devops-lab/1C-01
```

### Task 1 — Add Bitnami repo and search for nginx

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm search repo nginx > /tmp/devops-lab/1C-01/search-results.txt
cat /tmp/devops-lab/1C-01/search-results.txt
```

### Task 2 — Install bitnami/nginx as my-nginx

```bash
helm install my-nginx bitnami/nginx
helm list > /tmp/devops-lab/1C-01/releases.txt
cat /tmp/devops-lab/1C-01/releases.txt
```

### Task 3 — Customize with values override

```bash
cat > /tmp/devops-lab/1C-01/custom-values.yaml <<EOF
service:
  type: NodePort
replicaCount: 2
EOF

helm upgrade my-nginx bitnami/nginx \
  --set service.type=NodePort \
  --set replicaCount=2
```

### Task 4 — Record history then uninstall

```bash
helm history my-nginx > /tmp/devops-lab/1C-01/helm-history.txt
cat /tmp/devops-lab/1C-01/helm-history.txt
helm uninstall my-nginx
```

---

## What Just Happened

1. You added an external chart repository (Bitnami) — a curated library of production-ready charts.
2. Helm fetched the chart index so you can search and install from it.
3. `helm install` rendered the chart templates with default values and applied them to your cluster — creating a Deployment, Service, and other resources in one shot.
4. `helm upgrade` let you change configuration without touching any YAML directly — Helm computed the diff and applied only what changed.
5. `helm history` shows every revision: install, upgrades, rollbacks. This is Helm's release ledger.
6. `helm uninstall` cleanly removed all resources that belonged to the release.

---

## Interview Questions

**Q: "What is the difference between `helm install` and `kubectl apply`?"**

`kubectl apply` is a low-level tool — you manage raw YAML manifests yourself, handle ordering, templating, and upgrades manually. It has no concept of a "release" or revision history.

`helm install` is higher-level: it packages many manifests into a versioned unit (a release), supports templating with values, tracks revision history (enabling rollbacks), and manages the full lifecycle (install → upgrade → rollback → uninstall) as a single atomic operation. Helm is opinionated about application lifecycle; kubectl apply is a primitive building block.

In production, teams often use Helm for third-party software (databases, ingress controllers) and kubectl/Kustomize for their own apps.
