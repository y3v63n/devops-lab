#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1D-01"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then
    echo "  ✓ $desc"; PASS=$((PASS+1))
  else
    echo "  ✗ $desc"; FAIL=$((FAIL+1))
  fi
}

echo "Verifying: Exercise 1D-01 — Capstone Monitoring Stack"
echo ""

# ── Namespace ──────────────────────────────────────────────────────────────────
echo "[ Namespace ]"
ns=$(kubectl get namespace monitoring --no-headers 2>/dev/null | awk '{print $2}')
check "monitoring namespace exists and is Active" \
  "$([[ "$ns" == "Active" ]] && echo pass || echo fail)"

# ── Files ──────────────────────────────────────────────────────────────────────
echo ""
echo "[ Work-dir files ]"
check "prometheus-values.yaml exists" \
  "$([[ -f "$WORK_DIR/prometheus-values.yaml" ]] && echo pass || echo fail)"
check "grafana-values.yaml exists" \
  "$([[ -f "$WORK_DIR/grafana-values.yaml" ]] && echo pass || echo fail)"
check "health-checker.yaml exists" \
  "$([[ -f "$WORK_DIR/health-checker.yaml" ]] && echo pass || echo fail)"
check "grafana-url.txt exists" \
  "$([[ -f "$WORK_DIR/grafana-url.txt" ]] && echo pass || echo fail)"

# ── Values file content ────────────────────────────────────────────────────────
if [[ -f "$WORK_DIR/prometheus-values.yaml" ]]; then
  prom_vals=$(cat "$WORK_DIR/prometheus-values.yaml")
  check "prometheus values: retention set" \
    "$([[ "$prom_vals" == *"retention"* ]] && echo pass || echo fail)"
  check "prometheus values: scrape_interval set" \
    "$([[ "$prom_vals" == *"scrape_interval"* ]] && echo pass || echo fail)"
fi

if [[ -f "$WORK_DIR/grafana-values.yaml" ]]; then
  graf_vals=$(cat "$WORK_DIR/grafana-values.yaml")
  check "grafana values: adminPassword set to devops-lab" \
    "$([[ "$graf_vals" == *"devops-lab"* ]] && echo pass || echo fail)"
fi

# ── Helm releases ──────────────────────────────────────────────────────────────
echo ""
echo "[ Helm releases ]"
prom_release=$(helm list -n monitoring --filter prometheus --short 2>/dev/null | head -1)
check "prometheus Helm release exists in monitoring namespace" \
  "$([[ -n "$prom_release" ]] && echo pass || echo fail)"

graf_release=$(helm list -n monitoring --filter grafana --short 2>/dev/null | head -1)
check "grafana Helm release exists in monitoring namespace" \
  "$([[ -n "$graf_release" ]] && echo pass || echo fail)"

# ── Pod health ─────────────────────────────────────────────────────────────────
echo ""
echo "[ Pod health ]"

prom_ready=$(kubectl get pods -n monitoring -l "app.kubernetes.io/name=prometheus,app.kubernetes.io/component=server" \
  --no-headers 2>/dev/null | awk '{print $2}' | grep -c "^[1-9]" || echo 0)
check "prometheus-server pod is ready" \
  "$([[ "$prom_ready" -gt 0 ]] && echo pass || echo fail)"

graf_ready=$(kubectl get pods -n monitoring -l "app.kubernetes.io/name=grafana" \
  --no-headers 2>/dev/null | awk '{print $2}' | grep -c "^[1-9]" || echo 0)
check "grafana pod is ready" \
  "$([[ "$graf_ready" -gt 0 ]] && echo pass || echo fail)"

hc_ready=$(kubectl get pods -n monitoring -l "app=health-checker" \
  --no-headers 2>/dev/null | awk '{print $2}' | grep -c "^[1-9]" || echo 0)
check "health-checker pod is ready" \
  "$([[ "$hc_ready" -gt 0 ]] && echo pass || echo fail)"

# ── health-checker manifest content ────────────────────────────────────────────
if [[ -f "$WORK_DIR/health-checker.yaml" ]]; then
  hc_yaml=$(cat "$WORK_DIR/health-checker.yaml")
  check "health-checker YAML has prometheus scrape annotation" \
    "$([[ "$hc_yaml" == *"prometheus.io/scrape"* ]] && echo pass || echo fail)"
  check "health-checker YAML has /metrics path" \
    "$([[ "$hc_yaml" == *"/metrics"* ]] && echo pass || echo fail)"
fi

# ── Grafana port-forward (best-effort) ────────────────────────────────────────
echo ""
echo "[ Grafana access ]"
graf_http=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 \
  http://localhost:3000/api/health 2>/dev/null || echo "000")
check "Grafana responds on localhost:3000 (port-forward active)" \
  "$([[ "$graf_http" == "200" ]] && echo pass || echo fail)"

if [[ "$graf_http" == "200" ]]; then
  ds_count=$(curl -s -u admin:devops-lab --max-time 5 \
    http://localhost:3000/api/datasources 2>/dev/null \
    | python3 -c "import sys,json; ds=json.load(sys.stdin); print(len(ds))" 2>/dev/null || echo 0)
  check "Prometheus datasource configured in Grafana" \
    "$([[ "$ds_count" -gt 0 ]] && echo pass || echo fail)"
fi

# ── grafana-url.txt content ────────────────────────────────────────────────────
if [[ -f "$WORK_DIR/grafana-url.txt" ]]; then
  url_content=$(cat "$WORK_DIR/grafana-url.txt")
  check "grafana-url.txt contains localhost:3000" \
    "$([[ "$url_content" == *"3000"* ]] && echo pass || echo fail)"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
