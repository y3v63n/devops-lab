# Exercise 0B-06: Server Health Checker (Capstone)

## Putting It All Together

This capstone exercise combines everything from the module: variables, conditionals, loops, functions, file processing, and error handling. Real DevOps work involves writing production scripts that run unattended on servers, so this one must be robust: proper error handling, no hardcoded paths, and clean output that both humans and machines can parse. Production scripts also need to handle edge cases — what if a command doesn't exist on this system? What if a filesystem is tmpfs? The `--json` flag demonstrates a common pattern: the same script serves both human operators and automation pipelines.

## System Information Sources

Linux exposes system state through files in `/proc` and via standard utilities. `/proc/loadavg` has the load averages. `free -h` shows memory. `df -h` shows disk. `top -bn1` and `ps aux` list processes. `ss -tlnp` (socket statistics) shows listening ports, replacing the older `netstat`. `systemctl list-units` lists systemd services. All of these output to stdout and exit 0 on success — they're composable with pipes. The key skill is knowing which tool to reach for and how to extract the specific fields you need.

## JSON Output Pattern

Many scripts need dual output modes: human-readable text for terminals, machine-readable JSON for monitoring systems. A common pattern is to collect all values into variables first, then at the end format them as either text or JSON based on a flag. For JSON, `printf` with careful quoting works fine for simple structures — you don't need `jq` to write JSON. For complex structures, consider building the JSON incrementally or using `jq --null-input` to construct it safely.

---

## Task

Write `/tmp/devops-lab/0B-06/health-check.sh` — a complete server health checker.

**Requirements:**

1. Uses `set -euo pipefail` and proper error handling
2. Uses functions (at minimum one function per section)
3. Collects and displays all of the following:
   - **System**: hostname and current date/time
   - **Uptime**: system uptime
   - **CPU**: load averages (1, 5, 15 minute) from `/proc/loadavg`
   - **Memory**: used, total, and percentage (from `free`)
   - **Disk**: all mounted filesystems with usage (from `df -h`), skip trivial ones
   - **Top Processes (CPU)**: top 5 processes by CPU usage
   - **Top Processes (Memory)**: top 5 processes by memory usage
   - **Listening Ports**: open TCP listening ports (from `ss -tlnp`)
   - **Systemd Services**: count of active running services
4. Section headers clearly label each section
5. Accepts a `--json` flag: when passed, outputs a JSON object instead of text
   - JSON must include at minimum: `hostname`, `uptime`, `load_1m`, `load_5m`, `load_15m`, `mem_used`, `mem_total`, `timestamp`

**Usage:**
```bash
bash /tmp/devops-lab/0B-06/health-check.sh           # human-readable output
bash /tmp/devops-lab/0B-06/health-check.sh --json    # JSON output
```

---

> **Interview Q:** You need to monitor 50 servers. How would you distribute and schedule this script? What would you do with the output?

---

## What Just Happened

You built a production-grade monitoring tool from scratch using only bash and standard Linux utilities. The functions made each section independently testable and readable. `set -euo pipefail` ensures the script never silently produces partial output. The `--json` flag demonstrates a principle used throughout the industry: the same data collection logic serves both humans and machines by changing only the formatting layer. This script is now a portfolio piece — it demonstrates systems knowledge (knowing what to measure), bash proficiency (functions, error handling, argument parsing), and operational thinking (what does an on-call engineer need to see?).
