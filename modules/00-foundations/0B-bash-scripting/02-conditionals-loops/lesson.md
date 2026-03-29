# Exercise 0B-02: Conditionals and Loops

## if / elif / else

Bash conditionals test exit codes, not boolean values. `if command; then` runs the `then` block if `command` exits 0. The `[[ ]]` construct is a bash built-in test that returns 0 (true) or 1 (false) based on string, numeric, and file tests. Common operators: `-eq`, `-ne`, `-lt`, `-gt` for integers; `==`, `!=` for strings; `-z` (empty string), `-n` (non-empty); `-f` (is a file), `-d` (is a directory). Arithmetic comparisons can also live inside `(( ))`, which evaluates math expressions.

## for and while Loops

`for item in list; do ... done` iterates over a space-separated list or the output of a command. `for ((i=1; i<=10; i++)); do` gives C-style numeric loops. `while condition; do ... done` runs as long as the condition exits 0 — useful for reading input line-by-line (`while read -r line`) or retrying operations. `break` exits the loop early; `continue` skips to the next iteration.

## Test Operators and [[ vs [

`[ ]` is the POSIX `test` command — available in all shells but has quirks with unquoted variables and some operators. `[[ ]]` is a bash keyword with cleaner syntax: it handles unquoted variables safely, supports `&&` and `||` inside the brackets, allows `=~` for regex matching, and avoids word-splitting surprises. Always prefer `[[ ]]` in bash scripts.

---

## Tasks

### Task 1 — Number classifier
Write `/tmp/devops-lab/0B-02/classify.sh` that takes a number as `$1` and prints `positive`, `negative`, or `zero`.

```bash
bash /tmp/devops-lab/0B-02/classify.sh 5    # → positive
bash /tmp/devops-lab/0B-02/classify.sh -3   # → negative
bash /tmp/devops-lab/0B-02/classify.sh 0    # → zero
```

### Task 2 — FizzBuzz
Write `/tmp/devops-lab/0B-02/fizzbuzz.sh` that prints numbers 1 through 30, replacing:
- Multiples of 3 with `Fizz`
- Multiples of 5 with `Buzz`
- Multiples of both 3 and 5 with `FizzBuzz`

### Task 3 — Countdown
Write `/tmp/devops-lab/0B-02/countdown.sh` that takes a number N as `$1` and counts down from N to 0 using a `while` loop, one number per line.

```bash
bash /tmp/devops-lab/0B-02/countdown.sh 3
# → 3
# → 2
# → 1
# → 0
```

---

> **Interview Q:** What's the difference between `[ ]` and `[[ ]]`? Why prefer `[[ ]]`?

---

## What Just Happened

`classify.sh` showed numeric comparison inside `[[ ]]` with `-gt`, `-lt`, and the fallthrough to `else`. `fizzbuzz.sh` combined a `for` loop with nested conditionals — checking the most-specific case (divisible by both) first to avoid incorrect output. `countdown.sh` used a `while` loop with a manual decrement `((n--))`, demonstrating the pattern for loops where the exit condition changes based on computation rather than iteration over a fixed set.
