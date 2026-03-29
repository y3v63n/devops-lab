# Exercise 0B-01: Variables and Arguments

## Shell Variables

Shell variables store data for use in scripts. Assign them with `NAME=value` (no spaces around `=`) and read them with `$NAME` or `${NAME}`. Always quote variable expansions (`"$NAME"`) to prevent word splitting and glob expansion — failing to do so is a common source of bugs. Variables are untyped by default; everything is a string unless declared otherwise with `declare -i` (integer) or `declare -a` (array).

## Positional Parameters

When a script is called with arguments, bash populates the special variables `$1`, `$2`, ... `$9`, `${10}`, etc. — one per argument. `$0` holds the script name itself. `$#` gives the total count of arguments. `$@` expands to all arguments as separate words; `$*` expands to all arguments joined by the first character of `IFS` (usually a space). This difference only matters inside double quotes: `"$@"` preserves word boundaries while `"$*"` collapses them into one string.

## Exit Codes

Every command in bash returns an exit code: `0` means success, anything else means failure. Access the last command's exit code with `$?`. Use `exit N` to terminate a script with code N. The `||` and `&&` operators short-circuit based on exit codes. Tools like `if`, `while`, and `until` test exit codes directly — they don't test string values.

---

## Tasks

### Task 1 — Greeting script
Write a script at `/tmp/devops-lab/0B-01/greet.sh` that:
- Takes a name as `$1`
- Prints `Hello, <name>!`
- If no argument is given, prints `Hello, World!` and exits with code `1`

```bash
bash /tmp/devops-lab/0B-01/greet.sh Alice   # → Hello, Alice!
bash /tmp/devops-lab/0B-01/greet.sh          # → Hello, World! (exit 1)
```

### Task 2 — Argument counter
Write a script at `/tmp/devops-lab/0B-01/count-args.sh` that prints the number of arguments it received.

```bash
bash /tmp/devops-lab/0B-01/count-args.sh a b c   # → 3
bash /tmp/devops-lab/0B-01/count-args.sh          # → 0
```

### Task 3 — Exit code demo
Write a script at `/tmp/devops-lab/0B-01/exit-demo.sh` that exits with the code passed as `$1`. If no argument, exit with code `0`.

```bash
bash /tmp/devops-lab/0B-01/exit-demo.sh 42; echo $?   # → 42
bash /tmp/devops-lab/0B-01/exit-demo.sh; echo $?      # → 0
```

---

> **Interview Q:** What's the difference between `$*` and `$@`? When does it matter?

---

## What Just Happened

You wrote three scripts that demonstrate the core of bash argument handling. `greet.sh` showed the pattern of providing defaults when arguments are missing — a robust script never assumes its caller passed the right number of arguments. `count-args.sh` used `$#`, which lets a script adapt its behavior to however many arguments it received. `exit-demo.sh` highlighted that exit codes are the primary communication channel between a script and its caller — CI systems, `if` statements, and shell pipelines all act on exit codes, not on printed text.
