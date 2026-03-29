#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/0B-06"
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

echo "Verifying: 0B-06 Server Health Checker (Capstone)"
echo ""

SCRIPT="$WORK_DIR/health-check.sh"

if [[ ! -f "$SCRIPT" ]]; then
  echo "ERROR: $SCRIPT not found."
  echo ""
  echo "Results: 0 passed, 1 failed"
  exit 1
fi

# Check script structure
echo "Script structure:"
check "uses set -euo pipefail or set -e" \
  "$(grep -q 'set -e' "$SCRIPT" && echo pass || echo fail)"

check "uses at least one function definition" \
  "$(grep -qE '^\w+\(\)' "$SCRIPT" && echo pass || echo fail)"

check "uses trap" \
  "$(grep -q 'trap' "$SCRIPT" && echo pass || echo fail)"

check "handles --json flag" \
  "$(grep -q '\-\-json\|json' "$SCRIPT" && echo pass || echo fail)"

echo ""
echo "Text output (default mode):"

output=$(bash "$SCRIPT" 2>/dev/null)
exit_code=$?

check "script runs without error (exit 0)" \
  "$([[ $exit_code -eq 0 ]] && echo pass || echo fail)"

check "output contains hostname section" \
  "$(echo "$output" | grep -qi 'hostname\|host' && echo pass || echo fail)"

check "output contains uptime" \
  "$(echo "$output" | grep -qi 'uptime\|up ' && echo pass || echo fail)"

check "output contains CPU/load" \
  "$(echo "$output" | grep -qi 'cpu\|load' && echo pass || echo fail)"

check "output contains memory" \
  "$(echo "$output" | grep -qi 'mem\|memory' && echo pass || echo fail)"

check "output contains disk" \
  "$(echo "$output" | grep -qi 'disk\|filesystem\|df' && echo pass || echo fail)"

check "output contains process section" \
  "$(echo "$output" | grep -qi 'process\|cpu\|top' && echo pass || echo fail)"

check "output contains ports section" \
  "$(echo "$output" | grep -qi 'port\|listen\|socket' && echo pass || echo fail)"

check "output contains services section" \
  "$(echo "$output" | grep -qi 'service\|systemd\|systemctl' && echo pass || echo fail)"

echo ""
echo "JSON output (--json flag):"

json_output=$(bash "$SCRIPT" --json 2>/dev/null)
json_exit=$?

check "--json flag exits with code 0" \
  "$([[ $json_exit -eq 0 ]] && echo pass || echo fail)"

check "--json output starts with '{'" \
  "$(echo "$json_output" | grep -q '^{' && echo pass || echo fail)"

check "--json output ends with '}'" \
  "$(echo "$json_output" | tail -1 | grep -q '^}' && echo pass || echo fail)"

check "--json output contains 'hostname'" \
  "$(echo "$json_output" | grep -q '"hostname"' && echo pass || echo fail)"

check "--json output contains 'timestamp'" \
  "$(echo "$json_output" | grep -q '"timestamp"' && echo pass || echo fail)"

check "--json output contains load averages" \
  "$(echo "$json_output" | grep -q 'load' && echo pass || echo fail)"

check "--json output contains memory info" \
  "$(echo "$json_output" | grep -q 'mem' && echo pass || echo fail)"

# Validate JSON is parseable (if python3 or jq available)
if command -v python3 >/dev/null 2>&1; then
  echo "$json_output" | python3 -m json.tool >/dev/null 2>&1
  check "--json output is valid JSON (python3 validation)" \
    "$([[ $? -eq 0 ]] && echo pass || echo fail)"
elif command -v jq >/dev/null 2>&1; then
  echo "$json_output" | jq . >/dev/null 2>&1
  check "--json output is valid JSON (jq validation)" \
    "$([[ $? -eq 0 ]] && echo pass || echo fail)"
else
  check "--json output is valid JSON (skipped - no parser available)" pass
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
