#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/0A-04"
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

echo "Verifying: Finding Things"
echo ""

# Check 1: found-logs.txt contains .log file paths
if [[ -f "$WORK_DIR/found-logs.txt" ]]; then
  if grep -q "\.log$" "$WORK_DIR/found-logs.txt"; then
    count=$(grep -c "\.log$" "$WORK_DIR/found-logs.txt")
    if grep -q "app.log" "$WORK_DIR/found-logs.txt"; then
      check "found-logs.txt lists $count .log file(s) including app.log" "pass"
    else
      check "found-logs.txt should include app.log" "fail"
    fi
  else
    check "found-logs.txt should contain paths ending in .log" "fail"
  fi
else
  check "found-logs.txt exists in $WORK_DIR" "fail"
fi

# Check 2: errors.txt contains only ERROR lines
if [[ -f "$WORK_DIR/errors.txt" ]]; then
  if [[ -s "$WORK_DIR/errors.txt" ]]; then
    error_count=$(grep -c "ERROR" "$WORK_DIR/errors.txt" 2>/dev/null || echo 0)
    non_error=$(grep -v "ERROR" "$WORK_DIR/errors.txt" | grep -c "." 2>/dev/null || echo 0)
    if [[ "$error_count" -ge 4 ]] && [[ "$non_error" -eq 0 ]]; then
      check "errors.txt contains $error_count ERROR lines (no non-ERROR lines)" "pass"
    elif [[ "$non_error" -gt 0 ]]; then
      check "errors.txt contains non-ERROR lines — use grep 'ERROR'" "fail"
    else
      check "errors.txt should have at least 4 ERROR lines (got $error_count)" "fail"
    fi
  else
    check "errors.txt is empty — check grep command" "fail"
  fi
else
  check "errors.txt exists in $WORK_DIR" "fail"
fi

# Check 3: error-codes.txt contains error codes (APP0xx format)
if [[ -f "$WORK_DIR/error-codes.txt" ]]; then
  if [[ -s "$WORK_DIR/error-codes.txt" ]]; then
    if grep -q "^APP0" "$WORK_DIR/error-codes.txt"; then
      count=$(grep -c "^APP0" "$WORK_DIR/error-codes.txt")
      check "error-codes.txt contains $count error codes (APP0xx format)" "pass"
    else
      check "error-codes.txt should contain APP0xx codes — check awk field number" "fail"
    fi
  else
    check "error-codes.txt is empty — check awk command" "fail"
  fi
else
  check "error-codes.txt exists in $WORK_DIR" "fail"
fi

# Check 4: large-files.txt contains files from the data directory that are >100 bytes
if [[ -f "$WORK_DIR/large-files.txt" ]]; then
  if [[ -s "$WORK_DIR/large-files.txt" ]]; then
    # Verify each listed file is actually >100 bytes
    all_large=true
    while IFS= read -r filepath; do
      [[ -z "$filepath" ]] && continue
      if [[ -f "$filepath" ]]; then
        size=$(stat -c "%s" "$filepath")
        if [[ "$size" -le 100 ]]; then
          all_large=false
          break
        fi
      fi
    done < "$WORK_DIR/large-files.txt"

    listed=$(grep -c "." "$WORK_DIR/large-files.txt" 2>/dev/null || echo 0)
    if $all_large; then
      check "large-files.txt lists $listed file(s) all larger than 100 bytes" "pass"
    else
      check "large-files.txt includes files that are not >100 bytes" "fail"
    fi
  else
    check "large-files.txt is empty — check find -size +100c command" "fail"
  fi
else
  check "large-files.txt exists in $WORK_DIR" "fail"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
