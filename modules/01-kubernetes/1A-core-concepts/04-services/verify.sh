#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1A-04"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then
    echo "  ✓ $desc"
    PASS=$((PASS+1))
  else
    echo "  ✗ $desc"
    FAIL=$((FAIL+1))
  fi
}

echo "Verifying: Exercise 1A-04 — Services"
echo ""

# Task 2: nodeport-url.txt
if [[ -f "$WORK_DIR/nodeport-url.txt" ]] && [[ -s "$WORK_DIR/nodeport-url.txt" ]]; then
  check "nodeport-url.txt exists and is non-empty" "pass"
else
  check "nodeport-url.txt exists and is non-empty" "fail"
fi

if grep -qiE "NodePort URL|http://" "$WORK_DIR/nodeport-url.txt" 2>/dev/null; then
  check "nodeport-url.txt contains a URL" "pass"
else
  check "nodeport-url.txt contains a URL" "fail"
fi

if grep -qE ":[3-9][0-9]{4}" "$WORK_DIR/nodeport-url.txt" 2>/dev/null; then
  check "nodeport-url.txt contains a port in NodePort range (30000-39999)" "pass"
else
  check "nodeport-url.txt contains a port in NodePort range (30000-39999)" "fail"
fi

# Task 3: internal-access.txt
if [[ -f "$WORK_DIR/internal-access.txt" ]] && [[ -s "$WORK_DIR/internal-access.txt" ]]; then
  check "internal-access.txt exists and is non-empty" "pass"
else
  check "internal-access.txt exists and is non-empty" "fail"
fi

if grep -qiE "nginx|html|welcome" "$WORK_DIR/internal-access.txt" 2>/dev/null; then
  check "internal-access.txt contains nginx response" "pass"
else
  check "internal-access.txt contains nginx response" "fail"
fi

# Task 4: service-types.txt
if [[ -f "$WORK_DIR/service-types.txt" ]] && [[ -s "$WORK_DIR/service-types.txt" ]]; then
  check "service-types.txt exists and is non-empty" "pass"
else
  check "service-types.txt exists and is non-empty" "fail"
fi

SVCTYPE_WORDS=$(wc -w < "$WORK_DIR/service-types.txt" 2>/dev/null || echo 0)
if [[ "$SVCTYPE_WORDS" -ge 40 ]]; then
  check "service-types.txt has at least 40 words" "pass"
else
  check "service-types.txt has at least 40 words" "fail"
fi

for svctype in ClusterIP NodePort LoadBalancer; do
  if grep -q "$svctype" "$WORK_DIR/service-types.txt" 2>/dev/null; then
    check "service-types.txt mentions $svctype" "pass"
  else
    check "service-types.txt mentions $svctype" "fail"
  fi
done

# Bonus: live cluster checks
echo ""
echo "  [Bonus — requires live cluster]"
if kubectl cluster-info &>/dev/null; then
  if kubectl get svc backend-svc &>/dev/null 2>&1; then
    check "Service backend-svc exists" "pass"
    SVC_TYPE=$(kubectl get svc backend-svc -o jsonpath='{.spec.type}' 2>/dev/null)
    check "backend-svc is ClusterIP type (got: $SVC_TYPE)" "$([[ "$SVC_TYPE" == "ClusterIP" ]] && echo pass || echo fail)"
  else
    echo "  ~ Service backend-svc not found in cluster"
  fi
  if kubectl get svc backend-nodeport &>/dev/null 2>&1; then
    check "Service backend-nodeport exists" "pass"
  else
    echo "  ~ Service backend-nodeport not found"
  fi
else
  echo "  ~ cluster unreachable — skipping live checks"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
