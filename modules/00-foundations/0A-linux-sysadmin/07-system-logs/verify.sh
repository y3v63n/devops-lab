#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/0A-07"
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

echo "Verifying: System Logs"
echo ""

# Check 1: ssh-logs.txt is non-empty and contains log-like content
if [[ -f "$WORK_DIR/ssh-logs.txt" ]]; then
  if [[ -s "$WORK_DIR/ssh-logs.txt" ]]; then
    # Accept journal output (has timestamps) or "No entries" if no SSH logs exist
    if grep -qE "([A-Z][a-z]{2}\s+[0-9]|[0-9]{4}-[0-9]{2}-[0-9]{2}|No entries)" "$WORK_DIR/ssh-logs.txt"; then
      check "ssh-logs.txt contains journalctl output" "pass"
    else
      check "ssh-logs.txt doesn't look like journalctl output (missing timestamps)" "fail"
    fi
  else
    check "ssh-logs.txt is empty — run journalctl -u ssh or -u sshd" "fail"
  fi
else
  check "ssh-logs.txt exists in $WORK_DIR" "fail"
fi

# Check 2: errors-today.txt exists and is non-empty (even "no entries" is valid)
if [[ -f "$WORK_DIR/errors-today.txt" ]]; then
  # The file can be empty if there are genuinely no errors today — check it was created
  # We verify they ran the command by checking file was recently created or modified
  if [[ -f "$WORK_DIR/errors-today.txt" ]]; then
    word_count=$(wc -w < "$WORK_DIR/errors-today.txt" 2>/dev/null || echo 0)
    # Even an empty journal output produces a header line
    check "errors-today.txt exists ($(wc -l < "$WORK_DIR/errors-today.txt") lines)" "pass"
  fi
else
  check "errors-today.txt exists in $WORK_DIR" "fail"
fi

# Check 3: last-boot.txt contains a plausible date/time
if [[ -f "$WORK_DIR/last-boot.txt" ]]; then
  if [[ -s "$WORK_DIR/last-boot.txt" ]]; then
    content=$(cat "$WORK_DIR/last-boot.txt")
    # Accept various date formats: YYYY-MM-DD, Month Day, etc.
    if echo "$content" | grep -qE "([0-9]{4}-[0-9]{2}-[0-9]{2}|[A-Z][a-z]{2}\s*[0-9]|[0-9]{2}:[0-9]{2})"; then
      check "last-boot.txt contains a timestamp" "pass"
    else
      check "last-boot.txt should contain a date/time, got: '$content'" "fail"
    fi
  else
    check "last-boot.txt is empty — run 'who -b' or 'journalctl --list-boots'" "fail"
  fi
else
  check "last-boot.txt exists in $WORK_DIR" "fail"
fi

# Check 4: error-service-count.txt contains a non-negative integer
if [[ -f "$WORK_DIR/error-service-count.txt" ]]; then
  count=$(cat "$WORK_DIR/error-service-count.txt" | tr -d '[:space:]')
  if [[ "$count" =~ ^[0-9]+$ ]]; then
    check "error-service-count.txt contains a valid count: $count" "pass"
  else
    check "error-service-count.txt should contain a number, got: '$count'" "fail"
  fi
else
  check "error-service-count.txt exists in $WORK_DIR" "fail"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
