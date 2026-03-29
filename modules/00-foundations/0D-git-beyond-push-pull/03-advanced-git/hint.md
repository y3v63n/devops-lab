# Hints — Exercise 0D-03: Advanced Git

## Task 1: Cherry-pick the hotfix

<details>
<summary>Hint 1</summary>

Cherry-pick takes a commit SHA and applies that commit's changes to your current branch. You need to:
1. Be on `main`
2. Find the SHA of the single commit on `hotfix`
3. Run `git cherry-pick <SHA>`

</details>

<details>
<summary>Hint 2</summary>

```bash
cd /tmp/devops-lab/0D-03/myproject
git checkout main

# See what the hotfix commit is
git log hotfix --oneline -1

# Cherry-pick it (you can use the branch name to get the tip SHA)
git cherry-pick $(git rev-parse hotfix)

# Write the new HEAD SHA to the file
git rev-parse HEAD > /tmp/devops-lab/0D-03/cherry-picked.txt
```

Note: the SHA in `cherry-picked.txt` will be different from the original hotfix SHA — cherry-pick creates a NEW commit with the same changes.

</details>

---

## Task 2: Stash with a name

<details>
<summary>Hint 1</summary>

`git stash push -m "name"` saves everything in your working tree and index to the stash stack.

</details>

<details>
<summary>Hint 2</summary>

```bash
# Make a change (something to stash)
echo "# TODO: finish this later" >> README.md

# Stash it with a name
git stash push -m "work-in-progress"

# List stashes and save the list
git stash list > /tmp/devops-lab/0D-03/stash-list.txt
cat /tmp/devops-lab/0D-03/stash-list.txt
```

The stash list will show entries like `stash@{0}: On main: work-in-progress`.

</details>

---

## Task 3: Simulate and recover a lost commit

<details>
<summary>Hint 1</summary>

After `git reset --hard HEAD~1`, the commit is no longer reachable from any branch — but it still exists in Git's object store, and `git reflog` recorded the SHA when you made the commit.

</details>

<details>
<summary>Hint 2</summary>

```bash
# Create a commit
echo "important work" > important.txt
git add important.txt
git commit -m "important: do not lose this"

# "Lose" it
git reset --hard HEAD~1

# Check the reflog — look for your commit
git reflog | head -10
```

You'll see something like:
```
a1b2c3d HEAD@{0}: reset: moving to HEAD~1
e4f5a6b HEAD@{1}: commit: important: do not lose this
...
```

The SHA on the second line (`HEAD@{1}`) is your lost commit.

</details>

<details>
<summary>Hint 3 — Automated recovery</summary>

```bash
# Find the SHA automatically
LOST_SHA=$(git reflog | grep "important: do not lose" | head -1 | awk '{print $1}')
echo "Lost SHA: $LOST_SHA"

# Write to file and recover
echo "$LOST_SHA" > /tmp/devops-lab/0D-03/recovered-sha.txt
git cherry-pick "$LOST_SHA"
```

</details>

---

## Task 4: Git bisect

<details>
<summary>Hint 1</summary>

`git bisect` does a binary search. You need to give it a "good" commit (before the bug) and a "bad" commit (after the bug). Git checks out the midpoint; you test it and report good or bad.

`git bisect run <script>` automates this — it runs the script at each step and uses the exit code (0 = good, non-zero = bad).

</details>

<details>
<summary>Hint 2</summary>

```bash
git bisect start
git bisect bad HEAD          # current HEAD is broken
git bisect good v1.0         # tag v1.0 was clean

# Let Git automate the search using the test script
git bisect run ./test.sh
```

Git will print something like:
```
abc1234 is the first bad commit
```

Write that SHA to the result file.

</details>

<details>
<summary>Hint 3 — Capturing the bisect output</summary>

```bash
# Reset any in-progress bisect first
git bisect reset

# Run bisect and capture the "first bad commit" SHA
git bisect start
git bisect bad HEAD
git bisect good v1.0
BISECT_OUTPUT=$(git bisect run ./test.sh 2>&1)
echo "$BISECT_OUTPUT"

# The first bad commit SHA is printed before "is the first bad commit"
echo "$BISECT_OUTPUT" | grep "is the first bad commit" | awk '{print $1}' \
  > /tmp/devops-lab/0D-03/bisect-result.txt

git bisect reset
cat /tmp/devops-lab/0D-03/bisect-result.txt
```

</details>
