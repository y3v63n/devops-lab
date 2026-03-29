#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1C-06"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Exercise 1C-06 — Multi-Container Pods"; echo ""

# Task 1: init-container.yaml exists and is valid
[[ -f "$WORK_DIR/init-container.yaml" ]] && r="pass" || r="fail"
check "init-container.yaml exists" "$r"

grep -q "kind: Pod" "$WORK_DIR/init-container.yaml" 2>/dev/null && r="pass" || r="fail"
check "init-container.yaml is a Pod manifest" "$r"

grep -q "initContainers" "$WORK_DIR/init-container.yaml" 2>/dev/null && r="pass" || r="fail"
check "init-container.yaml has initContainers section" "$r"

grep -q "emptyDir" "$WORK_DIR/init-container.yaml" 2>/dev/null && r="pass" || r="fail"
check "init-container.yaml uses emptyDir shared volume" "$r"

# init-demo pod exists
kubectl get pod init-demo &>/dev/null && r="pass" || r="fail"
check "init-demo pod exists in cluster" "$r"

# Check pod is running or completed (init containers done, main running)
POD_STATUS=$(kubectl get pod init-demo -o jsonpath='{.status.phase}' 2>/dev/null)
[[ "$POD_STATUS" == "Running" || "$POD_STATUS" == "Succeeded" ]] && r="pass" || r="fail"
check "init-demo pod is Running (init container completed)" "$r"

# Task 2: sidecar.yaml exists and is valid
[[ -f "$WORK_DIR/sidecar.yaml" ]] && r="pass" || r="fail"
check "sidecar.yaml exists" "$r"

grep -q "kind: Pod" "$WORK_DIR/sidecar.yaml" 2>/dev/null && r="pass" || r="fail"
check "sidecar.yaml is a Pod manifest" "$r"

# Count containers in sidecar.yaml — should have 2
CONTAINER_COUNT=$(grep -c "^\s*- name:" "$WORK_DIR/sidecar.yaml" 2>/dev/null || echo 0)
[[ "$CONTAINER_COUNT" -ge 2 ]] && r="pass" || r="fail"
check "sidecar.yaml defines 2 containers" "$r"

grep -q "emptyDir" "$WORK_DIR/sidecar.yaml" 2>/dev/null && r="pass" || r="fail"
check "sidecar.yaml uses shared emptyDir volume" "$r"

# sidecar-demo pod exists
kubectl get pod sidecar-demo &>/dev/null && r="pass" || r="fail"
check "sidecar-demo pod exists in cluster" "$r"

# Task 3: init-events.txt exists with describe output
[[ -f "$WORK_DIR/init-events.txt" ]] && r="pass" || r="fail"
check "init-events.txt exists" "$r"

grep -q "Events:" "$WORK_DIR/init-events.txt" 2>/dev/null && r="pass" || r="fail"
check "init-events.txt contains Events section from kubectl describe" "$r"

grep -qi "init" "$WORK_DIR/init-events.txt" 2>/dev/null && r="pass" || r="fail"
check "init-events.txt references init container" "$r"

# Task 4: patterns.txt exists with content
[[ -f "$WORK_DIR/patterns.txt" ]] && r="pass" || r="fail"
check "patterns.txt exists" "$r"

[[ -s "$WORK_DIR/patterns.txt" ]] && r="pass" || r="fail"
check "patterns.txt has content" "$r"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
