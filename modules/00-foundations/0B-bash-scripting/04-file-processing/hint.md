# Hints — 0B-04: File Processing

## Task 1: active-hosts.txt

**Hint 1:** Use `awk` with a comma field separator. The status column is `$4`, hostname is `$1`:
```bash
awk -F',' '$4 == "active" { print $1 }' servers.csv
```

**Hint 2:** Skip the header row by adding `NR > 1` (NR = line number):
```bash
awk -F',' 'NR > 1 && $4 == "active" { print $1 }' servers.csv > active-hosts.txt
```

---

## Task 2: role-counts.txt

**Hint 1:** The role column is `$3`. Use `awk` to extract roles, then count with `sort | uniq -c`:
```bash
awk -F',' 'NR > 1 { print $3 }' servers.csv | sort | uniq -c
```

**Hint 2:** That gives output like `2 frontend`. To flip it to `frontend: 2`, pipe through `awk`:
```bash
awk -F',' 'NR > 1 { print $3 }' servers.csv | sort | uniq -c | awk '{ print $2 ": " $1 }'
```

**Hint 3:** Save with: `... > role-counts.txt`

---

## Task 3: subnet-ips.txt

**Hint 1:** The IP column is `$2`. Use `grep` to filter `10.0.1.` prefix:
```bash
awk -F',' 'NR > 1 { print $2 }' servers.csv | grep '^10\.0\.1\.'
```

**Hint 2:** Or do it all in awk:
```bash
awk -F',' 'NR > 1 && $2 ~ /^10\.0\.1\./ { print $2 }' servers.csv > subnet-ips.txt
```

---

## Task 4: process-csv.sh

**Hint 1:** Use `column -t -s,` to auto-align CSV columns:
```bash
column -t -s',' servers.csv
```

**Hint 2:** To skip the header, skip the first line with `tail -n +2`:
```bash
tail -n +2 servers.csv | column -t -s','
```

**Hint 3:** For custom alignment with `printf`:
```bash
while IFS=',' read -r host ip role status; do
  printf "%-12s %-15s %-10s %s\n" "$host" "$ip" "$role" "$status"
done < servers.csv
```

---

## General Tips

- Test commands interactively before putting them in files
- `awk -F',' '{ print NF }' servers.csv` — check how many fields per line
- `man awk` → search for "Field Separator" and "NR" (record number)
- `column --help` to see alignment options
