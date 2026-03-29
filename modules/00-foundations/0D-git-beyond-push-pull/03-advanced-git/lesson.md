# Exercise 0D-03: Advanced Git — Cherry-Pick, Stash, Reflog, Bisect

## Theory

**Cherry-pick and stash.** `git cherry-pick <SHA>` copies a single commit from anywhere in the history and applies it to your current branch. This is useful for pulling a bug fix from a release branch onto main, or grabbing a specific commit without merging an entire feature branch. `git stash` is a scratchpad: it saves your current uncommitted changes to a stack and restores a clean working tree, so you can switch context and come back later. `git stash list` shows all saved stashes; `git stash pop` restores the most recent one.

**Reflog — Git's safety net.** Every time Git moves `HEAD` (commits, checkouts, resets, rebases), it records the change in the reflog. This means commits that appear "lost" after a `git reset --hard` or accidental branch deletion are almost always recoverable. `git reflog` shows a chronological list of where HEAD has been. The entries expire after 90 days by default (configurable). To recover a lost commit, find its SHA in the reflog and either `git checkout <SHA>`, `git cherry-pick <SHA>`, or create a new branch at that point with `git branch recovered <SHA>`.

**Bisect — binary search for bugs.** `git bisect` helps you find which commit introduced a bug by performing a binary search through your history. You tell Git a known-good commit and a known-bad commit; it checks out the midpoint for you to test. You report `git bisect good` or `git bisect bad` after each test, and Git narrows down until it identifies the exact commit that introduced the problem. `git bisect run <script>` automates this entirely if you have a test script that exits 0 for good and non-zero for bad.

---

## Tasks

Work directory: `/tmp/devops-lab/0D-03/`

**Task 1 — Cherry-pick the hotfix onto main**

The `hotfix` branch has one commit with an important fix. Apply it to `main`:

```bash
cd /tmp/devops-lab/0D-03/myproject
git checkout main
git log hotfix --oneline -1        # see what we're picking
git cherry-pick $(git rev-parse hotfix)
```

Write the new commit's SHA to a file:

```bash
git rev-parse HEAD > /tmp/devops-lab/0D-03/cherry-picked.txt
cat /tmp/devops-lab/0D-03/cherry-picked.txt
```

**Task 2 — Stash work-in-progress and record the stash list**

Create a small change, then stash it with a descriptive name:

```bash
echo "# TODO: finish this later" >> README.md
git stash push -m "work-in-progress"
git stash list > /tmp/devops-lab/0D-03/stash-list.txt
cat /tmp/devops-lab/0D-03/stash-list.txt
```

**Task 3 — Simulate a "lost" commit and recover it with reflog**

Create a commit, then lose it with a hard reset, then recover it:

```bash
# Create a commit
echo "important work" > important.txt
git add important.txt
git commit -m "important: do not lose this"

# "Accidentally" reset it away
git reset --hard HEAD~1

# Find the lost commit SHA in the reflog
git reflog | head -5
```

Identify the SHA of the lost commit (it was `HEAD@{1}` before the reset). Write it to a file and recover it:

```bash
LOST_SHA=$(git reflog | grep "important: do not lose" | head -1 | awk '{print $1}')
echo "$LOST_SHA" > /tmp/devops-lab/0D-03/recovered-sha.txt
git cherry-pick "$LOST_SHA"
```

**Task 4 — Use git bisect to find the bad commit**

A bug was introduced in one of the commits on main. The repo includes a test script at `/tmp/devops-lab/0D-03/myproject/test.sh` that exits 0 if the code is "good" and 1 if it's "bad".

Find the commit range — there is a known-good tag `v1.0` and the current HEAD is known-bad:

```bash
git bisect start
git bisect bad HEAD
git bisect good v1.0
git bisect run ./test.sh
```

Git will print the first bad commit. Write it to a file:

```bash
git bisect reset
git bisect start
git bisect bad HEAD
git bisect good v1.0
git bisect run ./test.sh 2>&1 | grep "is the first bad commit" | awk '{print $1}' > /tmp/devops-lab/0D-03/bisect-result.txt
git bisect reset
cat /tmp/devops-lab/0D-03/bisect-result.txt
```

---

## What Just Happened

Cherry-pick copied a single commit's diff and applied it as a new commit on main — the commit message is preserved but the SHA is different. Stash pushed your working-tree changes to a stack without committing them, keeping the working tree clean. The reflog recovery demonstrated that Git retains every HEAD movement: even after `reset --hard`, the old commit wasn't deleted immediately — it was just dereferenced. Bisect ran your test script automatically at each midpoint, halving the search space each time, until it pinpointed the exact commit that broke the test.

---

## Interview Question

**"You accidentally ran `git reset --hard` and lost commits. How do you recover them? How long do reflog entries last?"**

Run `git reflog` to see the history of where HEAD has pointed. Find the SHA of the commit you want to recover, then either `git cherry-pick <SHA>` to apply it to the current branch, or `git branch recovery-branch <SHA>` to create a new branch at that point. Reflog entries last 90 days by default (configured by `gc.reflogExpire`). After that, `git gc` can prune them. For unreachable objects that were never referenced by reflog (very rare), `git fsck --lost-found` can sometimes find them before garbage collection.
