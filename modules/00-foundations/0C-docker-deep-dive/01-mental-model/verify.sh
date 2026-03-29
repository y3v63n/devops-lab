#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/0C-01"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then
    echo "  ✓ $desc"; PASS=$((PASS+1))
  else
    echo "  ✗ $desc"; FAIL=$((FAIL+1))
  fi
}

echo "Verifying: Exercise 0C-01 — Docker Mental Model"
echo ""

# Task 1: alpine image exists locally
alpine_id=$(docker images alpine:latest --format "{{.ID}}" 2>/dev/null)
check "alpine:latest image is present locally" \
  "$([[ -n "$alpine_id" ]] && echo pass || echo fail)"

# Task 1: image-id.txt exists and matches
if [[ -f "$WORK_DIR/image-id.txt" ]]; then
  recorded_id=$(cat "$WORK_DIR/image-id.txt" | tr -d '[:space:]')
  check "image-id.txt contains the alpine image ID" \
    "$([[ "$recorded_id" == "$alpine_id" ]] && echo pass || echo fail)"
else
  check "image-id.txt exists" "fail"
fi

# Task 2: container-id.txt exists and contains a valid container ID
if [[ -f "$WORK_DIR/container-id.txt" ]]; then
  cid=$(cat "$WORK_DIR/container-id.txt" | tr -d '[:space:]')
  check "container-id.txt is non-empty" \
    "$([[ -n "$cid" ]] && echo pass || echo fail)"
  # Verify it looks like a container ID (12 hex chars or 64 hex chars)
  check "container-id.txt contains a valid container ID format" \
    "$([[ "$cid" =~ ^[a-f0-9]{12,64}$ ]] && echo pass || echo fail)"
else
  check "container-id.txt exists" "fail"
  check "container-id.txt contains a valid container ID format" "fail"
fi

# Task 3: lab-test container is running
lab_test_status=$(docker inspect --format "{{.State.Status}}" lab-test 2>/dev/null)
check "lab-test container is running" \
  "$([[ "$lab_test_status" == "running" ]] && echo pass || echo fail)"

# Task 4: answers.txt has at least 3 non-empty lines
if [[ -f "$WORK_DIR/answers.txt" ]]; then
  line_count=$(grep -c '[^[:space:]]' "$WORK_DIR/answers.txt" 2>/dev/null || echo 0)
  check "answers.txt has at least 3 non-empty lines" \
    "$([[ "$line_count" -ge 3 ]] && echo pass || echo fail)"
else
  check "answers.txt exists" "fail"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
