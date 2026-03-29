# Hints — 0B-02: Conditionals and Loops

## Task 1: classify.sh

**Hint 1:** Use `-gt` and `-lt` for numeric comparisons inside `[[ ]]`:
```bash
[[ "$1" -gt 0 ]]   # true if $1 is greater than 0
[[ "$1" -lt 0 ]]   # true if $1 is less than 0
```

**Hint 2:** Structure with if/elif/else:
```bash
if [[ "$1" -gt 0 ]]; then
  echo "positive"
elif [[ "$1" -lt 0 ]]; then
  echo "negative"
else
  echo "zero"
fi
```

---

## Task 2: fizzbuzz.sh

**Hint 1:** Use `(( n % 3 == 0 ))` for modulo arithmetic. `(( ))` returns 0 (success/true) when the expression is non-zero.

**Hint 2:** Check the combined case (FizzBuzz) first, before checking Fizz or Buzz alone.

**Hint 3:** Use a C-style for loop:
```bash
for ((i=1; i<=30; i++)); do
  if (( i % 15 == 0 )); then
    echo "FizzBuzz"
  elif (( i % 3 == 0 )); then
    echo "Fizz"
  elif (( i % 5 == 0 )); then
    echo "Buzz"
  else
    echo "$i"
  fi
done
```

---

## Task 3: countdown.sh

**Hint 1:** Assign `$1` to a variable, then decrement it in the loop:
```bash
n="$1"
while [[ "$n" -ge 0 ]]; do
  echo "$n"
  ((n--))
done
```

**Hint 2:** `-ge` means "greater than or equal to". The loop runs while `n >= 0`, so it prints `0` on the last iteration.

---

## General Tips

- `man bash` → search for "Compound Commands" to see `[[ ]]` and `(( ))` docs
- Test arithmetic: `echo $(( 15 % 3 ))`  → `0`
- Test comparisons: `[[ 5 -gt 3 ]] && echo yes || echo no`
