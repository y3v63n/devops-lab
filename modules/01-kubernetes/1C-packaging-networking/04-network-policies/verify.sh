#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1C-04"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Exercise 1C-04 — Network Policies"; echo ""

# Task 1: Namespace exists
kubectl get namespace netpol-lab &>/dev/null && r="pass" || r="fail"
check "netpol-lab namespace exists" "$r"

# Task 1: Pods exist in namespace
kubectl get pod web-pod -n netpol-lab &>/dev/null && r="pass" || r="fail"
check "web-pod exists in netpol-lab" "$r"

kubectl get pod db-pod -n netpol-lab &>/dev/null && r="pass" || r="fail"
check "db-pod exists in netpol-lab" "$r"

# Task 2: netpol.yaml file exists and is valid
[[ -f "$WORK_DIR/netpol.yaml" ]] && r="pass" || r="fail"
check "netpol.yaml file exists" "$r"

grep -q "kind: NetworkPolicy" "$WORK_DIR/netpol.yaml" 2>/dev/null && r="pass" || r="fail"
check "netpol.yaml contains NetworkPolicy resource" "$r"

grep -q "role: db" "$WORK_DIR/netpol.yaml" 2>/dev/null && r="pass" || r="fail"
check "netpol.yaml selects role=db pods" "$r"

grep -q "role: web" "$WORK_DIR/netpol.yaml" 2>/dev/null && r="pass" || r="fail"
check "netpol.yaml allows role=web pods" "$r"

# NetworkPolicy exists in cluster
kubectl get networkpolicy allow-web-to-db -n netpol-lab &>/dev/null && r="pass" || r="fail"
check "NetworkPolicy applied to cluster" "$r"

# Task 3: policy-test.txt exists and has content
[[ -f "$WORK_DIR/policy-test.txt" ]] && r="pass" || r="fail"
check "policy-test.txt exists" "$r"

[[ -s "$WORK_DIR/policy-test.txt" ]] && r="pass" || r="fail"
check "policy-test.txt has content" "$r"

# Task 4: netpol-notes.txt exists with content
[[ -f "$WORK_DIR/netpol-notes.txt" ]] && r="pass" || r="fail"
check "netpol-notes.txt exists" "$r"

[[ -s "$WORK_DIR/netpol-notes.txt" ]] && r="pass" || r="fail"
check "netpol-notes.txt has content" "$r"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
