# 0A-04: Finding Things

## Theory

Four commands form the core of Linux text processing: `find` traverses the filesystem tree looking for files by name, type, size, age, or permissions. `grep` searches file contents for lines matching a pattern (supporting basic regex, extended regex with `-E`, and fixed strings with `-F`). `awk` is a mini programming language for structured text — it splits each line into fields, lets you filter rows and transform columns, and is the right tool when you need to extract specific columns from output. `sed` is a stream editor — it applies substitutions and transformations to text as it flows through, ideal for find-and-replace in pipelines.

These tools become powerful in combination. A pipeline like `find /var/log -name "*.log" | xargs grep -l "ERROR"` finds every log file containing the word ERROR. `grep "ERROR" app.log | awk '{print $3}'` extracts a specific field from every error line. The pattern — find the right files, filter the right lines, extract the right fields — is how sysadmins and DevOps engineers investigate incidents from the command line. No GUI, no log aggregator required.

---

## Tasks

### Setup

Run `reset.sh` first — it creates sample files for you to search.

### Task 1: Find All Log Files

1. Use `find` to locate all `.log` files under the work directory:
   ```bash
   find /tmp/devops-lab/0A-04/ -name "*.log"
   ```

2. Write the paths to the output file:
   ```bash
   find /tmp/devops-lab/0A-04/ -name "*.log" > /tmp/devops-lab/0A-04/found-logs.txt
   ```

---

### Task 2: Extract ERROR Lines

1. Use `grep` to find all lines containing ERROR in the app log:
   ```bash
   grep "ERROR" /tmp/devops-lab/0A-04/logs/app.log
   ```

2. Write them to the output file:
   ```bash
   grep "ERROR" /tmp/devops-lab/0A-04/logs/app.log > /tmp/devops-lab/0A-04/errors.txt
   ```

---

### Task 3: Extract Error Codes with awk

1. Each ERROR line has the format: `TIMESTAMP LEVEL CODE message`. Use `awk` to extract the 3rd field (the error code):
   ```bash
   awk '{print $3}' /tmp/devops-lab/0A-04/errors.txt
   ```

2. Write the codes to the output file:
   ```bash
   awk '{print $3}' /tmp/devops-lab/0A-04/errors.txt > /tmp/devops-lab/0A-04/error-codes.txt
   ```

---

### Task 4: Find Large Files

1. Use `find` with the `-size` flag to find files larger than 100 bytes in the data directory:
   ```bash
   find /tmp/devops-lab/0A-04/data/ -size +100c
   ```
   (`c` = bytes; `k` = kilobytes; `M` = megabytes)

2. Write the paths to the output file:
   ```bash
   find /tmp/devops-lab/0A-04/data/ -size +100c > /tmp/devops-lab/0A-04/large-files.txt
   ```

---

> **Interview Q:** What's the difference between grep, egrep, and fgrep? When would you use each? What does `grep -r` do differently from piping `find` output to `grep`?

---

## What Just Happened

You just used the four core text-processing tools in a realistic workflow: locate files, filter relevant lines, extract specific fields. The `find` + `grep` + `awk` pipeline is how experienced engineers triage incidents without reaching for a GUI. When a service starts throwing errors at 3 AM, you SSH in and run exactly these commands.

`find -size +100c` demonstrates how `find` can filter on file attributes beyond just name — you can filter by modification time (`-mtime -1` for files changed in the last day), permissions (`-perm 644`), owner (`-user www-data`), or type (`-type f` for files, `-type d` for directories). Combined with `-exec` or `xargs`, find becomes the foundation of filesystem automation.
