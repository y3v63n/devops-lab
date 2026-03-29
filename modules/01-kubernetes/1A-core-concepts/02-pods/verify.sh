#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1A-02"
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

echo "Verifying: Exercise 1A-02 — Pods"
echo ""

# Task 1: pod.yaml
if [[ -f "$WORK_DIR/pod.yaml" ]] && [[ -s "$WORK_DIR/pod.yaml" ]]; then
  check "pod.yaml exists and is non-empty" "pass"
else
  check "pod.yaml exists and is non-empty" "fail"
fi

if grep -q "nginx:alpine" "$WORK_DIR/pod.yaml" 2>/dev/null; then
  check "pod.yaml references nginx:alpine image" "pass"
else
  check "pod.yaml references nginx:alpine image" "fail"
fi

if grep -q "lab-nginx" "$WORK_DIR/pod.yaml" 2>/dev/null; then
  check "pod.yaml contains pod name 'lab-nginx'" "pass"
else
  check "pod.yaml contains pod name 'lab-nginx'" "fail"
fi

if grep -q "kind: Pod" "$WORK_DIR/pod.yaml" 2>/dev/null; then
  check "pod.yaml has correct kind: Pod" "pass"
else
  check "pod.yaml has correct kind: Pod" "fail"
fi

# Task 3: response.txt
if [[ -f "$WORK_DIR/response.txt" ]] && [[ -s "$WORK_DIR/response.txt" ]]; then
  check "response.txt exists and is non-empty" "pass"
else
  check "response.txt exists and is non-empty" "fail"
fi

if grep -q "Hello K8s" "$WORK_DIR/response.txt" 2>/dev/null; then
  check "response.txt contains 'Hello K8s'" "pass"
else
  check "response.txt contains 'Hello K8s'" "fail"
fi

# Task 4: pod-logs.txt
if [[ -f "$WORK_DIR/pod-logs.txt" ]] && [[ -s "$WORK_DIR/pod-logs.txt" ]]; then
  check "pod-logs.txt exists and is non-empty" "pass"
else
  check "pod-logs.txt exists and is non-empty" "fail"
fi

# Bonus: live cluster checks
echo ""
echo "  [Bonus — requires live cluster]"
if kubectl cluster-info &>/dev/null; then
  POD_STATUS=$(kubectl get pod lab-nginx --no-headers 2>/dev/null | awk '{print $3}' || echo "")
  if [[ "$POD_STATUS" == "Running" ]]; then
    check "Pod lab-nginx is currently Running" "pass"
  elif [[ -z "$POD_STATUS" ]]; then
    echo "  ~ lab-nginx not found (may have been deleted — that's expected for Task 4)"
  else
    check "Pod lab-nginx status: $POD_STATUS" "fail"
  fi
else
  echo "  ~ cluster unreachable — skipping live checks"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
