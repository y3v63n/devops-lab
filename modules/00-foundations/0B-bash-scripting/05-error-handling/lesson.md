# Exercise 0B-05: Error Handling

## set -euo pipefail

Three flags that dramatically improve script safety: `set -e` (errexit) causes the script to exit immediately if any command exits non-zero — no more silently continuing after failures. `set -u` (nounset) treats unset variables as errors — catches typos like `$HOMEDIR` when you meant `$HOME`. `set -o pipefail` makes a pipeline fail if any command in it fails, not just the last one — without it, `failing_command | grep foo` exits 0 because `grep` succeeded. Use all three at the top of every production script.

## trap and Cleanup

`trap 'commands' SIGNAL` registers a handler to run when a signal arrives or an event occurs. The `EXIT` pseudo-signal fires whenever the script exits — whether normally, via `exit`, or due to `set -e`. Use it to clean up temp files, release locks, or log a final status: `trap 'rm -rf "$TMPDIR"' EXIT`. The `ERR` signal fires on any non-zero exit (similar to `set -e`). Handlers receive the signal name as context. Always define traps near the top of the script, after `set -euo pipefail`.

## Input Validation Patterns

Never trust input. Validate early and fail loudly with specific messages. Check file existence with `-f`, readability with `-r`, and non-emptiness with `-s` (non-zero size). Check numeric input with `[[ "$n" =~ ^[0-9]+$ ]]`. For commands, verify they exist with `command -v toolname`. Return meaningful exit codes: 1 for general errors, 2 for usage errors, specific codes for known failure modes. Print error messages to stderr (`>&2`) so they don't pollute stdout output that callers might parse.

---

## Tasks

### Task 1 — Safe script with cleanup
Write `/tmp/devops-lab/0B-05/safe-script.sh` that:
- Uses `set -euo pipefail` at the top
- Creates a temp directory with `mktemp -d`
- Writes the text `safe-script was here` to a file called `output.txt` inside the temp dir
- Uses `trap` to clean up (delete) the temp directory on EXIT
- Prints the temp directory path while running
- After the script exits, the temp directory should no longer exist

### Task 2 — Retry wrapper
Write `/tmp/devops-lab/0B-05/retry.sh` that:
- Takes a command (and its args) as arguments: `retry.sh <command> [args...]`
- Tries the command up to 3 times
- Waits 1 second between attempts
- Prints which attempt number it's on (e.g., `Attempt 1/3...`)
- Exits 0 if any attempt succeeds, exits 1 if all 3 fail

```bash
bash /tmp/devops-lab/0B-05/retry.sh true         # → succeeds on attempt 1, exit 0
bash /tmp/devops-lab/0B-05/retry.sh false         # → tries 3 times, exits 1
```

### Task 3 — Input validator
Write `/tmp/devops-lab/0B-05/validate-input.sh` that:
- Takes a filename as `$1`
- Checks: file exists (print `Error: file not found: <name>` if not)
- Checks: file is readable (print `Error: file not readable: <name>` if not)
- Checks: file is not empty (print `Error: file is empty: <name>` if empty)
- Exits with code 0 if all checks pass, code 1 on any failure
- Prints all error messages to stderr

---

> **Interview Q:** What does `set -euo pipefail` do? Explain each flag. When might you NOT want to use `set -e`?

---

## What Just Happened

`safe-script.sh` demonstrated the fundamental cleanup pattern: register the cleanup in a `trap` immediately after creating the resource. This guarantees cleanup even if the script crashes mid-way. `retry.sh` showed defensive programming for flaky operations — network calls, service restarts, and file locks all benefit from retry logic. `validate-input.sh` established the "fail fast, fail loud" principle: validate all preconditions up front so the script doesn't do half its work before discovering the input was wrong. Writing errors to stderr is critical — it keeps stdout clean for parsing while still surfacing errors to operators.
