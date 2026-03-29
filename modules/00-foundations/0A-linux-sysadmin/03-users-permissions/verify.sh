#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/0A-03"
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

echo "Verifying: Users and Permissions"
echo ""

# Check 1: secret.txt exists, has content "classified", permissions 600
if [[ -f "$WORK_DIR/secret.txt" ]]; then
  perms=$(stat -c "%a" "$WORK_DIR/secret.txt")
  content=$(cat "$WORK_DIR/secret.txt" | tr -d '[:space:]')
  if [[ "$perms" == "600" ]]; then
    check "secret.txt has permissions 600 (rw-------)" "pass"
  else
    check "secret.txt should have permissions 600, got $perms" "fail"
  fi
  if [[ "$content" == "classified" ]]; then
    check "secret.txt contains 'classified'" "pass"
  else
    check "secret.txt should contain 'classified', got '$content'" "fail"
  fi
else
  check "secret.txt exists in $WORK_DIR" "fail"
  check "secret.txt has permissions 600" "fail"
fi

# Check 2: shared.txt exists, has content "public", permissions 644
if [[ -f "$WORK_DIR/shared.txt" ]]; then
  perms=$(stat -c "%a" "$WORK_DIR/shared.txt")
  content=$(cat "$WORK_DIR/shared.txt" | tr -d '[:space:]')
  if [[ "$perms" == "644" ]]; then
    check "shared.txt has permissions 644 (rw-r--r--)" "pass"
  else
    check "shared.txt should have permissions 644, got $perms" "fail"
  fi
  if [[ "$content" == "public" ]]; then
    check "shared.txt contains 'public'" "pass"
  else
    check "shared.txt should contain 'public', got '$content'" "fail"
  fi
else
  check "shared.txt exists in $WORK_DIR" "fail"
  check "shared.txt has permissions 644" "fail"
fi

# Check 3: script.sh exists, permissions 755, starts with shebang
if [[ -f "$WORK_DIR/script.sh" ]]; then
  perms=$(stat -c "%a" "$WORK_DIR/script.sh")
  first_line=$(head -1 "$WORK_DIR/script.sh")
  if [[ "$perms" == "755" ]]; then
    check "script.sh has permissions 755 (rwxr-xr-x)" "pass"
  else
    check "script.sh should have permissions 755, got $perms" "fail"
  fi
  if [[ "$first_line" == "#!/bin/bash" ]]; then
    check "script.sh starts with #!/bin/bash shebang" "pass"
  else
    check "script.sh should start with #!/bin/bash, got '$first_line'" "fail"
  fi
else
  check "script.sh exists in $WORK_DIR" "fail"
  check "script.sh has permissions 755" "fail"
fi

# Check 4: passwd-perms.txt contains the actual octal perms of /etc/passwd
if [[ -f "$WORK_DIR/passwd-perms.txt" ]]; then
  recorded=$(cat "$WORK_DIR/passwd-perms.txt" | tr -d '[:space:]')
  actual=$(stat -c "%a" /etc/passwd)
  if [[ "$recorded" == "$actual" ]]; then
    check "passwd-perms.txt correctly records /etc/passwd permissions ($actual)" "pass"
  else
    check "passwd-perms.txt has '$recorded' but /etc/passwd is actually $actual" "fail"
  fi
else
  check "passwd-perms.txt exists in $WORK_DIR" "fail"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
