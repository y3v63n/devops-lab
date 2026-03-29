# Server Health Checker

A command-line server health monitoring tool that generates comprehensive system reports.

Built as part of the [DevOps Lab](../../README.md) Module 0 Foundations Bootcamp.

## Features

- CPU load and usage reporting
- Memory utilization (used/total/percentage)
- Disk usage across all mounted filesystems
- Top processes by CPU and memory consumption
- Open listening ports
- Active systemd services count
- System uptime
- JSON output mode for integration with monitoring tools

## Usage

```bash
# Text report (default)
./health-check.sh

# JSON output
./health-check.sh --json

# Save report to file
./health-check.sh > report-$(date +%Y%m%d).txt
```

## Sample Output

```
═══════════════════════════════════════════
  SERVER HEALTH REPORT
  Host: myserver    Date: 2026-03-28
═══════════════════════════════════════════

── CPU ──────────────────────────────────
  Load Average: 0.52 0.48 0.45

── Memory ───────────────────────────────
  Used: 4.2Gi / 7.8Gi (54%)

── Disk ─────────────────────────────────
  /dev/sda1  50G  23G  25G  48%  /

── Top 5 by CPU ─────────────────────────
  PID   CPU%  COMMAND
  1234  12.3  node
  ...

── Open Ports ───────────────────────────
  22/tcp   sshd
  80/tcp   nginx
  ...

── Services ─────────────────────────────
  Active: 47

── Uptime ───────────────────────────────
  up 14 days, 3:22
═══════════════════════════════════════════
```

## Making This a Portfolio Piece

1. Add error handling for systems where commands may not be available
2. Add a `--watch` flag that refreshes every N seconds
3. Add threshold alerts (e.g., disk > 90% shows WARNING)
4. Set up a GitHub Actions CI workflow that runs shellcheck
5. Add a screenshot to this README

## Skills Demonstrated

- Bash scripting (functions, error handling, argument parsing)
- Linux system administration commands
- Text formatting and report generation
- JSON output for tool integration
