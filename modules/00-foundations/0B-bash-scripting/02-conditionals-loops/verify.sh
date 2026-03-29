#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/0B-02"
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

echo "Verifying: 0B-02 Conditionals and Loops"
echo ""

# Task 1 — classify.sh
echo "Task 1: classify.sh"

if [[ -f "$WORK_DIR/classify.sh" ]]; then
  out=$(bash "$WORK_DIR/classify.sh" 5 2>/dev/null)
  check "classify.sh 5 → 'positive'" \
    "$([[ "$out" == "positive" ]] && echo pass || echo fail)"

  out=$(bash "$WORK_DIR/classify.sh" -3 2>/dev/null)
  check "classify.sh -3 → 'negative'" \
    "$([[ "$out" == "negative" ]] && echo pass || echo fail)"

  out=$(bash "$WORK_DIR/classify.sh" 0 2>/dev/null)
  check "classify.sh 0 → 'zero'" \
    "$([[ "$out" == "zero" ]] && echo pass || echo fail)"

  out=$(bash "$WORK_DIR/classify.sh" 100 2>/dev/null)
  check "classify.sh 100 → 'positive'" \
    "$([[ "$out" == "positive" ]] && echo pass || echo fail)"
else
  check "classify.sh exists" fail
  check "classify.sh 5 → positive" fail
  check "classify.sh -3 → negative" fail
  check "classify.sh 0 → zero" fail
fi

echo ""
echo "Task 2: fizzbuzz.sh"

if [[ -f "$WORK_DIR/fizzbuzz.sh" ]]; then
  output=$(bash "$WORK_DIR/fizzbuzz.sh" 2>/dev/null)

  check "fizzbuzz: line 1 is '1'" \
    "$([[ "$(echo "$output" | sed -n '1p')" == "1" ]] && echo pass || echo fail)"

  check "fizzbuzz: line 3 is 'Fizz'" \
    "$([[ "$(echo "$output" | sed -n '3p')" == "Fizz" ]] && echo pass || echo fail)"

  check "fizzbuzz: line 5 is 'Buzz'" \
    "$([[ "$(echo "$output" | sed -n '5p')" == "Buzz" ]] && echo pass || echo fail)"

  check "fizzbuzz: line 15 is 'FizzBuzz'" \
    "$([[ "$(echo "$output" | sed -n '15p')" == "FizzBuzz" ]] && echo pass || echo fail)"

  check "fizzbuzz: line 30 is 'FizzBuzz'" \
    "$([[ "$(echo "$output" | sed -n '30p')" == "FizzBuzz" ]] && echo pass || echo fail)"

  line_count=$(echo "$output" | wc -l)
  check "fizzbuzz: produces exactly 30 lines" \
    "$([[ "$line_count" -eq 30 ]] && echo pass || echo fail)"
else
  check "fizzbuzz.sh exists" fail
  check "fizzbuzz line 3 is Fizz" fail
  check "fizzbuzz line 5 is Buzz" fail
  check "fizzbuzz line 15 is FizzBuzz" fail
  check "fizzbuzz produces 30 lines" fail
fi

echo ""
echo "Task 3: countdown.sh"

if [[ -f "$WORK_DIR/countdown.sh" ]]; then
  output=$(bash "$WORK_DIR/countdown.sh" 5 2>/dev/null)
  expected=$'5\n4\n3\n2\n1\n0'
  check "countdown.sh 5 → 5 4 3 2 1 0" \
    "$([[ "$output" == "$expected" ]] && echo pass || echo fail)"

  output=$(bash "$WORK_DIR/countdown.sh" 0 2>/dev/null)
  check "countdown.sh 0 → just '0'" \
    "$([[ "$output" == "0" ]] && echo pass || echo fail)"

  output=$(bash "$WORK_DIR/countdown.sh" 3 2>/dev/null)
  first=$(echo "$output" | head -1)
  last=$(echo "$output" | tail -1)
  check "countdown.sh 3 starts at 3" \
    "$([[ "$first" == "3" ]] && echo pass || echo fail)"
  check "countdown.sh 3 ends at 0" \
    "$([[ "$last" == "0" ]] && echo pass || echo fail)"
else
  check "countdown.sh exists" fail
  check "countdown.sh 5 → 5 4 3 2 1 0" fail
  check "countdown.sh 0 → 0" fail
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
