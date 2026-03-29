#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1A-01"
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

echo "Verifying: Exercise 1A-01 — Kubernetes Architecture Overview"
echo ""

# Task 1: cluster-info.txt
if [[ -f "$WORK_DIR/cluster-info.txt" ]] && [[ -s "$WORK_DIR/cluster-info.txt" ]]; then
  check "cluster-info.txt exists and is non-empty" "pass"
else
  check "cluster-info.txt exists and is non-empty" "fail"
fi

if grep -qi "kubernetes" "$WORK_DIR/cluster-info.txt" 2>/dev/null; then
  check "cluster-info.txt mentions 'Kubernetes'" "pass"
else
  check "cluster-info.txt mentions 'Kubernetes'" "fail"
fi

# Task 2: nodes.txt
if [[ -f "$WORK_DIR/nodes.txt" ]] && [[ -s "$WORK_DIR/nodes.txt" ]]; then
  check "nodes.txt exists and is non-empty" "pass"
else
  check "nodes.txt exists and is non-empty" "fail"
fi

if grep -qiE "Ready|NAME" "$WORK_DIR/nodes.txt" 2>/dev/null; then
  check "nodes.txt contains node status data" "pass"
else
  check "nodes.txt contains node status data" "fail"
fi

# Task 3: system-pods.txt
if [[ -f "$WORK_DIR/system-pods.txt" ]] && [[ -s "$WORK_DIR/system-pods.txt" ]]; then
  check "system-pods.txt exists and is non-empty" "pass"
else
  check "system-pods.txt exists and is non-empty" "fail"
fi

if grep -qiE "etcd|apiserver|scheduler|controller|coredns|kube-proxy" "$WORK_DIR/system-pods.txt" 2>/dev/null; then
  check "system-pods.txt contains control plane component names" "pass"
else
  check "system-pods.txt contains control plane component names" "fail"
fi

# Task 4: architecture.txt
if [[ -f "$WORK_DIR/architecture.txt" ]] && [[ -s "$WORK_DIR/architecture.txt" ]]; then
  check "architecture.txt exists and is non-empty" "pass"
else
  check "architecture.txt exists and is non-empty" "fail"
fi

ARCH_WORD_COUNT=$(wc -w < "$WORK_DIR/architecture.txt" 2>/dev/null || echo 0)
if [[ "$ARCH_WORD_COUNT" -ge 50 ]]; then
  check "architecture.txt has at least 50 words (substantive explanation)" "pass"
else
  check "architecture.txt has at least 50 words (substantive explanation)" "fail"
fi

if grep -qiE "api.?server|scheduler|etcd|kubelet|controller" "$WORK_DIR/architecture.txt" 2>/dev/null; then
  check "architecture.txt references key K8s components" "pass"
else
  check "architecture.txt references key K8s components" "fail"
fi

# Bonus: live cluster check (non-fatal)
echo ""
echo "  [Bonus — requires live cluster]"
if kubectl cluster-info &>/dev/null; then
  check "kubectl can reach the cluster" "pass"
  NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
  if [[ "$NODE_COUNT" -ge 1 ]]; then
    check "At least one node is registered" "pass"
  else
    check "At least one node is registered" "fail"
  fi
else
  echo "  ~ cluster unreachable — skipping live checks"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
