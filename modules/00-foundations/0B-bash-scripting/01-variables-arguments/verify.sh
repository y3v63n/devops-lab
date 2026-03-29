#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/0B-01"
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

echo "Verifying: 0B-01 Variables and Arguments"
echo ""

# Task 1 — greet.sh
echo "Task 1: greet.sh"

if [[ -f "$WORK_DIR/greet.sh" ]]; then
  output=$(bash "$WORK_DIR/greet.sh" Alice 2>/dev/null)
  check "greet.sh Alice → 'Hello, Alice!'" \
    "$([[ "$output" == "Hello, Alice!" ]] && echo pass || echo fail)"

  output=$(bash "$WORK_DIR/greet.sh" 2>/dev/null)
  check "greet.sh (no arg) → 'Hello, World!'" \
    "$([[ "$output" == "Hello, World!" ]] && echo pass || echo fail)"

  bash "$WORK_DIR/greet.sh" >/dev/null 2>&1
  code=$?
  check "greet.sh (no arg) exits with code 1" \
    "$([[ "$code" -eq 1 ]] && echo pass || echo fail)"

  bash "$WORK_DIR/greet.sh" Alice >/dev/null 2>&1
  code=$?
  check "greet.sh Alice exits with code 0" \
    "$([[ "$code" -eq 0 ]] && echo pass || echo fail)"
else
  check "greet.sh exists" fail
  check "greet.sh Alice → 'Hello, Alice!'" fail
  check "greet.sh (no arg) → 'Hello, World!'" fail
  check "greet.sh (no arg) exits with code 1" fail
fi

echo ""
echo "Task 2: count-args.sh"

if [[ -f "$WORK_DIR/count-args.sh" ]]; then
  output=$(bash "$WORK_DIR/count-args.sh" a b c 2>/dev/null)
  check "count-args.sh a b c → 3" \
    "$([[ "$output" == "3" ]] && echo pass || echo fail)"

  output=$(bash "$WORK_DIR/count-args.sh" 2>/dev/null)
  check "count-args.sh (no args) → 0" \
    "$([[ "$output" == "0" ]] && echo pass || echo fail)"

  output=$(bash "$WORK_DIR/count-args.sh" "hello world" foo 2>/dev/null)
  check "count-args.sh 'hello world' foo → 2 (quoted arg counts as one)" \
    "$([[ "$output" == "2" ]] && echo pass || echo fail)"
else
  check "count-args.sh exists" fail
  check "count-args.sh a b c → 3" fail
  check "count-args.sh (no args) → 0" fail
fi

echo ""
echo "Task 3: exit-demo.sh"

if [[ -f "$WORK_DIR/exit-demo.sh" ]]; then
  bash "$WORK_DIR/exit-demo.sh" 42 >/dev/null 2>&1
  code=$?
  check "exit-demo.sh 42 exits with code 42" \
    "$([[ "$code" -eq 42 ]] && echo pass || echo fail)"

  bash "$WORK_DIR/exit-demo.sh" 0 >/dev/null 2>&1
  code=$?
  check "exit-demo.sh 0 exits with code 0" \
    "$([[ "$code" -eq 0 ]] && echo pass || echo fail)"

  bash "$WORK_DIR/exit-demo.sh" >/dev/null 2>&1
  code=$?
  check "exit-demo.sh (no arg) exits with code 0" \
    "$([[ "$code" -eq 0 ]] && echo pass || echo fail)"

  bash "$WORK_DIR/exit-demo.sh" 7 >/dev/null 2>&1
  code=$?
  check "exit-demo.sh 7 exits with code 7" \
    "$([[ "$code" -eq 7 ]] && echo pass || echo fail)"
else
  check "exit-demo.sh exists" fail
  check "exit-demo.sh 42 exits with code 42" fail
  check "exit-demo.sh (no arg) exits with code 0" fail
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
