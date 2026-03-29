# Hints — Exercise 0D-01: Branching and Merging

## Task 1: Check out feature-a

<details>
<summary>Hint 1</summary>

Use `git branch` to see available branches, then switch with `git checkout`.

</details>

<details>
<summary>Hint 2</summary>

```bash
cd /tmp/devops-lab/0D-01/myproject
git branch          # lists all local branches
git checkout feature-a
cat config.txt      # see what feature-a has
git show main:config.txt  # compare with main
```

</details>

---

## Task 2: Merge main into feature-a

<details>
<summary>Hint 1</summary>

You must be on `feature-a` when you run the merge. The merge command takes the branch you want to bring in as the argument.

</details>

<details>
<summary>Hint 2</summary>

```bash
git checkout feature-a   # make sure you're on feature-a
git merge main           # bring in main's changes
# Git will say "CONFLICT" — this is expected
```

Do NOT run `git merge --abort`. The conflict is part of the exercise.

</details>

---

## Task 3: Resolve the conflict

<details>
<summary>Hint 1</summary>

Open `config.txt` in any text editor. Look for lines starting with `<<<<<<<`, `=======`, and `>>>>>>>`. The section between `<<<<<<<` and `=======` is your current branch (feature-a). The section between `=======` and `>>>>>>>` is the incoming branch (main).

</details>

<details>
<summary>Hint 2</summary>

You need to:
1. Decide on the final content (keep both changes somehow)
2. Remove ALL three marker lines (`<<<<<<<`, `=======`, `>>>>>>>`)
3. Save the file

A reasonable resolution might include both `debug=true`, `log_level=verbose`, `version=2.0`, and `max_connections=100`.

</details>

<details>
<summary>Hint 3 — Complete resolution example</summary>

```bash
# Edit config.txt to look like this (no markers):
cat > /tmp/devops-lab/0D-01/myproject/config.txt <<'EOF'
# Project configuration
app=myapp
version=2.0
debug=true
log_level=verbose
max_connections=100
EOF

# Then stage and commit:
git add config.txt
git commit -m "Merge main into feature-a, resolve config conflict"
```

</details>

---

## Task 4: Inspect the history

<details>
<summary>Hint 1</summary>

```bash
git log --oneline --graph --all
```

Look for a line like `*   Merge main into feature-a` with two branch lines (`|\`) above it connecting to two parent commits.

</details>
