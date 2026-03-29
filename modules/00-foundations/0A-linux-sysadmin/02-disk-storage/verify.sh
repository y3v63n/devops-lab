#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/0A-02"
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

echo "Verifying: Disk Storage"
echo ""

# Check 1: largest-fs.txt contains a valid mount point
if [[ -f "$WORK_DIR/largest-fs.txt" ]]; then
  fs=$(cat "$WORK_DIR/largest-fs.txt" | tr -d '[:space:]')
  if [[ "$fs" == /* ]]; then
    # Verify the path is actually a mounted filesystem
    if df "$fs" &>/dev/null; then
      check "largest-fs.txt contains a valid mount point ($fs)" "pass"
    else
      check "largest-fs.txt value '$fs' is not a recognized mount point" "fail"
    fi
  else
    check "largest-fs.txt should start with / (got: '$fs')" "fail"
  fi
else
  check "largest-fs.txt exists in $WORK_DIR" "fail"
fi

# Check 2: largest-dirs.txt contains 3 lines, each a path under /var
if [[ -f "$WORK_DIR/largest-dirs.txt" ]]; then
  line_count=$(grep -c . "$WORK_DIR/largest-dirs.txt" 2>/dev/null || echo 0)
  if [[ "$line_count" -ge 3 ]]; then
    valid=true
    while IFS= read -r line; do
      line=$(echo "$line" | tr -d '[:space:]')
      if [[ ! "$line" == /var/* ]] && [[ -n "$line" ]]; then
        valid=false
        break
      fi
    done < "$WORK_DIR/largest-dirs.txt"
    if $valid; then
      check "largest-dirs.txt contains 3 /var paths ($line_count lines)" "pass"
    else
      check "largest-dirs.txt paths should all be under /var" "fail"
    fi
  else
    check "largest-dirs.txt should have 3 lines (got $line_count)" "fail"
  fi
else
  check "largest-dirs.txt exists in $WORK_DIR" "fail"
fi

# Check 3: block-devices.txt is non-empty and contains lsblk column headers
if [[ -f "$WORK_DIR/block-devices.txt" ]]; then
  if [[ -s "$WORK_DIR/block-devices.txt" ]]; then
    if grep -qi "NAME" "$WORK_DIR/block-devices.txt"; then
      check "block-devices.txt contains lsblk output with NAME column" "pass"
    else
      check "block-devices.txt should contain lsblk output (missing NAME column)" "fail"
    fi
  else
    check "block-devices.txt is empty — run lsblk and redirect output" "fail"
  fi
else
  check "block-devices.txt exists in $WORK_DIR" "fail"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
