#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/0A-01"
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

echo "Verifying: Process Management"
echo ""

# Check 1: highest-cpu.txt exists and contains a valid PID
if [[ -f "$WORK_DIR/highest-cpu.txt" ]]; then
  pid=$(cat "$WORK_DIR/highest-cpu.txt" | tr -d '[:space:]')
  if [[ "$pid" =~ ^[0-9]+$ ]]; then
    check "highest-cpu.txt contains a valid PID ($pid)" "pass"
  else
    check "highest-cpu.txt should contain a numeric PID, got: '$pid'" "fail"
  fi
else
  check "highest-cpu.txt exists in $WORK_DIR" "fail"
fi

# Check 2: sleep process was started and killed
if [[ -f "$WORK_DIR/sleep-pid.txt" ]]; then
  pid=$(cat "$WORK_DIR/sleep-pid.txt" | tr -d '[:space:]')
  if [[ "$pid" =~ ^[0-9]+$ ]]; then
    if ! kill -0 "$pid" 2>/dev/null; then
      check "sleep process ($pid) was started and killed" "pass"
    else
      check "sleep process ($pid) is still running — you need to kill it" "fail"
    fi
  else
    check "sleep-pid.txt should contain a numeric PID" "fail"
  fi
else
  check "sleep-pid.txt exists in $WORK_DIR" "fail"
fi

# Check 3: ssh-status.txt
if [[ -f "$WORK_DIR/ssh-status.txt" ]]; then
  status=$(cat "$WORK_DIR/ssh-status.txt" | tr -d '[:space:]')
  actual=$(systemctl is-active ssh 2>/dev/null || systemctl is-active sshd 2>/dev/null || echo "unknown")
  if [[ "$status" == "$actual" ]]; then
    check "SSH service status correctly identified as '$status'" "pass"
  else
    check "SSH status is '$actual', but you wrote '$status'" "fail"
  fi
else
  check "ssh-status.txt exists in $WORK_DIR" "fail"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
