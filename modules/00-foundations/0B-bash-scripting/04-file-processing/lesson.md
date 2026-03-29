# Exercise 0B-04: File Processing

## Text Processing Tools

Linux ships powerful text tools designed to work together via pipes. `grep` filters lines by pattern. `awk` splits each line into fields (`$1`, `$2`, ...) and lets you act on them — it's the go-to for CSV-like processing. `cut` extracts specific columns from delimited files. `sort` and `uniq -c` together count occurrences. `wc -l` counts lines. Learn these tools deeply — they process gigabytes without loading data into memory, which is critical for log analysis and data pipelines.

## Reading Files Line by Line

`while IFS= read -r line; do ... done < file` is the correct pattern for processing a file line by line in bash. The `IFS=` prevents leading/trailing whitespace from being stripped. The `-r` flag prevents backslash interpretation. Avoid `for line in $(cat file)` — it splits on all whitespace (not just newlines), breaks on filenames with spaces, and is slower because it loads the whole file into memory first.

## Field Extraction and Filtering

For CSV processing, `awk -F','` sets the field separator to comma. `awk -F',' '$4 == "active"'` filters rows where the 4th column is "active". Combining `awk`, `sort`, and `uniq -c` gives you group-and-count operations similar to SQL's `GROUP BY`. For formatted table output, `column -t` aligns columns automatically, or use `printf "%-15s %-10s\n"` for fixed-width formatting.

---

## Setup

Your `reset.sh` creates `/tmp/devops-lab/0B-04/servers.csv` with server inventory data. Run it before starting.

---

## Tasks

Work from the data in `/tmp/devops-lab/0B-04/servers.csv`.

### Task 1 — Active hosts
Extract the hostnames of all servers with status `active`. Write them to `/tmp/devops-lab/0B-04/active-hosts.txt`, one hostname per line (no header).

### Task 2 — Role counts
Count how many servers exist in each role. Write to `/tmp/devops-lab/0B-04/role-counts.txt` in the format:
```
frontend: 2
database: 2
cache: 1
backend: 2
```
(order does not need to match exactly)

### Task 3 — Subnet filter
Extract all IP addresses in the `10.0.1.x` subnet. Write to `/tmp/devops-lab/0B-04/subnet-ips.txt`, one per line.

### Task 4 — Formatted table
Write a script `/tmp/devops-lab/0B-04/process-csv.sh` that reads `servers.csv` and prints all data rows (skip the header) as an aligned table. Columns should be visually separated. Example:
```
web-01     10.0.1.10   frontend  active
web-02     10.0.1.11   frontend  active
...
```

---

> **Interview Q:** What's the difference between `while read` and a `for` loop for processing file lines? When does it matter?

---

## What Just Happened

Task 1 used `awk` to filter rows by column value and extract a specific field — the core operation in any log or data pipeline. Task 2 combined `awk`, `sort`, and `uniq -c` for a group-count operation; this pattern scales to hundreds of millions of lines. Task 3 added a subnet filter by matching an IP prefix pattern. Task 4 used `printf` or `column` for aligned output — formatting data for human consumption is a key ops skill when building monitoring tools and reports.
