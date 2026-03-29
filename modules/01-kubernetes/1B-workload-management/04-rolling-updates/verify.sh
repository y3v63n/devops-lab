#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1B-04"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Exercise 1B-04 — Rolling Updates"; echo ""

# Task 1: Deployment YAML with strategy
echo "Task 1: Deployment with rolling update strategy"
[[ -f "$WORK_DIR/deploy.yaml" ]] \
  && check "deploy.yaml exists" "pass" \
  || check "deploy.yaml exists" "fail"

grep -q "RollingUpdate" "$WORK_DIR/deploy.yaml" 2>/dev/null \
  && check "deploy.yaml specifies RollingUpdate strategy" "pass" \
  || check "deploy.yaml specifies RollingUpdate strategy" "fail"

grep -q "maxSurge" "$WORK_DIR/deploy.yaml" 2>/dev/null \
  && check "deploy.yaml has maxSurge" "pass" \
  || check "deploy.yaml has maxSurge" "fail"

grep -q "maxUnavailable" "$WORK_DIR/deploy.yaml" 2>/dev/null \
  && check "deploy.yaml has maxUnavailable" "pass" \
  || check "deploy.yaml has maxUnavailable" "fail"

kubectl get deployment rolling-demo &>/dev/null \
  && check "rolling-demo deployment exists" "pass" \
  || check "rolling-demo deployment exists" "fail"

echo ""

# Task 2: Rollout log
echo "Task 2: Rolling update log"
[[ -f "$WORK_DIR/rollout-log.txt" ]] \
  && check "rollout-log.txt exists" "pass" \
  || check "rollout-log.txt exists" "fail"

[[ -s "$WORK_DIR/rollout-log.txt" ]] \
  && check "rollout-log.txt has content" "pass" \
  || check "rollout-log.txt has content" "fail"

echo ""

# Task 3: Failed rollout documented
echo "Task 3: Failed rollout captured"
[[ -f "$WORK_DIR/failed-rollout.txt" ]] \
  && check "failed-rollout.txt exists" "pass" \
  || check "failed-rollout.txt exists" "fail"

[[ -s "$WORK_DIR/failed-rollout.txt" ]] \
  && check "failed-rollout.txt has content" "pass" \
  || check "failed-rollout.txt has content" "fail"

echo ""

# Task 4: History and rollback
echo "Task 4: Rollback and history"
[[ -f "$WORK_DIR/history.txt" ]] \
  && check "history.txt exists" "pass" \
  || check "history.txt exists" "fail"

# Check there are multiple revisions
REVISIONS=$(grep -c "^[0-9]" "$WORK_DIR/history.txt" 2>/dev/null || echo 0)
[[ "$REVISIONS" -ge 2 ]] \
  && check "history.txt shows >= 2 revisions (found $REVISIONS)" "pass" \
  || check "history.txt shows >= 2 revisions (found $REVISIONS)" "fail"

# Deployment should be healthy after rollback
READY=$(kubectl get deployment rolling-demo -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
DESIRED=$(kubectl get deployment rolling-demo -o jsonpath='{.spec.replicas}' 2>/dev/null)
[[ "$READY" == "$DESIRED" && -n "$READY" ]] \
  && check "rolling-demo has $READY/$DESIRED pods ready after rollback" "pass" \
  || check "rolling-demo pods ready after rollback ($READY/$DESIRED)" "fail"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
