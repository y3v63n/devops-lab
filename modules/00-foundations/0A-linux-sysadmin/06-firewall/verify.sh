#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/0A-06"
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

echo "Verifying: Firewall"
echo ""

# Check 1: ufw-status.txt contains "active" or "inactive"
if [[ -f "$WORK_DIR/ufw-status.txt" ]]; then
  status=$(cat "$WORK_DIR/ufw-status.txt" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
  if [[ "$status" == "active" ]] || [[ "$status" == "inactive" ]]; then
    # Verify against actual system state
    actual=""
    if command -v ufw &>/dev/null; then
      sudo ufw status 2>/dev/null | grep -q "Status: active" && actual="active" || actual="inactive"
    else
      actual="inactive"
    fi
    if [[ "$status" == "$actual" ]]; then
      check "ufw-status.txt correctly shows '$status'" "pass"
    else
      check "ufw-status.txt shows '$status' but actual state is '$actual'" "fail"
    fi
  else
    check "ufw-status.txt should contain 'active' or 'inactive', got: '$status'" "fail"
  fi
else
  check "ufw-status.txt exists in $WORK_DIR" "fail"
fi

# Check 2: current-rules.txt is non-empty with firewall output
if [[ -f "$WORK_DIR/current-rules.txt" ]]; then
  if [[ -s "$WORK_DIR/current-rules.txt" ]]; then
    # Accept ufw output or iptables output
    if grep -qiE "(Status|Chain|ufw|iptables|ACCEPT|DROP|DENY|ALLOW|Policy)" "$WORK_DIR/current-rules.txt"; then
      check "current-rules.txt contains firewall rule output" "pass"
    else
      check "current-rules.txt doesn't look like firewall output" "fail"
    fi
  else
    check "current-rules.txt is empty — run ufw status verbose or iptables -L" "fail"
  fi
else
  check "current-rules.txt exists in $WORK_DIR" "fail"
fi

# Check 3: default-policy.txt contains "deny", "allow", "reject", or "drop"
if [[ -f "$WORK_DIR/default-policy.txt" ]]; then
  policy=$(cat "$WORK_DIR/default-policy.txt" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
  if [[ "$policy" == "deny" ]] || [[ "$policy" == "allow" ]] || [[ "$policy" == "reject" ]] || [[ "$policy" == "drop" ]]; then
    check "default-policy.txt contains a valid policy: '$policy'" "pass"
  else
    check "default-policy.txt should be 'deny', 'allow', 'reject', or 'drop', got: '$policy'" "fail"
  fi
else
  check "default-policy.txt exists in $WORK_DIR" "fail"
fi

# Check 4: rule-explanation.txt is non-empty and mentions key concepts
if [[ -f "$WORK_DIR/rule-explanation.txt" ]]; then
  if [[ -s "$WORK_DIR/rule-explanation.txt" ]]; then
    line_count=$(wc -l < "$WORK_DIR/rule-explanation.txt")
    word_count=$(wc -w < "$WORK_DIR/rule-explanation.txt")
    if [[ "$word_count" -ge 10 ]]; then
      # Check for key concepts: port 5432 or postgres, and the subnet
      has_port=$(grep -ciE "(5432|postgres)" "$WORK_DIR/rule-explanation.txt" || echo 0)
      has_subnet=$(grep -ciE "(10\.0\.0|subnet|network|/24)" "$WORK_DIR/rule-explanation.txt" || echo 0)
      if [[ "$has_port" -gt 0 ]] && [[ "$has_subnet" -gt 0 ]]; then
        check "rule-explanation.txt mentions port 5432 and the source subnet" "pass"
      else
        check "rule-explanation.txt should mention port 5432 and the 10.0.0.0/24 subnet" "fail"
      fi
    else
      check "rule-explanation.txt is too short ($word_count words) — write 1-2 full sentences" "fail"
    fi
  else
    check "rule-explanation.txt is empty — explain what the ufw rule does" "fail"
  fi
else
  check "rule-explanation.txt exists in $WORK_DIR" "fail"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
