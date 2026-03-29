#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1B-01"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Exercise 1B-01 — Namespaces"; echo ""

# Task 1: Namespaces exist
echo "Task 1: Namespace creation"
kubectl get namespace dev &>/dev/null \
  && check "namespace 'dev' exists" "pass" \
  || check "namespace 'dev' exists" "fail"

kubectl get namespace staging &>/dev/null \
  && check "namespace 'staging' exists" "pass" \
  || check "namespace 'staging' exists" "fail"

[[ -f "$WORK_DIR/namespaces.txt" ]] \
  && check "namespaces.txt file exists" "pass" \
  || check "namespaces.txt file exists" "fail"

grep -q "dev" "$WORK_DIR/namespaces.txt" 2>/dev/null \
  && check "namespaces.txt contains 'dev'" "pass" \
  || check "namespaces.txt contains 'dev'" "fail"

echo ""

# Task 2: Pods in correct namespaces
echo "Task 2: Workloads in namespaces"
DEV_PODS=$(kubectl get pods -n dev --no-headers 2>/dev/null | wc -l)
[[ "$DEV_PODS" -ge 2 ]] \
  && check "dev namespace has >= 2 pods" "pass" \
  || check "dev namespace has >= 2 pods (found $DEV_PODS)" "fail"

STAGING_PODS=$(kubectl get pods -n staging --no-headers 2>/dev/null | wc -l)
[[ "$STAGING_PODS" -ge 1 ]] \
  && check "staging namespace has >= 1 pod" "pass" \
  || check "staging namespace has >= 1 pod (found $STAGING_PODS)" "fail"

[[ -f "$WORK_DIR/dev-pods.txt" ]] \
  && check "dev-pods.txt file exists" "pass" \
  || check "dev-pods.txt file exists" "fail"

[[ -f "$WORK_DIR/staging-pods.txt" ]] \
  && check "staging-pods.txt file exists" "pass" \
  || check "staging-pods.txt file exists" "fail"

echo ""

# Task 3: Cross-namespace file
echo "Task 3: Cross-namespace access"
[[ -f "$WORK_DIR/cross-ns.txt" ]] \
  && check "cross-ns.txt file exists" "pass" \
  || check "cross-ns.txt file exists" "fail"

[[ -s "$WORK_DIR/cross-ns.txt" ]] \
  && check "cross-ns.txt has content" "pass" \
  || check "cross-ns.txt has content" "fail"

echo ""

# Task 4: Default namespace set
echo "Task 4: Default namespace context"
CURRENT_NS=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
[[ "$CURRENT_NS" == "dev" ]] \
  && check "current context namespace is 'dev'" "pass" \
  || check "current context namespace is 'dev' (got: '$CURRENT_NS')" "fail"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
