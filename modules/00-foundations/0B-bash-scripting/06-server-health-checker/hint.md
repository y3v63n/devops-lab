# Hints — 0B-06: Server Health Checker

## Getting Started

**Hint 1:** Set up the skeleton first:
```bash
#!/usr/bin/env bash
set -euo pipefail

JSON_MODE=false
[[ "${1:-}" == "--json" ]] && JSON_MODE=true

# Functions for each section...

main() {
  if $JSON_MODE; then
    output_json
  else
    output_text
  fi
}

main
```

---

## Collecting System Data

**Hint 2 — Hostname and date:**
```bash
HOSTNAME_VAL=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
```

**Hint 3 — Uptime:**
```bash
UPTIME=$(uptime -p 2>/dev/null || uptime)
```

**Hint 4 — Load averages from /proc/loadavg:**
```bash
read -r LOAD1 LOAD5 LOAD15 _ < /proc/loadavg
```

**Hint 5 — Memory with `free`:**
```bash
# free -m gives megabytes; parse with awk
MEM_TOTAL=$(free -m | awk '/^Mem:/ { print $2 }')
MEM_USED=$(free -m  | awk '/^Mem:/ { print $3 }')
MEM_PCT=$(( MEM_USED * 100 / MEM_TOTAL ))
```

**Hint 6 — Disk usage:**
```bash
df -h --output=target,size,used,pcent | grep -v tmpfs
```

**Hint 7 — Top 5 processes by CPU:**
```bash
ps aux --sort=-%cpu | head -6 | tail -5
```

**Hint 8 — Top 5 processes by memory:**
```bash
ps aux --sort=-%mem | head -6 | tail -5
```

**Hint 9 — Listening ports:**
```bash
ss -tlnp 2>/dev/null || netstat -tlnp 2>/dev/null
```

**Hint 10 — Active systemd service count:**
```bash
systemctl list-units --type=service --state=running --no-legend 2>/dev/null | wc -l
```

---

## Text Output Structure

**Hint 11:** Use a separator function for clean headers:
```bash
header() {
  echo ""
  echo "=== $1 ==="
}
```

Then in your text output function:
```bash
output_text() {
  header "SYSTEM"
  echo "Hostname : $HOSTNAME_VAL"
  echo "Time     : $TIMESTAMP"
  header "CPU LOAD"
  echo "1m: $LOAD1  5m: $LOAD5  15m: $LOAD15"
  # ... etc
}
```

---

## JSON Output

**Hint 12:** Build JSON with printf:
```bash
output_json() {
  printf '{\n'
  printf '  "hostname": "%s",\n' "$HOSTNAME_VAL"
  printf '  "timestamp": "%s",\n' "$TIMESTAMP"
  printf '  "uptime": "%s",\n' "$UPTIME"
  printf '  "load_1m": "%s",\n' "$LOAD1"
  printf '  "load_5m": "%s",\n' "$LOAD5"
  printf '  "load_15m": "%s",\n' "$LOAD15"
  printf '  "mem_used_mb": "%s",\n' "$MEM_USED"
  printf '  "mem_total_mb": "%s",\n' "$MEM_TOTAL"
  printf '  "mem_pct": "%s"\n' "$MEM_PCT"
  printf '}\n'
}
```

Note: the last key before `}` must not have a trailing comma.

---

## Error Handling

**Hint 13:** Use a trap for any cleanup and to catch errors gracefully:
```bash
trap 'echo "Error on line $LINENO" >&2' ERR
```

**Hint 14:** For commands that might not exist on all systems, use:
```bash
if command -v ss >/dev/null 2>&1; then
  ss -tlnp
else
  echo "ss not available"
fi
```

---

## Tips

- Build one function at a time, test it, then add the next
- `bash -x health-check.sh` shows every command as it executes (debug mode)
- `man free`, `man df`, `man ps`, `man ss` — all have many useful flags
- Run `bash --posix` to check if you've used any non-POSIX features by accident
