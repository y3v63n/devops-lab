# Hints — Exercise 0D-02: Rebasing

## Task 1: Inspect feature-b

<details>
<summary>Hint 1</summary>

```bash
cd /tmp/devops-lab/0D-02/myproject
git checkout feature-b
git log --oneline
```

You should see 4 commits with messages like "fix typo", "add debug logging", "remove debug logging", and "feat: add farewell()".

</details>

---

## Task 2: Squash 3 commits into 1 (interactive rebase)

<details>
<summary>Hint 1</summary>

Interactive rebase opens your `$EDITOR` with a list of commits and actions. The key actions are:
- `pick` — keep the commit as-is
- `squash` (or `s`) — combine this commit into the one above it

You need to change lines 2 and 3 from `pick` to `squash` (keeping line 1 as `pick` and line 4 as `pick`).

</details>

<details>
<summary>Hint 2 — Using a scripted approach (no interactive editor)</summary>

If you want to avoid the editor, use `GIT_SEQUENCE_EDITOR` to script the changes:

```bash
GIT_SEQUENCE_EDITOR="sed -i '2s/^pick/squash/; 3s/^pick/squash/'" \
  git rebase -i HEAD~4
```

Git will still open the commit message editor for the squashed commit. You can set `GIT_EDITOR` too if needed, or use:

```bash
GIT_SEQUENCE_EDITOR="sed -i '2s/^pick/squash/; 3s/^pick/squash/'" \
  GIT_EDITOR="true" \
  git rebase -i HEAD~4
```

(`GIT_EDITOR="true"` accepts the default combined message without prompting.)

</details>

<details>
<summary>Hint 3 — Manual interactive approach</summary>

```bash
git rebase -i HEAD~4
```

Your editor opens with something like:
```
pick abc1234 fix typo in utils
pick def5678 add debug logging to greet
pick ghi9012 remove debug logging (oops)
pick jkl3456 feat: add farewell() utility function
```

Change to:
```
pick abc1234 fix typo in utils
squash def5678 add debug logging to greet
squash ghi9012 remove debug logging (oops)
pick jkl3456 feat: add farewell() utility function
```

Save the file. Git opens a second editor for the squashed commit message — write something like "cleanup: fix typo and tidy up utils" and save.

Verify: `git log --oneline` should now show 2 commits on feature-b.

</details>

---

## Task 3: Rebase onto main

<details>
<summary>Hint 1</summary>

Make sure you are on `feature-b`:

```bash
git checkout feature-b
git rebase main
```

If there are no conflicts, it completes automatically. Check the result:

```bash
git log --oneline --graph --all
```

feature-b's 2 commits should now appear after main's commits with no branching lines.

</details>

---

## Task 4: Write the log to a file

<details>
<summary>Hint 1</summary>

```bash
git log --oneline > /tmp/devops-lab/0D-02/final-log.txt
cat /tmp/devops-lab/0D-02/final-log.txt
```

The file should show 4 lines total: 2 from main + 2 from feature-b, all linear.

</details>
