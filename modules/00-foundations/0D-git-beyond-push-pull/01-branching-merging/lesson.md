# Exercise 0D-01: Branching and Merging

## Theory

**Branches as pointers.** In Git, a branch is simply a lightweight pointer to a specific commit. When you create a branch, Git doesn't copy any files — it just creates a new pointer. Moving between branches changes what `HEAD` points to. This makes creating and switching branches nearly instant, no matter how large your repository is.

**Merge types.** When you merge two branches, Git chooses a strategy based on their history. A **fast-forward merge** happens when there is a straight-line path from one branch tip to the other — Git simply moves the pointer forward, no merge commit is created. A **three-way merge** is required when the branches have diverged: Git finds the common ancestor, compares each branch's changes relative to it, and creates a new merge commit that ties both histories together.

**Merge conflicts.** Conflicts occur when both branches have modified the same lines of the same file. Git pauses the merge and marks the conflicting sections with `<<<<<<<`, `=======`, and `>>>>>>>` markers. Your job is to edit the file, remove the markers, and decide on the final content — keeping one side, the other, or a combination. Once resolved, you `git add` the file and `git commit` to complete the merge.

---

## Tasks

Work directory: `/tmp/devops-lab/0D-01/`

**Task 1 — Check out the feature branch**

Switch to the `feature-a` branch and confirm it exists and has different content than `main`.

```bash
cd /tmp/devops-lab/0D-01/myproject
git checkout feature-a
cat config.txt
```

Compare to what is on `main`:

```bash
git show main:config.txt
```

**Task 2 — Merge main into feature-a (expect a conflict)**

While on `feature-a`, merge `main` into it:

```bash
git merge main
```

Git will report a conflict in `config.txt`. Do NOT abort — proceed to Task 3.

**Task 3 — Resolve the conflict and complete the merge**

Open `config.txt` in your editor. You will see conflict markers like:

```
<<<<<<< HEAD
version=feature
=======
version=2.0
>>>>>>> main
```

Edit the file so it contains **both** changes in a meaningful way (e.g., combine the lines so nothing is lost). Remove all conflict markers. Then stage and commit:

```bash
git add config.txt
git commit -m "Merge main into feature-a, resolve config conflict"
```

**Task 4 — Inspect the resulting history**

```bash
git log --oneline --graph --all
```

You should see a merge commit (a node with two parent lines) connecting `feature-a` and `main`.

---

## What Just Happened

You performed a **three-way merge**. Git identified the common ancestor (the first commit where `feature-a` diverged from `main`), compared both branches' changes to that ancestor, and found they modified the same line — a conflict. You resolved it by deciding on the final content, then Git recorded a new merge commit with two parents, preserving the complete history of both branches.

A fast-forward merge would have looked different: if `feature-a` had no commits of its own and you simply added commits to it from main, Git would just move the `feature-a` pointer forward — no merge commit at all.

---

## Interview Question

**"What's the difference between a fast-forward merge and a three-way merge? When does each happen?"**

A fast-forward merge is possible when one branch is a direct ancestor of the other — there is no divergence. Git simply advances the pointer; no new commit is created and history stays linear. A three-way merge is required when both branches have commits not present in the other. Git uses the common ancestor as the base, combines changes from both sides, and creates a merge commit with two parents. Fast-forward is the default when possible; `--no-ff` forces a merge commit even when fast-forward is available.
