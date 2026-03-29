# Hints — 0B-05: Error Handling

## Task 1: safe-script.sh

**Hint 1:** Put these three lines at the top:
```bash
#!/usr/bin/env bash
set -euo pipefail
```

**Hint 2:** Create a temp directory and immediately set a trap:
```bash
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
echo "Working in: $TMPDIR"
```

**Hint 3:** Write your file inside the temp dir:
```bash
echo "safe-script was here" > "$TMPDIR/output.txt"
```

The `trap ... EXIT` will fire when the script ends — whether it exits normally or fails.

---

## Task 2: retry.sh

**Hint 1:** Use a `for` loop counting 1 to 3. The command to run is `"$@"` (all arguments):
```bash
for attempt in 1 2 3; do
  echo "Attempt $attempt/3..."
  if "$@"; then
    exit 0
  fi
  sleep 1
done
exit 1
```

**Hint 2:** The `if "$@"` runs the command and checks if it exits 0. If it does, exit successfully. If the loop ends without success, exit 1.

**Hint 3:** Skip the last sleep — don't sleep after the final failed attempt. You can use:
```bash
[[ $attempt -lt 3 ]] && sleep 1
```

---

## Task 3: validate-input.sh

**Hint 1:** File test operators:
- `-f "$file"` — file exists and is a regular file
- `-r "$file"` — file is readable
- `-s "$file"` — file has size > 0 (non-empty)

**Hint 2:** Print errors to stderr with `>&2`:
```bash
echo "Error: file not found: $1" >&2
```

**Hint 3:** Full structure:
```bash
#!/usr/bin/env bash
file="$1"
if [[ ! -f "$file" ]]; then
  echo "Error: file not found: $file" >&2
  exit 1
fi
if [[ ! -r "$file" ]]; then
  echo "Error: file not readable: $file" >&2
  exit 1
fi
if [[ ! -s "$file" ]]; then
  echo "Error: file is empty: $file" >&2
  exit 1
fi
echo "File is valid: $file"
```

---

## General Tips

- Test `set -e`: `bash -c 'set -e; false; echo "this should not print"'`
- Test trap: `bash -c 'trap "echo cleanup" EXIT; echo running'`
- `man bash` → search for "trap" and "set" for full documentation
- `-s` flag for `[[ ]]` tests if file is non-empty (has size > 0)
