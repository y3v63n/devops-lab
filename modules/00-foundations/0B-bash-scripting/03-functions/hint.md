# Hints — 0B-03: Functions

## Task 1: mathlib.sh

**Hint 1:** Functions output their result with `echo`, not `return`. Use `$(( ))` for arithmetic:
```bash
add() {
  echo $(( $1 + $2 ))
}
```

**Hint 2:** `return` sets the exit code (0–255 only). For negative results, you need `echo`.

**Hint 3:** Full structure:
```bash
#!/usr/bin/env bash
add()      { echo $(( $1 + $2 )); }
subtract() { echo $(( $1 - $2 )); }
multiply() { echo $(( $1 * $2 )); }
```

---

## Task 2: validate.sh

**Hint 1:** Use a regex with `=~` inside `[[ ]]`. An IPv4 address is four groups of 1-3 digits separated by dots:
```bash
[[ "$1" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
```

**Hint 2:** That regex allows `999.999.999.999`. To also check that each octet is 0–255, use `IFS='.' read` to split and check each part:
```bash
is_valid_ip() {
  local ip="$1"
  local IFS='.'
  read -r a b c d <<< "$ip"
  # check all 4 parts are numeric and 0-255
}
```

**Hint 3:** Check each octet with:
```bash
[[ "$a" =~ ^[0-9]+$ ]] && [[ "$a" -le 255 ]]
```

**Hint 4:** Return 0 for valid, 1 for invalid:
```bash
return 0   # valid
return 1   # invalid
```

---

## Task 3: string-utils.sh

**Hint 1:** Bash 4+ has built-in case conversion:
- `${var^^}` — uppercase all characters
- `${var,,}` — lowercase all characters
- `${#var}` — length of string

**Hint 2:**
```bash
to_upper() { echo "${1^^}"; }
to_lower() { echo "${1,,}"; }
str_length() { echo "${#1}"; }
```

**Hint 3:** If `^^` and `,,` don't work (bash 3), use `tr`:
```bash
to_upper() { echo "$1" | tr '[:lower:]' '[:upper:]'; }
```

---

## General Tips

- Test a sourced function: `bash -c "source ./mathlib.sh; add 3 4"`
- List all defined functions: `declare -F`
- Check if a function exists: `declare -f funcname`
