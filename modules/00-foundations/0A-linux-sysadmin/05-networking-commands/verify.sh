#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/0A-05"
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

echo "Verifying: Networking Commands"
echo ""

# Check 1: listening-ports.txt is non-empty and contains ss header or port info
if [[ -f "$WORK_DIR/listening-ports.txt" ]]; then
  if [[ -s "$WORK_DIR/listening-ports.txt" ]]; then
    if grep -qiE "(State|LISTEN|Local Address)" "$WORK_DIR/listening-ports.txt"; then
      check "listening-ports.txt contains ss -tlnp output" "pass"
    else
      check "listening-ports.txt should contain ss output (missing headers/LISTEN state)" "fail"
    fi
  else
    check "listening-ports.txt is empty — run ss -tlnp and redirect output" "fail"
  fi
else
  check "listening-ports.txt exists in $WORK_DIR" "fail"
fi

# Check 2: my-ip.txt contains a valid non-loopback IP address
if [[ -f "$WORK_DIR/my-ip.txt" ]]; then
  recorded_ip=$(cat "$WORK_DIR/my-ip.txt" | tr -d '[:space:]')
  # Validate it looks like an IPv4 address
  if [[ "$recorded_ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    if [[ "$recorded_ip" == "127.0.0.1" ]]; then
      check "my-ip.txt should NOT be 127.0.0.1 (loopback) — find your real IP" "fail"
    else
      # Verify this IP actually exists on the system
      if ip addr show | grep -q "$recorded_ip"; then
        check "my-ip.txt contains valid system IP: $recorded_ip" "pass"
      else
        check "my-ip.txt has $recorded_ip but this IP is not assigned to any interface" "fail"
      fi
    fi
  else
    check "my-ip.txt should contain an IP address (x.x.x.x), got: '$recorded_ip'" "fail"
  fi
else
  check "my-ip.txt exists in $WORK_DIR" "fail"
fi

# Check 3: gateway.txt contains the actual default gateway
if [[ -f "$WORK_DIR/gateway.txt" ]]; then
  recorded_gw=$(cat "$WORK_DIR/gateway.txt" | tr -d '[:space:]')
  actual_gw=$(ip route | grep "^default" | awk '{print $3}' | head -1)
  if [[ -z "$actual_gw" ]]; then
    # No default gateway exists — accept any IP-looking value
    if [[ "$recorded_gw" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
      check "gateway.txt contains an IP (no default route detected on system)" "pass"
    else
      check "gateway.txt should contain a gateway IP address" "fail"
    fi
  else
    if [[ "$recorded_gw" == "$actual_gw" ]]; then
      check "gateway.txt correctly identifies default gateway: $recorded_gw" "pass"
    else
      check "gateway.txt has '$recorded_gw' but actual default gateway is '$actual_gw'" "fail"
    fi
  fi
else
  check "gateway.txt exists in $WORK_DIR" "fail"
fi

# Check 4: port22-process.txt contains a process name (sshd or similar)
if [[ -f "$WORK_DIR/port22-process.txt" ]]; then
  proc=$(cat "$WORK_DIR/port22-process.txt" | tr -d '[:space:]')
  if [[ -n "$proc" ]]; then
    # Verify against what ss actually shows
    actual_proc=$(ss -tlnp | grep ":22 " | grep -oP 'users:\(\("?\K[^",]+' | head -1)
    if [[ -z "$actual_proc" ]]; then
      # Port 22 not listening, accept any reasonable answer
      check "port22-process.txt has value '$proc' (port 22 not detected as listening)" "pass"
    elif [[ "$proc" == "$actual_proc" ]] || [[ "$actual_proc" == *"$proc"* ]]; then
      check "port22-process.txt correctly identifies process: $proc" "pass"
    else
      check "port22-process.txt has '$proc' but ss shows '$actual_proc' on port 22" "fail"
    fi
  else
    check "port22-process.txt is empty — write the process name" "fail"
  fi
else
  check "port22-process.txt exists in $WORK_DIR" "fail"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
