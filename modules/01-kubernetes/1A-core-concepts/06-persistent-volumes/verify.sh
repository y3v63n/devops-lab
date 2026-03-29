#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1A-06"
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

echo "Verifying: Exercise 1A-06 — Persistent Volumes"
echo ""

# Task 1: pvc.yaml
if [[ -f "$WORK_DIR/pvc.yaml" ]] && [[ -s "$WORK_DIR/pvc.yaml" ]]; then
  check "pvc.yaml exists and is non-empty" "pass"
else
  check "pvc.yaml exists and is non-empty" "fail"
fi

if grep -q "kind: PersistentVolumeClaim" "$WORK_DIR/pvc.yaml" 2>/dev/null; then
  check "pvc.yaml has kind: PersistentVolumeClaim" "pass"
else
  check "pvc.yaml has kind: PersistentVolumeClaim" "fail"
fi

if grep -q "data-pvc" "$WORK_DIR/pvc.yaml" 2>/dev/null; then
  check "pvc.yaml contains name: data-pvc" "pass"
else
  check "pvc.yaml contains name: data-pvc" "fail"
fi

if grep -qE "storage:\s*100Mi" "$WORK_DIR/pvc.yaml" 2>/dev/null; then
  check "pvc.yaml requests 100Mi storage" "pass"
else
  check "pvc.yaml requests 100Mi storage" "fail"
fi

if grep -q "ReadWriteOnce" "$WORK_DIR/pvc.yaml" 2>/dev/null; then
  check "pvc.yaml specifies ReadWriteOnce access mode" "pass"
else
  check "pvc.yaml specifies ReadWriteOnce access mode" "fail"
fi

# Task 3: persistence-proof.txt
if [[ -f "$WORK_DIR/persistence-proof.txt" ]] && [[ -s "$WORK_DIR/persistence-proof.txt" ]]; then
  check "persistence-proof.txt exists and is non-empty" "pass"
else
  check "persistence-proof.txt exists and is non-empty" "fail"
fi

if grep -q "persistent data" "$WORK_DIR/persistence-proof.txt" 2>/dev/null; then
  check "persistence-proof.txt contains 'persistent data' (proves data survived pod deletion)" "pass"
else
  check "persistence-proof.txt contains 'persistent data'" "fail"
fi

# Task 4: storage-notes.txt
if [[ -f "$WORK_DIR/storage-notes.txt" ]] && [[ -s "$WORK_DIR/storage-notes.txt" ]]; then
  check "storage-notes.txt exists and is non-empty" "pass"
else
  check "storage-notes.txt exists and is non-empty" "fail"
fi

NOTES_WORDS=$(wc -w < "$WORK_DIR/storage-notes.txt" 2>/dev/null || echo 0)
if [[ "$NOTES_WORDS" -ge 50 ]]; then
  check "storage-notes.txt has at least 50 words" "pass"
else
  check "storage-notes.txt has at least 50 words" "fail"
fi

for term in PersistentVolume PersistentVolumeClaim StorageClass Retain Delete; do
  if grep -q "$term" "$WORK_DIR/storage-notes.txt" 2>/dev/null; then
    check "storage-notes.txt mentions $term" "pass"
  else
    check "storage-notes.txt mentions $term" "fail"
  fi
done

# Bonus: live cluster checks
echo ""
echo "  [Bonus — requires live cluster]"
if kubectl cluster-info &>/dev/null; then
  PVC_STATUS=$(kubectl get pvc data-pvc -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
  if [[ "$PVC_STATUS" == "Bound" ]]; then
    check "PVC data-pvc is Bound" "pass"
  elif [[ -n "$PVC_STATUS" ]]; then
    check "PVC data-pvc status: $PVC_STATUS (expected Bound)" "fail"
  else
    echo "  ~ PVC data-pvc not found in cluster"
  fi
else
  echo "  ~ cluster unreachable — skipping live checks"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
