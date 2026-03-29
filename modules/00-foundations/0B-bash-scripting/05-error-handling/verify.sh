#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/0B-05"
PASS=0
FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then
    echo "  ✓ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "Verifying: 0B-05 Error Handling"
echo ""

# Task 1 — safe-script.sh
echo "Task 1: safe-script.sh"

if [[ -f "$WORK_DIR/safe-script.sh" ]]; then
  check "safe-script.sh uses set -e or set -euo pipefail" \
    "$(grep -q 'set -e' "$WORK_DIR/safe-script.sh" && echo pass || echo fail)"

  check "safe-script.sh uses trap" \
    "$(grep -q 'trap' "$WORK_DIR/safe-script.sh" && echo pass || echo fail)"

  check "safe-script.sh uses mktemp" \
    "$(grep -q 'mktemp' "$WORK_DIR/safe-script.sh" && echo pass || echo fail)"

  # Run the script and capture output
  output=$(bash "$WORK_DIR/safe-script.sh" 2>/dev/null)
  exit_code=$?
  check "safe-script.sh exits with code 0" \
    "$([[ $exit_code -eq 0 ]] && echo pass || echo fail)"

  # The script should print a temp dir path — extract it
  tmpdir=$(echo "$output" | grep -oE '/tmp/[^ ]+' | head -1)
  if [[ -n "$tmpdir" ]]; then
    check "temp directory was cleaned up after script ran" \
      "$([[ ! -d "$tmpdir" ]] && echo pass || echo fail)"
  else
    check "script printed a temp directory path" fail
  fi
else
  check "safe-script.sh exists" fail
  check "safe-script.sh uses set -e" fail
  check "safe-script.sh uses trap" fail
  check "safe-script.sh exits 0" fail
  check "temp dir cleaned up" fail
fi

echo ""
echo "Task 2: retry.sh"

if [[ -f "$WORK_DIR/retry.sh" ]]; then
  # Test: true succeeds on first try
  output=$(bash "$WORK_DIR/retry.sh" true 2>&1)
  exit_code=$?
  check "retry.sh true → exits 0" \
    "$([[ $exit_code -eq 0 ]] && echo pass || echo fail)"
  check "retry.sh true → mentions Attempt 1" \
    "$(echo "$output" | grep -qi 'attempt.*1\|1.*attempt' && echo pass || echo fail)"

  # Test: false fails all 3 attempts
  start=$SECONDS
  output=$(bash "$WORK_DIR/retry.sh" false 2>&1)
  exit_code=$?
  elapsed=$(( SECONDS - start ))
  check "retry.sh false → exits 1 (all attempts failed)" \
    "$([[ $exit_code -ne 0 ]] && echo pass || echo fail)"
  check "retry.sh false → mentions 3 attempts" \
    "$(echo "$output" | grep -q '3' && echo pass || echo fail)"
  check "retry.sh false → waited (takes at least 2 seconds for sleeps)" \
    "$([[ $elapsed -ge 2 ]] && echo pass || echo fail)"
else
  check "retry.sh exists" fail
  check "retry.sh true → exits 0" fail
  check "retry.sh false → exits 1" fail
  check "retry.sh false → makes 3 attempts" fail
fi

echo ""
echo "Task 3: validate-input.sh"

if [[ -f "$WORK_DIR/validate-input.sh" ]]; then
  # Test with a valid, non-empty file
  tmpfile=$(mktemp)
  echo "some content" > "$tmpfile"
  bash "$WORK_DIR/validate-input.sh" "$tmpfile" >/dev/null 2>&1
  check "validate-input.sh passes for valid readable non-empty file" \
    "$([[ $? -eq 0 ]] && echo pass || echo fail)"
  rm -f "$tmpfile"

  # Test with non-existent file
  output=$(bash "$WORK_DIR/validate-input.sh" "/tmp/does-not-exist-xyz123" 2>&1)
  exit_code=$?
  check "validate-input.sh fails for missing file (exit non-zero)" \
    "$([[ $exit_code -ne 0 ]] && echo pass || echo fail)"
  check "validate-input.sh prints 'not found' error for missing file" \
    "$(echo "$output" | grep -qi 'not found\|does not exist\|no such' && echo pass || echo fail)"

  # Test with empty file
  tmpempty=$(mktemp)
  output=$(bash "$WORK_DIR/validate-input.sh" "$tmpempty" 2>&1)
  exit_code=$?
  check "validate-input.sh fails for empty file (exit non-zero)" \
    "$([[ $exit_code -ne 0 ]] && echo pass || echo fail)"
  check "validate-input.sh prints 'empty' error for empty file" \
    "$(echo "$output" | grep -qi 'empty' && echo pass || echo fail)"
  rm -f "$tmpempty"
else
  check "validate-input.sh exists" fail
  check "validate-input.sh passes for valid file" fail
  check "validate-input.sh fails for missing file" fail
  check "validate-input.sh fails for empty file" fail
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
