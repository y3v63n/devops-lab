#!/usr/bin/env bash
echo "Resetting Exercise 1B-06 — Debugging..."

# Delete everything from previous runs
kubectl delete deployment broken-image broken-probe broken-selector --ignore-not-found=true
kubectl delete service broken-image-svc broken-probe-svc broken-selector-svc --ignore-not-found=true
echo "  Deleted previous deployments and services"

# Clean up work directory
rm -rf /tmp/devops-lab/1B-06
mkdir -p /tmp/devops-lab/1B-06
echo "  Cleaned /tmp/devops-lab/1B-06"

echo ""
echo "Creating broken deployments..."

# ── Broken 1: ImagePullBackOff ──────────────────────────────────────────────
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broken-image
spec:
  replicas: 2
  selector:
    matchLabels:
      app: broken-image
  template:
    metadata:
      labels:
        app: broken-image
    spec:
      containers:
      - name: nginx
        image: nginx:99.99.99
        ports:
        - containerPort: 80
EOF
echo "  Created broken-image (ImagePullBackOff)"

# ── Service for broken-image ────────────────────────────────────────────────
kubectl expose deployment broken-image --name=broken-image-svc --port=80 --target-port=80
echo "  Created broken-image-svc"

# ── Broken 2: Bad liveness probe port ──────────────────────────────────────
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broken-probe
spec:
  replicas: 1
  selector:
    matchLabels:
      app: broken-probe
  template:
    metadata:
      labels:
        app: broken-probe
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 9999
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 2
EOF
echo "  Created broken-probe (liveness on wrong port 9999)"

# ── Service for broken-probe ────────────────────────────────────────────────
kubectl expose deployment broken-probe --name=broken-probe-svc --port=80 --target-port=80
echo "  Created broken-probe-svc"

# ── Broken 3: Service selector mismatch ────────────────────────────────────
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broken-selector
spec:
  replicas: 2
  selector:
    matchLabels:
      app: broken-selector
  template:
    metadata:
      labels:
        app: broken-selector
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
EOF
echo "  Created broken-selector deployment (correct labels: app=broken-selector)"

# Service with WRONG selector
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: broken-selector-svc
spec:
  selector:
    label: wrong
  ports:
  - port: 80
    targetPort: 80
EOF
echo "  Created broken-selector-svc (WRONG selector: label=wrong)"

echo ""
echo "Setup complete. Three broken deployments are ready:"
echo "  1. broken-image     → ImagePullBackOff (nginx:99.99.99)"
echo "  2. broken-probe     → CrashLoopBackOff (liveness on port 9999)"
echo "  3. broken-selector  → Deployment healthy but service has no endpoints"
echo ""
echo "Now read lesson.md and start debugging!"
