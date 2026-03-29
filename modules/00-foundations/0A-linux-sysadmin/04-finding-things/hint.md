## Hints

### Task 1: Find all .log files
- `find PATH -name "*.log"` searches recursively for files matching the pattern
- The `*` wildcard matches any characters before `.log`
- Write results: `find /tmp/devops-lab/0A-04/ -name "*.log" > /tmp/devops-lab/0A-04/found-logs.txt`

### Task 2: Extract ERROR lines with grep
- `grep "PATTERN" file` prints lines containing PATTERN
- Case-sensitive by default — "ERROR" won't match "error"
- Write results: `grep "ERROR" /tmp/devops-lab/0A-04/logs/app.log > /tmp/devops-lab/0A-04/errors.txt`

### Task 3: Extract the 3rd field with awk
- `awk '{print $3}'` prints the 3rd whitespace-delimited field from each line
- Fields are numbered starting at 1 (`$1` = first word, `$2` = second, etc.)
- The log format is: `DATE TIME LEVEL CODE message`
  - `$1` = date, `$2` = time, `$3` = level, `$4` = code
  - Wait — look at the actual lines. Count the fields carefully.
- Full command: `awk '{print $3}' /tmp/devops-lab/0A-04/errors.txt > /tmp/devops-lab/0A-04/error-codes.txt`

### Task 4: Find files by size
- `find PATH -size +100c` finds files LARGER than 100 bytes (`c` = bytes)
- Other size units: `k` (kilobytes), `M` (megabytes), `G` (gigabytes)
- `+100c` means "more than 100 bytes"; `-100c` means "less than 100 bytes"
- Write results: `find /tmp/devops-lab/0A-04/data/ -size +100c > /tmp/devops-lab/0A-04/large-files.txt`
