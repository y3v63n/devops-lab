#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1C-03"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Exercise 1C-03 — Ingress"; echo ""

# Task 1: Deployments exist
kubectl get deployment app-v1 &>/dev/null && r="pass" || r="fail"
check "app-v1 deployment exists" "$r"

kubectl get deployment app-v2 &>/dev/null && r="pass" || r="fail"
check "app-v2 deployment exists" "$r"

# Task 2: Services exist
kubectl get service app-v1 &>/dev/null && r="pass" || r="fail"
check "app-v1 service exists" "$r"

kubectl get service app-v2 &>/dev/null && r="pass" || r="fail"
check "app-v2 service exists" "$r"

# Task 3: ingress.yaml exists and has valid content
[[ -f "$WORK_DIR/ingress.yaml" ]] && r="pass" || r="fail"
check "ingress.yaml file exists" "$r"

grep -q "kind: Ingress" "$WORK_DIR/ingress.yaml" 2>/dev/null && r="pass" || r="fail"
check "ingress.yaml contains Ingress resource" "$r"

grep -q "/v1" "$WORK_DIR/ingress.yaml" 2>/dev/null && r="pass" || r="fail"
check "ingress.yaml has /v1 path rule" "$r"

grep -q "/v2" "$WORK_DIR/ingress.yaml" 2>/dev/null && r="pass" || r="fail"
check "ingress.yaml has /v2 path rule" "$r"

# Ingress exists in cluster
kubectl get ingress app-ingress &>/dev/null && r="pass" || r="fail"
check "app-ingress resource exists in cluster" "$r"

# Task 4: routing-test.txt exists and has content
[[ -f "$WORK_DIR/routing-test.txt" ]] && r="pass" || r="fail"
check "routing-test.txt exists" "$r"

[[ -s "$WORK_DIR/routing-test.txt" ]] && r="pass" || r="fail"
check "routing-test.txt has content" "$r"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
