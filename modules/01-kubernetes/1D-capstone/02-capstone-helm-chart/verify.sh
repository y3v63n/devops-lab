#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1D-02"
CHART_DIR="$WORK_DIR/blockchain-monitor"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then
    echo "  ✓ $desc"; PASS=$((PASS+1))
  else
    echo "  ✗ $desc"; FAIL=$((FAIL+1))
  fi
}

echo "Verifying: Exercise 1D-02 — Capstone Helm Chart"
echo ""

# ── Chart scaffold ─────────────────────────────────────────────────────────────
echo "[ Chart structure ]"
check "chart directory exists" \
  "$([[ -d "$CHART_DIR" ]] && echo pass || echo fail)"
check "Chart.yaml exists" \
  "$([[ -f "$CHART_DIR/Chart.yaml" ]] && echo pass || echo fail)"
check "values.yaml exists" \
  "$([[ -f "$CHART_DIR/values.yaml" ]] && echo pass || echo fail)"
check "templates/ directory exists" \
  "$([[ -d "$CHART_DIR/templates" ]] && echo pass || echo fail)"
check "README.md exists" \
  "$([[ -f "$CHART_DIR/README.md" ]] && echo pass || echo fail)"

# ── Chart.yaml content ─────────────────────────────────────────────────────────
echo ""
echo "[ Chart.yaml ]"
if [[ -f "$CHART_DIR/Chart.yaml" ]]; then
  chart_yaml=$(cat "$CHART_DIR/Chart.yaml")
  check "Chart.yaml has name: blockchain-monitor" \
    "$([[ "$chart_yaml" == *"blockchain-monitor"* ]] && echo pass || echo fail)"
  check "Chart.yaml declares prometheus dependency" \
    "$([[ "$chart_yaml" == *"prometheus"* ]] && echo pass || echo fail)"
  check "Chart.yaml declares grafana dependency" \
    "$([[ "$chart_yaml" == *"grafana"* ]] && echo pass || echo fail)"
fi

# ── values.yaml content ────────────────────────────────────────────────────────
echo ""
echo "[ values.yaml ]"
if [[ -f "$CHART_DIR/values.yaml" ]]; then
  vals=$(cat "$CHART_DIR/values.yaml")
  check "values.yaml has replicaCount" \
    "$([[ "$vals" == *"replicaCount"* ]] && echo pass || echo fail)"
  check "values.yaml configures scrape_interval" \
    "$([[ "$vals" == *"scrape_interval"* ]] && echo pass || echo fail)"
  check "values.yaml configures grafana adminPassword" \
    "$([[ "$vals" == *"adminPassword"* ]] && echo pass || echo fail)"
  check "values.yaml has ingress section" \
    "$([[ "$vals" == *"ingress"* ]] && echo pass || echo fail)"
fi

# ── Templates ──────────────────────────────────────────────────────────────────
echo ""
echo "[ Templates ]"
check "health-checker template exists" \
  "$([[ -f "$CHART_DIR/templates/health-checker.yaml" ]] && echo pass || echo fail)"
check "ingress template exists" \
  "$([[ -f "$CHART_DIR/templates/ingress.yaml" ]] && echo pass || echo fail)"

if [[ -f "$CHART_DIR/templates/health-checker.yaml" ]]; then
  hc_tmpl=$(cat "$CHART_DIR/templates/health-checker.yaml")
  check "health-checker template has prometheus scrape annotation" \
    "$([[ "$hc_tmpl" == *"prometheus.io/scrape"* ]] && echo pass || echo fail)"
  check "health-checker template has Deployment kind" \
    "$([[ "$hc_tmpl" == *"kind: Deployment"* ]] && echo pass || echo fail)"
fi

# ── Sub-chart dependencies ─────────────────────────────────────────────────────
echo ""
echo "[ Dependencies ]"
charts_dir_populated=$(ls "$CHART_DIR/charts/" 2>/dev/null | grep -c "." || echo 0)
check "charts/ directory populated (helm dep update ran)" \
  "$([[ "$charts_dir_populated" -gt 0 ]] && echo pass || echo fail)"

# ── helm lint ─────────────────────────────────────────────────────────────────
echo ""
echo "[ Helm lint ]"
lint_output=$(helm lint "$CHART_DIR" 2>&1)
lint_exit=$?
check "helm lint passes (0 errors)" \
  "$([[ $lint_exit -eq 0 ]] && echo pass || echo fail)"
if [[ $lint_exit -ne 0 ]]; then
  echo "    lint output:"
  echo "$lint_output" | sed 's/^/    /'
fi

# ── rendered.yaml ─────────────────────────────────────────────────────────────
echo ""
echo "[ Rendered output ]"
check "rendered.yaml exists" \
  "$([[ -f "$WORK_DIR/rendered.yaml" ]] && echo pass || echo fail)"
if [[ -f "$WORK_DIR/rendered.yaml" ]]; then
  kind_count=$(grep -c "^kind:" "$WORK_DIR/rendered.yaml" 2>/dev/null || echo 0)
  check "rendered.yaml contains multiple resource kinds (>=5)" \
    "$([[ "$kind_count" -ge 5 ]] && echo pass || echo fail)"
  check "rendered.yaml contains an Ingress" \
    "$(grep -q "kind: Ingress" "$WORK_DIR/rendered.yaml" && echo pass || echo fail)"
  check "rendered.yaml contains a Deployment" \
    "$(grep -q "kind: Deployment" "$WORK_DIR/rendered.yaml" && echo pass || echo fail)"
fi

# ── README.md sections ────────────────────────────────────────────────────────
echo ""
echo "[ README.md ]"
if [[ -f "$CHART_DIR/README.md" ]]; then
  readme=$(cat "$CHART_DIR/README.md")
  check "README has Features section" \
    "$([[ "$readme" == *"## Features"* ]] && echo pass || echo fail)"
  check "README has Prerequisites section" \
    "$([[ "$readme" == *"## Prerequisites"* ]] && echo pass || echo fail)"
  check "README has Install section" \
    "$([[ "$readme" == *"## Install"* ]] && echo pass || echo fail)"
  check "README has Customisation/Values section" \
    "$([[ "$readme" == *"## Customis"* || "$readme" == *"## Customize"* || "$readme" == *"## Values"* ]] && echo pass || echo fail)"
  check "README has Skills Demonstrated section" \
    "$([[ "$readme" == *"Skills Demonstrated"* ]] && echo pass || echo fail)"
fi

# ── Helm release (optional — check if chart was actually installed) ────────────
echo ""
echo "[ Helm install (optional) ]"
release=$(helm list -A --filter blockchain-monitor --short 2>/dev/null | head -1)
if [[ -n "$release" ]]; then
  check "blockchain-monitor Helm release exists" "pass"
  release_status=$(helm status blockchain-monitor -n monitoring --output json 2>/dev/null \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['info']['status'])" 2>/dev/null || echo "unknown")
  check "blockchain-monitor release status is deployed" \
    "$([[ "$release_status" == "deployed" ]] && echo pass || echo fail)"
else
  echo "  (skipping install checks — chart not yet installed)"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
