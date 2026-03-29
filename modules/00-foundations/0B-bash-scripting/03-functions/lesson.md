# Exercise 0B-03: Functions

## Defining and Calling Functions

Functions in bash are blocks of reusable code: `funcname() { commands; }`. Call them by name like any command. Functions see the parent script's variables by default (dynamic scoping), so use `local varname` to prevent unintended side effects — this is critical in any non-trivial script. Functions must be defined before they are called in the file. You can source a library of functions into another script with `. ./libfile.sh` or `source ./libfile.sh`.

## Return Values vs stdout

Bash functions have two ways to communicate results. The `return N` statement sets the function's exit code (0–255, integers only) — useful for pass/fail signaling. To return a string or number, `echo` or `printf` it inside the function and capture it with command substitution: `result=$(funcname args)`. This is the idiomatic pattern for returning computed values. Avoid using global variables for output — it makes functions hard to test and reuse.

## Function Libraries

A bash library is just a script full of function definitions with no executable code at the top level. Other scripts source it to get access to those functions. Keep libraries focused: math functions in one file, string utilities in another. The `declare -f funcname` command checks if a function is defined; `declare -F` lists all defined functions. When writing libraries, document the expected arguments and output of each function with a comment.

---

## Tasks

### Task 1 — Math library
Write `/tmp/devops-lab/0B-03/mathlib.sh` that defines three functions:
- `add N1 N2` — prints the sum
- `subtract N1 N2` — prints the difference (N1 - N2)
- `multiply N1 N2` — prints the product

```bash
source /tmp/devops-lab/0B-03/mathlib.sh
add 3 4        # → 7
subtract 10 3  # → 7
multiply 4 5   # → 20
```

### Task 2 — IP validator
Write `/tmp/devops-lab/0B-03/validate.sh` that defines a function `is_valid_ip`:
- Takes one string argument
- Returns `0` (exit code) if it's a valid IPv4 address (four octets 0–255 separated by dots)
- Returns `1` otherwise

```bash
source /tmp/devops-lab/0B-03/validate.sh
is_valid_ip "192.168.1.1"   # exit code 0
is_valid_ip "256.0.0.1"     # exit code 1
is_valid_ip "not-an-ip"     # exit code 1
```

### Task 3 — String utilities
Write `/tmp/devops-lab/0B-03/string-utils.sh` that defines:
- `to_upper STR` — prints STR in uppercase
- `to_lower STR` — prints STR in lowercase
- `str_length STR` — prints the number of characters in STR

```bash
source /tmp/devops-lab/0B-03/string-utils.sh
to_upper "hello"     # → HELLO
to_lower "WORLD"     # → world
str_length "devops"  # → 6
```

---

> **Interview Q:** How do you return a value from a bash function? What are the options and trade-offs?

---

## What Just Happened

`mathlib.sh` demonstrated that bash functions output values via `echo` to stdout, not via `return`. `return` is for exit codes only — using `return 7` in `add` would give back the number 7 as an exit code, which is not the sum. `validate.sh` used `return 0/1` correctly — this is exactly what `return` is for: signaling success or failure so callers can use the function in an `if` statement. `string-utils.sh` used bash parameter expansion (`${var^^}` for uppercase, `${var,,}` for lowercase, `${#var}` for length) — built-in operations that avoid spawning a subprocess.
