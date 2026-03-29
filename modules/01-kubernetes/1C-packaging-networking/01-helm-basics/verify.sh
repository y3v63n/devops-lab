#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1C-01"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Exercise 1C-01 — Helm Basics"; echo ""

# Task 1: search-results.txt exists and has content
[[ -f "$WORK_DIR/search-results.txt" ]] && r="pass" || r="fail"
check "search-results.txt exists" "$r"

[[ -s "$WORK_DIR/search-results.txt" ]] && r="pass" || r="fail"
check "search-results.txt has content" "$r"

grep -qi "nginx" "$WORK_DIR/search-results.txt" 2>/dev/null && r="pass" || r="fail"
check "search-results.txt contains nginx results" "$r"

# Task 2: releases.txt exists and has content
[[ -f "$WORK_DIR/releases.txt" ]] && r="pass" || r="fail"
check "releases.txt exists" "$r"

[[ -s "$WORK_DIR/releases.txt" ]] && r="pass" || r="fail"
check "releases.txt has content" "$r"

# Task 3: custom-values.yaml exists and references NodePort
[[ -f "$WORK_DIR/custom-values.yaml" ]] && r="pass" || r="fail"
check "custom-values.yaml exists" "$r"

grep -q "NodePort" "$WORK_DIR/custom-values.yaml" 2>/dev/null && r="pass" || r="fail"
check "custom-values.yaml contains NodePort" "$r"

grep -q "replicaCount" "$WORK_DIR/custom-values.yaml" 2>/dev/null && r="pass" || r="fail"
check "custom-values.yaml contains replicaCount" "$r"

# Task 4: helm-history.txt exists and has content
[[ -f "$WORK_DIR/helm-history.txt" ]] && r="pass" || r="fail"
check "helm-history.txt exists" "$r"

[[ -s "$WORK_DIR/helm-history.txt" ]] && r="pass" || r="fail"
check "helm-history.txt has content" "$r"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
