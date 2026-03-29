# 0A-07: System Logs

## Theory

Linux systems generate a continuous stream of log events — kernel messages, service start/stop events, authentication attempts, application errors. The traditional log system writes to files in `/var/log/` (syslog, auth.log, kern.log). Modern Linux systems use **systemd-journald**, which collects all of these into a structured binary journal and exposes them through **`journalctl`**. The journal is indexed and queryable — you can filter by service, priority level, time range, or boot session without grepping raw text files.

Log **priority levels** follow the syslog scale: `emerg` (0) > `alert` (1) > `crit` (2) > `err` (3) > `warning` (4) > `notice` (5) > `info` (6) > `debug` (7). When you filter with `journalctl -p err`, you get all messages at err priority and above (err, crit, alert, emerg). In production, you'd typically forward these to a centralized log aggregator (Splunk, Elasticsearch, CloudWatch) — but when you're SSH'd into a machine at 3 AM, `journalctl` is your first tool.

---

## Tasks

### Task 1: Find Recent SSH Log Entries

1. Create your work directory:
   ```bash
   mkdir -p /tmp/devops-lab/0A-07
   ```

2. Use `journalctl` to find SSH-related log entries:
   ```bash
   journalctl -u ssh -u sshd -n 10 --no-pager
   ```
   (Try `-u ssh` first; use `-u sshd` if that returns nothing)

3. Write the 10 most recent entries to the file:
   ```bash
   journalctl -u ssh --no-pager -n 10 > /tmp/devops-lab/0A-07/ssh-logs.txt
   # If ssh unit not found, try sshd:
   journalctl -u sshd --no-pager -n 10 > /tmp/devops-lab/0A-07/ssh-logs.txt
   ```

---

### Task 2: Find Error-Level Entries from Today

1. Use `journalctl` to show all error (and above) messages from today:
   ```bash
   journalctl -p err --since today --no-pager
   ```

2. Write the output to the file:
   ```bash
   journalctl -p err --since today --no-pager > /tmp/devops-lab/0A-07/errors-today.txt
   ```

---

### Task 3: Find the Last Boot Timestamp

1. Use `who -b` to get the last boot time:
   ```bash
   who -b
   ```
   Or use journalctl's boot list:
   ```bash
   journalctl --list-boots --no-pager
   ```

2. Write the timestamp to the file:
   ```bash
   who -b | awk '{print $3, $4}' > /tmp/devops-lab/0A-07/last-boot.txt
   ```

---

### Task 4: Count Unique Services with Errors Today

1. Get all error entries from today and extract service names:
   ```bash
   journalctl -p err --since today --no-pager -o short-unix | awk '{print $5}' | sort -u
   ```
   Or use the `_SYSTEMD_UNIT` field approach:
   ```bash
   journalctl -p err --since today --no-pager | grep -oP '(?<=\s)\w+\.service' | sort -u | wc -l
   ```

2. Write just the count (a number) to the file:
   ```bash
   echo "3" > /tmp/devops-lab/0A-07/error-service-count.txt
   ```

---

> **Interview Q:** A service crashed at 3 AM. How would you investigate what happened using only system logs? Walk through the exact journalctl commands you'd run and what you'd look for.

---

## What Just Happened

You just used journalctl to navigate your system's logs in four different ways: by unit (service), by priority, by time, and in aggregate. This mirrors exactly how incident investigation works — you start broad (all errors today) then narrow down to specific services or time windows. The `--since` and `--until` flags let you isolate the exact time window of an incident. The `-u service-name` flag lets you follow a single service's history.

The `who -b` command is a quick sanity check: if a server "rebooted by itself," the boot timestamp tells you exactly when it happened and you can cross-reference that with error logs from just before the reboot to find the cause. These tools together let you reconstruct exactly what happened on a system, even hours or days after an incident.
