#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1C-02"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Exercise 1C-02 — Helm Create Chart"; echo ""

# Task 1: Chart directory structure exists
[[ -d "$WORK_DIR/node-monitor" ]] && r="pass" || r="fail"
check "node-monitor chart directory exists" "$r"

[[ -f "$WORK_DIR/node-monitor/Chart.yaml" ]] && r="pass" || r="fail"
check "Chart.yaml exists" "$r"

[[ -f "$WORK_DIR/node-monitor/values.yaml" ]] && r="pass" || r="fail"
check "values.yaml exists" "$r"

[[ -d "$WORK_DIR/node-monitor/templates" ]] && r="pass" || r="fail"
check "templates/ directory exists" "$r"

# Task 2: values.yaml customizations
grep -q "alpine" "$WORK_DIR/node-monitor/values.yaml" 2>/dev/null && r="pass" || r="fail"
check "values.yaml uses alpine image tag" "$r"

grep -q "replicaCount" "$WORK_DIR/node-monitor/values.yaml" 2>/dev/null && r="pass" || r="fail"
check "values.yaml has replicaCount" "$r"

python3 -c "
import sys
try:
    import yaml
    with open('$WORK_DIR/node-monitor/values.yaml') as f:
        v = yaml.safe_load(f)
    rc = v.get('replicaCount', 0)
    sys.exit(0 if rc == 2 else 1)
except Exception:
    sys.exit(1)
" 2>/dev/null && r="pass" || r="fail"
check "values.yaml replicaCount is 2" "$r"

grep -q "env" "$WORK_DIR/node-monitor/values.yaml" 2>/dev/null && r="pass" || r="fail"
check "values.yaml has env section" "$r"

# Task 3: rendered.yaml exists and has Kubernetes resources
[[ -f "$WORK_DIR/rendered.yaml" ]] && r="pass" || r="fail"
check "rendered.yaml exists" "$r"

[[ -s "$WORK_DIR/rendered.yaml" ]] && r="pass" || r="fail"
check "rendered.yaml has content" "$r"

grep -q "kind:" "$WORK_DIR/rendered.yaml" 2>/dev/null && r="pass" || r="fail"
check "rendered.yaml contains Kubernetes resources" "$r"

# Task 3: helm lint passes
helm lint "$WORK_DIR/node-monitor" --quiet 2>/dev/null && r="pass" || r="fail"
check "helm lint passes with no errors" "$r"

# Task 4: Release installed
helm list --short 2>/dev/null | grep -q "my-node-monitor" && r="pass" || r="fail"
check "my-node-monitor release is installed" "$r"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
