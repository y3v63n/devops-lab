#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1B-03"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Exercise 1B-03 — Health Checks"; echo ""

# Task 1: Liveness YAML
echo "Task 1: HTTP liveness probe deployment"
[[ -f "$WORK_DIR/liveness.yaml" ]] \
  && check "liveness.yaml exists" "pass" \
  || check "liveness.yaml exists" "fail"

grep -q "livenessProbe" "$WORK_DIR/liveness.yaml" 2>/dev/null \
  && check "liveness.yaml has livenessProbe" "pass" \
  || check "liveness.yaml has livenessProbe" "fail"

grep -q "httpGet" "$WORK_DIR/liveness.yaml" 2>/dev/null \
  && check "liveness.yaml uses httpGet" "pass" \
  || check "liveness.yaml uses httpGet" "fail"

kubectl get deployment liveness-demo &>/dev/null \
  && check "liveness-demo deployment exists" "pass" \
  || check "liveness-demo deployment exists" "fail"

echo ""

# Task 2: Readiness probe
echo "Task 2: Readiness probe — not-ready state"
[[ -f "$WORK_DIR/not-ready.txt" ]] \
  && check "not-ready.txt exists" "pass" \
  || check "not-ready.txt exists" "fail"

[[ -s "$WORK_DIR/not-ready.txt" ]] \
  && check "not-ready.txt has content" "pass" \
  || check "not-ready.txt has content" "fail"

kubectl get deployment readiness-demo &>/dev/null \
  && check "readiness-demo deployment exists" "pass" \
  || check "readiness-demo deployment exists" "fail"

echo ""

# Task 3: Pod became ready
echo "Task 3: Pod transitions to Ready"
READY_PODS=$(kubectl get pods -l app=readiness-demo --no-headers 2>/dev/null | grep -c "1/1")
[[ "$READY_PODS" -ge 1 ]] \
  && check "readiness-demo pod is 1/1 Ready" "pass" \
  || check "readiness-demo pod is 1/1 Ready (found $READY_PODS ready)" "fail"

echo ""

# Task 4: Restart events from failing liveness
echo "Task 4: Failing liveness probe causes restarts"
[[ -f "$WORK_DIR/restart-events.txt" ]] \
  && check "restart-events.txt exists" "pass" \
  || check "restart-events.txt exists" "fail"

RESTARTS=$(kubectl get pods -l app=failing-liveness --no-headers 2>/dev/null | awk '{print $4}' | head -1)
[[ "$RESTARTS" -ge 1 ]] \
  && check "failing-liveness pod has >= 1 restart (got $RESTARTS)" "pass" \
  || check "failing-liveness pod has >= 1 restart (got $RESTARTS)" "fail"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
