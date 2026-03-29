#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/0B-04"
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

echo "Verifying: 0B-04 File Processing"
echo ""

# Ensure CSV exists
if [[ ! -f "$WORK_DIR/servers.csv" ]]; then
  echo "ERROR: $WORK_DIR/servers.csv not found. Run reset.sh first."
  exit 1
fi

# Task 1 — active-hosts.txt
echo "Task 1: active-hosts.txt"

if [[ -f "$WORK_DIR/active-hosts.txt" ]]; then
  # Active servers: web-01, web-02, db-01, cache-01, api-01 (not db-02 maintenance, not api-02 inactive)
  check "active-hosts.txt contains web-01" \
    "$(grep -q '^web-01$' "$WORK_DIR/active-hosts.txt" && echo pass || echo fail)"
  check "active-hosts.txt contains web-02" \
    "$(grep -q '^web-02$' "$WORK_DIR/active-hosts.txt" && echo pass || echo fail)"
  check "active-hosts.txt contains db-01" \
    "$(grep -q '^db-01$' "$WORK_DIR/active-hosts.txt" && echo pass || echo fail)"
  check "active-hosts.txt contains cache-01" \
    "$(grep -q '^cache-01$' "$WORK_DIR/active-hosts.txt" && echo pass || echo fail)"
  check "active-hosts.txt contains api-01" \
    "$(grep -q '^api-01$' "$WORK_DIR/active-hosts.txt" && echo pass || echo fail)"
  check "active-hosts.txt does NOT contain db-02 (maintenance)" \
    "$(grep -q '^db-02$' "$WORK_DIR/active-hosts.txt" && echo fail || echo pass)"
  check "active-hosts.txt does NOT contain api-02 (inactive)" \
    "$(grep -q '^api-02$' "$WORK_DIR/active-hosts.txt" && echo fail || echo pass)"
  count=$(grep -c '.' "$WORK_DIR/active-hosts.txt" 2>/dev/null || echo 0)
  check "active-hosts.txt has exactly 5 lines" \
    "$([[ "$count" -eq 5 ]] && echo pass || echo fail)"
else
  check "active-hosts.txt exists" fail
  check "active-hosts.txt contains web-01" fail
  check "active-hosts.txt contains db-01" fail
  check "active-hosts.txt does not contain db-02" fail
fi

echo ""
echo "Task 2: role-counts.txt"

if [[ -f "$WORK_DIR/role-counts.txt" ]]; then
  # Expected: frontend:2, database:2, cache:1, backend:2
  check "role-counts.txt: frontend: 2" \
    "$(grep -q 'frontend.*2\|2.*frontend' "$WORK_DIR/role-counts.txt" && echo pass || echo fail)"
  check "role-counts.txt: database: 2" \
    "$(grep -q 'database.*2\|2.*database' "$WORK_DIR/role-counts.txt" && echo pass || echo fail)"
  check "role-counts.txt: cache: 1" \
    "$(grep -q 'cache.*1\|1.*cache' "$WORK_DIR/role-counts.txt" && echo pass || echo fail)"
  check "role-counts.txt: backend: 2" \
    "$(grep -q 'backend.*2\|2.*backend' "$WORK_DIR/role-counts.txt" && echo pass || echo fail)"
else
  check "role-counts.txt exists" fail
  check "role-counts.txt: frontend: 2" fail
  check "role-counts.txt: database: 2" fail
  check "role-counts.txt: cache: 1" fail
fi

echo ""
echo "Task 3: subnet-ips.txt"

if [[ -f "$WORK_DIR/subnet-ips.txt" ]]; then
  # 10.0.1.x IPs: 10.0.1.10, 10.0.1.11, 10.0.1.20, 10.0.1.21
  check "subnet-ips.txt contains 10.0.1.10" \
    "$(grep -q '10\.0\.1\.10' "$WORK_DIR/subnet-ips.txt" && echo pass || echo fail)"
  check "subnet-ips.txt contains 10.0.1.11" \
    "$(grep -q '10\.0\.1\.11' "$WORK_DIR/subnet-ips.txt" && echo pass || echo fail)"
  check "subnet-ips.txt contains 10.0.1.20" \
    "$(grep -q '10\.0\.1\.20' "$WORK_DIR/subnet-ips.txt" && echo pass || echo fail)"
  check "subnet-ips.txt contains 10.0.1.21" \
    "$(grep -q '10\.0\.1\.21' "$WORK_DIR/subnet-ips.txt" && echo pass || echo fail)"
  check "subnet-ips.txt does NOT contain 10.0.2.x IPs" \
    "$(grep -q '10\.0\.2\.' "$WORK_DIR/subnet-ips.txt" && echo fail || echo pass)"
  check "subnet-ips.txt does NOT contain 10.0.3.x IPs" \
    "$(grep -q '10\.0\.3\.' "$WORK_DIR/subnet-ips.txt" && echo fail || echo pass)"
  count=$(grep -c '.' "$WORK_DIR/subnet-ips.txt" 2>/dev/null || echo 0)
  check "subnet-ips.txt has exactly 4 entries" \
    "$([[ "$count" -eq 4 ]] && echo pass || echo fail)"
else
  check "subnet-ips.txt exists" fail
  check "subnet-ips.txt contains 10.0.1.10" fail
  check "subnet-ips.txt does not contain 10.0.2.x" fail
fi

echo ""
echo "Task 4: process-csv.sh"

if [[ -f "$WORK_DIR/process-csv.sh" ]]; then
  output=$(bash "$WORK_DIR/process-csv.sh" 2>/dev/null)
  check "process-csv.sh runs without error" \
    "$([[ $? -eq 0 ]] && echo pass || echo fail)"

  check "output contains web-01" \
    "$(echo "$output" | grep -q 'web-01' && echo pass || echo fail)"
  check "output contains 10.0.1.10" \
    "$(echo "$output" | grep -q '10\.0\.1\.10' && echo pass || echo fail)"
  check "output contains api-02" \
    "$(echo "$output" | grep -q 'api-02' && echo pass || echo fail)"

  # Header should NOT appear (or if it does, that's fine, just check data rows)
  line_count=$(echo "$output" | grep -c '\.' 2>/dev/null || echo 0)
  check "output contains at least 7 lines (all data rows)" \
    "$([[ "$line_count" -ge 7 ]] && echo pass || echo fail)"
else
  check "process-csv.sh exists" fail
  check "process-csv.sh runs without error" fail
  check "output contains web-01" fail
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
