## Hints

### Task 1: Find SSH log entries
- `journalctl -u ssh` shows logs for the `ssh` systemd unit
- If that returns no entries, try `journalctl -u sshd`
- `-n 10` limits to the last 10 entries
- `--no-pager` prevents interactive scrolling (needed for redirecting to file)
- Full command: `journalctl -u sshd -n 10 --no-pager > /tmp/devops-lab/0A-07/ssh-logs.txt`

### Task 2: Find errors from today
- `journalctl -p err` filters by priority "err" and above (err, crit, alert, emerg)
- `--since today` means since midnight today
- `--no-pager` prevents pager
- Full command: `journalctl -p err --since today --no-pager > /tmp/devops-lab/0A-07/errors-today.txt`
- The file may be short if there are few errors — that's fine

### Task 3: Find the last boot timestamp
- `who -b` is the simplest: prints "system boot YYYY-MM-DD HH:MM"
- Extract just the date and time: `who -b | awk '{print $3, $4}'`
- Alternative: `journalctl --list-boots --no-pager | head -3`
- Write to file: `who -b | awk '{print $3, $4}' > /tmp/devops-lab/0A-07/last-boot.txt`

### Task 4: Count unique services with errors today
Step 1: Get all errors from today:
```bash
journalctl -p err --since today --no-pager
```

Step 2: Extract service/unit names from the output. Journal lines look like:
`Mar 15 09:23:11 hostname servicename[pid]: message`
The 5th field is the service identifier.

Step 3: Count unique services:
```bash
journalctl -p err --since today --no-pager | awk '{print $5}' | sort -u | grep -v "^$" | wc -l
```

Step 4: Write the count:
```bash
COUNT=$(journalctl -p err --since today --no-pager | awk '{print $5}' | sort -u | grep -v "^$" | wc -l)
echo "$COUNT" > /tmp/devops-lab/0A-07/error-service-count.txt
```
