#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1B-02"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Exercise 1B-02 — Resource Limits"; echo ""

# Task 1: Resource pod
echo "Task 1: Resource pod with requests/limits"
[[ -f "$WORK_DIR/resource-pod.yaml" ]] \
  && check "resource-pod.yaml exists" "pass" \
  || check "resource-pod.yaml exists" "fail"

grep -q "requests" "$WORK_DIR/resource-pod.yaml" 2>/dev/null \
  && check "resource-pod.yaml contains 'requests'" "pass" \
  || check "resource-pod.yaml contains 'requests'" "fail"

grep -q "limits" "$WORK_DIR/resource-pod.yaml" 2>/dev/null \
  && check "resource-pod.yaml contains 'limits'" "pass" \
  || check "resource-pod.yaml contains 'limits'" "fail"

grep -q "100m" "$WORK_DIR/resource-pod.yaml" 2>/dev/null \
  && check "resource-pod.yaml has cpu request 100m" "pass" \
  || check "resource-pod.yaml has cpu request 100m" "fail"

POD_STATUS=$(kubectl get pod resource-demo --no-headers 2>/dev/null | awk '{print $3}')
[[ "$POD_STATUS" == "Running" ]] \
  && check "resource-demo pod is Running" "pass" \
  || check "resource-demo pod is Running (status: $POD_STATUS)" "fail"

echo ""

# Task 2: Pending pod
echo "Task 2: Impossible memory request → Pending"
PENDING_STATUS=$(kubectl get pod memory-hog --no-headers 2>/dev/null | awk '{print $3}')
[[ "$PENDING_STATUS" == "Pending" ]] \
  && check "memory-hog pod is Pending" "pass" \
  || check "memory-hog pod is Pending (status: $PENDING_STATUS)" "fail"

[[ -f "$WORK_DIR/pending-reason.txt" ]] \
  && check "pending-reason.txt exists" "pass" \
  || check "pending-reason.txt exists" "fail"

grep -qi "insufficient\|memory\|unschedulable" "$WORK_DIR/pending-reason.txt" 2>/dev/null \
  && check "pending-reason.txt mentions memory constraint" "pass" \
  || check "pending-reason.txt mentions memory constraint" "fail"

echo ""

# Task 3: Metrics file
echo "Task 3: Metrics capture"
[[ -f "$WORK_DIR/metrics.txt" ]] \
  && check "metrics.txt exists" "pass" \
  || check "metrics.txt exists" "fail"

[[ -s "$WORK_DIR/metrics.txt" ]] \
  && check "metrics.txt has content" "pass" \
  || check "metrics.txt has content" "fail"

echo ""

# Task 4: QoS notes
echo "Task 4: QoS documentation"
[[ -f "$WORK_DIR/qos-notes.txt" ]] \
  && check "qos-notes.txt exists" "pass" \
  || check "qos-notes.txt exists" "fail"

grep -qi "guaranteed\|burstable\|besteffort" "$WORK_DIR/qos-notes.txt" 2>/dev/null \
  && check "qos-notes.txt mentions QoS classes" "pass" \
  || check "qos-notes.txt mentions QoS classes" "fail"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
