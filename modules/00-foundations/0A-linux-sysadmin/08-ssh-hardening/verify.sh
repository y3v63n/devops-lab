#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/0A-08"
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

echo "Verifying: SSH Hardening"
echo ""

# Check 1: lab_key (private key) exists and is an ed25519 key
if [[ -f "$WORK_DIR/lab_key" ]]; then
  # Check it's a private key (starts with OpenSSH private key header)
  if head -1 "$WORK_DIR/lab_key" | grep -q "BEGIN OPENSSH PRIVATE KEY"; then
    check "lab_key exists and is an OpenSSH private key" "pass"
  else
    check "lab_key exists but doesn't look like an OpenSSH private key" "fail"
  fi
else
  check "lab_key (private key) exists in $WORK_DIR" "fail"
fi

# Check 1b: lab_key.pub exists and contains ed25519
if [[ -f "$WORK_DIR/lab_key.pub" ]]; then
  if grep -q "ed25519" "$WORK_DIR/lab_key.pub"; then
    check "lab_key.pub exists and is an ed25519 public key" "pass"
  else
    check "lab_key.pub should contain 'ed25519', got: $(cat "$WORK_DIR/lab_key.pub" | awk '{print $1}')" "fail"
  fi
else
  check "lab_key.pub (public key) exists in $WORK_DIR" "fail"
fi

# Check 2: sshd_config_hardened exists with correct hardened values
if [[ -f "$WORK_DIR/sshd_config_hardened" ]]; then
  # Check PasswordAuthentication is set to no
  if grep -q "^PasswordAuthentication no" "$WORK_DIR/sshd_config_hardened"; then
    check "sshd_config_hardened: PasswordAuthentication set to no" "pass"
  else
    check "sshd_config_hardened: PasswordAuthentication should be 'no'" "fail"
  fi

  # Check PermitRootLogin is set to no
  if grep -q "^PermitRootLogin no" "$WORK_DIR/sshd_config_hardened"; then
    check "sshd_config_hardened: PermitRootLogin set to no" "pass"
  else
    check "sshd_config_hardened: PermitRootLogin should be 'no'" "fail"
  fi

  # Check Port is set to 2222
  if grep -q "^Port 2222" "$WORK_DIR/sshd_config_hardened"; then
    check "sshd_config_hardened: Port set to 2222" "pass"
  else
    check "sshd_config_hardened: Port should be '2222'" "fail"
  fi

  # Ensure old insecure values are NOT present
  if ! grep -q "^PasswordAuthentication yes" "$WORK_DIR/sshd_config_hardened"; then
    check "sshd_config_hardened: old 'PasswordAuthentication yes' removed" "pass"
  else
    check "sshd_config_hardened: still contains 'PasswordAuthentication yes' — fix it" "fail"
  fi
else
  check "sshd_config_hardened exists in $WORK_DIR" "fail"
  check "sshd_config_hardened: PasswordAuthentication set to no" "fail"
  check "sshd_config_hardened: PermitRootLogin set to no" "fail"
  check "sshd_config_hardened: Port set to 2222" "fail"
fi

# Check 3: hardening-checklist.txt has at least 5 non-empty lines
if [[ -f "$WORK_DIR/hardening-checklist.txt" ]]; then
  line_count=$(grep -c "." "$WORK_DIR/hardening-checklist.txt" 2>/dev/null || echo 0)
  if [[ "$line_count" -ge 5 ]]; then
    check "hardening-checklist.txt has $line_count best practice entries (need 5+)" "pass"
  else
    check "hardening-checklist.txt has only $line_count lines — need at least 5" "fail"
  fi
else
  check "hardening-checklist.txt exists in $WORK_DIR" "fail"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
