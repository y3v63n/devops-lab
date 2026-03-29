#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1B-06"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Exercise 1B-06 — Debugging"; echo ""

# Task 1: broken-image fixed
echo "Task 1: broken-image deployment fixed"
[[ -f "$WORK_DIR/issue1.txt" ]] \
  && check "issue1.txt (diagnosis) exists" "pass" \
  || check "issue1.txt (diagnosis) exists" "fail"

grep -qi "imagepull\|errimagepull\|not found\|manifest\|99.99" "$WORK_DIR/issue1.txt" 2>/dev/null \
  && check "issue1.txt describes the image pull error" "pass" \
  || check "issue1.txt describes the image pull error" "fail"

READY=$(kubectl get deployment broken-image -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
DESIRED=$(kubectl get deployment broken-image -o jsonpath='{.spec.replicas}' 2>/dev/null)
[[ -n "$READY" && "$READY" == "$DESIRED" ]] \
  && check "broken-image deployment is healthy ($READY/$DESIRED)" "pass" \
  || check "broken-image deployment is healthy ($READY/$DESIRED — not fixed yet)" "fail"

echo ""

# Task 2: broken-probe fixed
echo "Task 2: broken-probe deployment fixed"
[[ -f "$WORK_DIR/issue2.txt" ]] \
  && check "issue2.txt (diagnosis) exists" "pass" \
  || check "issue2.txt (diagnosis) exists" "fail"

grep -qi "liveness\|probe\|9999\|restart\|kill" "$WORK_DIR/issue2.txt" 2>/dev/null \
  && check "issue2.txt describes the probe failure" "pass" \
  || check "issue2.txt describes the probe failure" "fail"

READY=$(kubectl get deployment broken-probe -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
DESIRED=$(kubectl get deployment broken-probe -o jsonpath='{.spec.replicas}' 2>/dev/null)
[[ -n "$READY" && "$READY" == "$DESIRED" ]] \
  && check "broken-probe deployment is healthy ($READY/$DESIRED)" "pass" \
  || check "broken-probe deployment is healthy ($READY/$DESIRED — not fixed yet)" "fail"

echo ""

# Task 3: broken-selector fixed
echo "Task 3: broken-selector service fixed"
[[ -f "$WORK_DIR/issue3.txt" ]] \
  && check "issue3.txt (diagnosis) exists" "pass" \
  || check "issue3.txt (diagnosis) exists" "fail"

grep -qi "selector\|endpoint\|no endpoints\|label\|wrong" "$WORK_DIR/issue3.txt" 2>/dev/null \
  && check "issue3.txt describes the selector mismatch" "pass" \
  || check "issue3.txt describes the selector mismatch" "fail"

ENDPOINTS=$(kubectl get endpoints broken-selector-svc -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
[[ -n "$ENDPOINTS" ]] \
  && check "broken-selector-svc now has endpoints" "pass" \
  || check "broken-selector-svc still has no endpoints — selector not fixed" "fail"

echo ""

# Task 4: Connectivity
echo "Task 4: Service connectivity verified"
[[ -f "$WORK_DIR/connectivity.txt" ]] \
  && check "connectivity.txt exists" "pass" \
  || check "connectivity.txt exists" "fail"

[[ -s "$WORK_DIR/connectivity.txt" ]] \
  && check "connectivity.txt has content" "pass" \
  || check "connectivity.txt has content" "fail"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
