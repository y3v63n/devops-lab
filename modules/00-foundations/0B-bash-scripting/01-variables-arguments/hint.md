# Hints — 0B-01: Variables and Arguments

## Task 1: greet.sh

**Hint 1:** Check if `$1` is set using `-z` (zero-length string test):
```bash
if [[ -z "$1" ]]; then
  # no argument given
fi
```

**Hint 2:** Use `exit 1` to signal failure when no argument is given.

**Hint 3:** Full structure:
```bash
#!/usr/bin/env bash
if [[ -z "$1" ]]; then
  echo "Hello, World!"
  exit 1
fi
echo "Hello, $1!"
```

---

## Task 2: count-args.sh

**Hint 1:** `$#` holds the number of arguments. Just print it.

**Hint 2:**
```bash
#!/usr/bin/env bash
echo "$#"
```

---

## Task 3: exit-demo.sh

**Hint 1:** Use `${1:-0}` to default to `0` if `$1` is unset or empty.

**Hint 2:**
```bash
#!/usr/bin/env bash
exit "${1:-0}"
```

---

## General Tips

- Make scripts executable: `chmod +x scriptname.sh`
- Test exit codes with: `bash script.sh; echo "Exit: $?"`
- `man bash` and search for "Special Parameters" to read about `$#`, `$@`, `$*`, `$?`
