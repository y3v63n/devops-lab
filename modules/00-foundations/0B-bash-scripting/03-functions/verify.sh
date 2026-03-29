#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/0B-03"
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

echo "Verifying: 0B-03 Functions"
echo ""

# Task 1 — mathlib.sh
echo "Task 1: mathlib.sh"

if [[ -f "$WORK_DIR/mathlib.sh" ]]; then
  # Source in a subshell to isolate
  out=$(bash -c "source '$WORK_DIR/mathlib.sh'; add 3 4" 2>/dev/null)
  check "add 3 4 → 7" "$([[ "$out" == "7" ]] && echo pass || echo fail)"

  out=$(bash -c "source '$WORK_DIR/mathlib.sh'; add 0 0" 2>/dev/null)
  check "add 0 0 → 0" "$([[ "$out" == "0" ]] && echo pass || echo fail)"

  out=$(bash -c "source '$WORK_DIR/mathlib.sh'; subtract 10 3" 2>/dev/null)
  check "subtract 10 3 → 7" "$([[ "$out" == "7" ]] && echo pass || echo fail)"

  out=$(bash -c "source '$WORK_DIR/mathlib.sh'; subtract 5 8" 2>/dev/null)
  check "subtract 5 8 → -3" "$([[ "$out" == "-3" ]] && echo pass || echo fail)"

  out=$(bash -c "source '$WORK_DIR/mathlib.sh'; multiply 4 5" 2>/dev/null)
  check "multiply 4 5 → 20" "$([[ "$out" == "20" ]] && echo pass || echo fail)"

  out=$(bash -c "source '$WORK_DIR/mathlib.sh'; multiply 6 7" 2>/dev/null)
  check "multiply 6 7 → 42" "$([[ "$out" == "42" ]] && echo pass || echo fail)"
else
  check "mathlib.sh exists" fail
  check "add 3 4 → 7" fail
  check "subtract 10 3 → 7" fail
  check "multiply 4 5 → 20" fail
fi

echo ""
echo "Task 2: validate.sh"

if [[ -f "$WORK_DIR/validate.sh" ]]; then
  bash -c "source '$WORK_DIR/validate.sh'; is_valid_ip '192.168.1.1'" >/dev/null 2>&1
  check "is_valid_ip '192.168.1.1' → exit 0" \
    "$([[ $? -eq 0 ]] && echo pass || echo fail)"

  bash -c "source '$WORK_DIR/validate.sh'; is_valid_ip '10.0.0.1'" >/dev/null 2>&1
  check "is_valid_ip '10.0.0.1' → exit 0" \
    "$([[ $? -eq 0 ]] && echo pass || echo fail)"

  bash -c "source '$WORK_DIR/validate.sh'; is_valid_ip '0.0.0.0'" >/dev/null 2>&1
  check "is_valid_ip '0.0.0.0' → exit 0" \
    "$([[ $? -eq 0 ]] && echo pass || echo fail)"

  bash -c "source '$WORK_DIR/validate.sh'; is_valid_ip '255.255.255.255'" >/dev/null 2>&1
  check "is_valid_ip '255.255.255.255' → exit 0" \
    "$([[ $? -eq 0 ]] && echo pass || echo fail)"

  bash -c "source '$WORK_DIR/validate.sh'; is_valid_ip '256.0.0.1'" >/dev/null 2>&1
  check "is_valid_ip '256.0.0.1' → exit 1" \
    "$([[ $? -ne 0 ]] && echo pass || echo fail)"

  bash -c "source '$WORK_DIR/validate.sh'; is_valid_ip 'not-an-ip'" >/dev/null 2>&1
  check "is_valid_ip 'not-an-ip' → exit 1" \
    "$([[ $? -ne 0 ]] && echo pass || echo fail)"

  bash -c "source '$WORK_DIR/validate.sh'; is_valid_ip '192.168.1'" >/dev/null 2>&1
  check "is_valid_ip '192.168.1' (3 octets) → exit 1" \
    "$([[ $? -ne 0 ]] && echo pass || echo fail)"
else
  check "validate.sh exists" fail
  check "is_valid_ip '192.168.1.1' → exit 0" fail
  check "is_valid_ip '256.0.0.1' → exit 1" fail
  check "is_valid_ip 'not-an-ip' → exit 1" fail
fi

echo ""
echo "Task 3: string-utils.sh"

if [[ -f "$WORK_DIR/string-utils.sh" ]]; then
  out=$(bash -c "source '$WORK_DIR/string-utils.sh'; to_upper 'hello'" 2>/dev/null)
  check "to_upper 'hello' → 'HELLO'" \
    "$([[ "$out" == "HELLO" ]] && echo pass || echo fail)"

  out=$(bash -c "source '$WORK_DIR/string-utils.sh'; to_upper 'DevOps'" 2>/dev/null)
  check "to_upper 'DevOps' → 'DEVOPS'" \
    "$([[ "$out" == "DEVOPS" ]] && echo pass || echo fail)"

  out=$(bash -c "source '$WORK_DIR/string-utils.sh'; to_lower 'WORLD'" 2>/dev/null)
  check "to_lower 'WORLD' → 'world'" \
    "$([[ "$out" == "world" ]] && echo pass || echo fail)"

  out=$(bash -c "source '$WORK_DIR/string-utils.sh'; to_lower 'BaSH'" 2>/dev/null)
  check "to_lower 'BaSH' → 'bash'" \
    "$([[ "$out" == "bash" ]] && echo pass || echo fail)"

  out=$(bash -c "source '$WORK_DIR/string-utils.sh'; str_length 'devops'" 2>/dev/null)
  check "str_length 'devops' → 6" \
    "$([[ "$out" == "6" ]] && echo pass || echo fail)"

  out=$(bash -c "source '$WORK_DIR/string-utils.sh'; str_length ''" 2>/dev/null)
  check "str_length '' → 0" \
    "$([[ "$out" == "0" ]] && echo pass || echo fail)"
else
  check "string-utils.sh exists" fail
  check "to_upper 'hello' → 'HELLO'" fail
  check "to_lower 'WORLD' → 'world'" fail
  check "str_length 'devops' → 6" fail
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
