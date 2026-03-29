#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1A-03"
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

echo "Verifying: Exercise 1A-03 — Deployments"
echo ""

# Task 1: deployment.yaml
if [[ -f "$WORK_DIR/deployment.yaml" ]] && [[ -s "$WORK_DIR/deployment.yaml" ]]; then
  check "deployment.yaml exists and is non-empty" "pass"
else
  check "deployment.yaml exists and is non-empty" "fail"
fi

if grep -q "kind: Deployment" "$WORK_DIR/deployment.yaml" 2>/dev/null; then
  check "deployment.yaml has kind: Deployment" "pass"
else
  check "deployment.yaml has kind: Deployment" "fail"
fi

if grep -q "nginx:1.24" "$WORK_DIR/deployment.yaml" 2>/dev/null; then
  check "deployment.yaml specifies nginx:1.24 image" "pass"
else
  check "deployment.yaml specifies nginx:1.24 image" "fail"
fi

if grep -qE "replicas:\s*3" "$WORK_DIR/deployment.yaml" 2>/dev/null; then
  check "deployment.yaml has replicas: 3" "pass"
else
  check "deployment.yaml has replicas: 3" "fail"
fi

# Task 2: scaled-pods.txt
if [[ -f "$WORK_DIR/scaled-pods.txt" ]] && [[ -s "$WORK_DIR/scaled-pods.txt" ]]; then
  check "scaled-pods.txt exists and is non-empty" "pass"
else
  check "scaled-pods.txt exists and is non-empty" "fail"
fi

POD_LINE_COUNT=$(grep -c "pod/" "$WORK_DIR/scaled-pods.txt" 2>/dev/null || echo 0)
if [[ "$POD_LINE_COUNT" -ge 5 ]]; then
  check "scaled-pods.txt contains at least 5 pod entries" "pass"
else
  check "scaled-pods.txt contains at least 5 pod entries (found $POD_LINE_COUNT)" "fail"
fi

# Task 3: rollout.txt
if [[ -f "$WORK_DIR/rollout.txt" ]] && [[ -s "$WORK_DIR/rollout.txt" ]]; then
  check "rollout.txt exists and is non-empty" "pass"
else
  check "rollout.txt exists and is non-empty" "fail"
fi

if grep -qi "successfully rolled out\|waiting\|nginx:1.25" "$WORK_DIR/rollout.txt" 2>/dev/null; then
  check "rollout.txt contains rollout progress or success message" "pass"
else
  check "rollout.txt contains rollout progress or success message" "fail"
fi

# Task 4: history.txt
if [[ -f "$WORK_DIR/history.txt" ]] && [[ -s "$WORK_DIR/history.txt" ]]; then
  check "history.txt exists and is non-empty" "pass"
else
  check "history.txt exists and is non-empty" "fail"
fi

if grep -qE "REVISION|[0-9]+" "$WORK_DIR/history.txt" 2>/dev/null; then
  check "history.txt contains rollout revision data" "pass"
else
  check "history.txt contains rollout revision data" "fail"
fi

# Bonus: live cluster checks
echo ""
echo "  [Bonus — requires live cluster]"
if kubectl cluster-info &>/dev/null; then
  DEPLOY_EXISTS=$(kubectl get deployment web-app --no-headers 2>/dev/null | wc -l)
  if [[ "$DEPLOY_EXISTS" -ge 1 ]]; then
    check "Deployment web-app exists in cluster" "pass"
    READY=$(kubectl get deployment web-app -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)
    check "web-app has ready replicas ($READY)" "$([[ ${READY:-0} -ge 1 ]] && echo pass || echo fail)"
  else
    echo "  ~ Deployment web-app not found in cluster"
  fi
else
  echo "  ~ cluster unreachable — skipping live checks"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
