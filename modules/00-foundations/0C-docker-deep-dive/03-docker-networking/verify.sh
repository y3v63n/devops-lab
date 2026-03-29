#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/0C-03"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then
    echo "  ✓ $desc"; PASS=$((PASS+1))
  else
    echo "  ✗ $desc"; FAIL=$((FAIL+1))
  fi
}

echo "Verifying: Exercise 0C-03 — Docker Networking"
echo ""

# Task 1: lab-net network exists
lab_net=$(docker network inspect lab-net --format "{{.Name}}" 2>/dev/null)
check "lab-net network exists" \
  "$([[ "$lab_net" == "lab-net" ]] && echo pass || echo fail)"

# Task 2: net-ping container is running on lab-net
ping_status=$(docker inspect --format "{{.State.Status}}" net-ping 2>/dev/null)
check "net-ping container is running" \
  "$([[ "$ping_status" == "running" ]] && echo pass || echo fail)"

ping_network=$(docker inspect --format "{{range \$k,\$v := .NetworkSettings.Networks}}{{\$k}}{{end}}" net-ping 2>/dev/null)
check "net-ping is on lab-net network" \
  "$([[ "$ping_network" == *"lab-net"* ]] && echo pass || echo fail)"

# Task 2: net-pong container is running on lab-net
pong_status=$(docker inspect --format "{{.State.Status}}" net-pong 2>/dev/null)
check "net-pong container is running" \
  "$([[ "$pong_status" == "running" ]] && echo pass || echo fail)"

pong_network=$(docker inspect --format "{{range \$k,\$v := .NetworkSettings.Networks}}{{\$k}}{{end}}" net-pong 2>/dev/null)
check "net-pong is on lab-net network" \
  "$([[ "$pong_network" == *"lab-net"* ]] && echo pass || echo fail)"

# Task 3: ping-result.txt exists and shows successful ping
if [[ -f "$WORK_DIR/ping-result.txt" ]]; then
  ping_content=$(cat "$WORK_DIR/ping-result.txt")
  check "ping-result.txt exists" "pass"
  check "ping-result.txt shows packets transmitted" \
    "$([[ "$ping_content" == *"packets transmitted"* ]] && echo pass || echo fail)"
  check "ping-result.txt shows 0 packet loss or successful replies" \
    "$([[ "$ping_content" == *"0% packet loss"* || "$ping_content" == *"bytes from"* ]] && echo pass || echo fail)"
else
  check "ping-result.txt exists" "fail"
  check "ping-result.txt shows packets transmitted" "fail"
  check "ping-result.txt shows 0 packet loss or successful replies" "fail"
fi

# Task 4: subnet.txt exists and contains a valid CIDR
if [[ -f "$WORK_DIR/subnet.txt" ]]; then
  subnet=$(cat "$WORK_DIR/subnet.txt" | tr -d '[:space:]')
  check "subnet.txt exists and is non-empty" \
    "$([[ -n "$subnet" ]] && echo pass || echo fail)"
  # Validate CIDR format: x.x.x.x/yy
  check "subnet.txt contains a valid CIDR notation" \
    "$([[ "$subnet" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]] && echo pass || echo fail)"
else
  check "subnet.txt exists and is non-empty" "fail"
  check "subnet.txt contains a valid CIDR notation" "fail"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
