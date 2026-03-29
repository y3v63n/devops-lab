# Exercise 0D-02: Rebasing

## Theory

**Rebase vs merge.** Both rebase and merge integrate changes from one branch into another, but they produce different histories. Merge preserves the exact timeline — a merge commit records when two lines of work came together. Rebase rewrites history: it takes commits from one branch and replays them on top of another, producing a clean linear history as if the work had always been built sequentially. Neither is universally better; each serves a purpose.

**Interactive rebase.** `git rebase -i` (interactive mode) lets you rewrite your local commit history before sharing it. You can reorder commits, combine (squash) multiple commits into one, edit commit messages, or drop commits entirely. This is how experienced developers clean up messy "WIP: fix", "fix typo", "actually fix typo" commits into a coherent story before opening a pull request. The editor presents a list of commits and actions you can apply to each.

**The golden rule of rebasing.** Never rebase commits that have already been pushed to a shared branch. Rebase rewrites commit SHAs — any collaborator who pulled the original commits will have diverged history, leading to painful conflicts and duplicate commits. Rebase freely on your own local branches; avoid it on `main`, `develop`, or any branch others are actively using.

---

## Tasks

Work directory: `/tmp/devops-lab/0D-02/`

**Task 1 — Check out feature-b and inspect its commits**

```bash
cd /tmp/devops-lab/0D-02/myproject
git checkout feature-b
git log --oneline
```

You should see 4 commits on top of main. Note their messages.

**Task 2 — Squash the first 3 commits into one using interactive rebase**

Interactive rebase requires a text editor. The simplest approach is to set the sequence editor to `sed` so you can script the changes:

```bash
# Squash commits 1-3 into the first, keep commit 4 as-is
# "pick" = keep as-is, "squash" = combine into previous commit
GIT_SEQUENCE_EDITOR="sed -i '2s/^pick/squash/; 3s/^pick/squash/'" \
  git rebase -i HEAD~4
```

This will open a second editor for the combined commit message. You can accept the default (which concatenates all three messages) or write a new one. Save and close.

Alternatively, do it manually in your editor: change the word `pick` to `squash` (or `s`) on lines 2 and 3 of the rebase todo file.

After the squash, verify you now have 2 commits on feature-b:

```bash
git log --oneline
```

**Task 3 — Rebase feature-b onto main**

Move feature-b's 2 commits so they sit on top of main's latest commit:

```bash
git rebase main
```

Verify the result — feature-b should now show main's commits followed by your 2 commits, all in a straight line.

**Task 4 — Write the final log to a file**

```bash
git log --oneline > /tmp/devops-lab/0D-02/final-log.txt
cat /tmp/devops-lab/0D-02/final-log.txt
```

---

## What Just Happened

The interactive rebase re-wrote three commits into one by combining their diffs and letting you write a single commit message. Then the non-interactive `git rebase main` replayed feature-b's 2 commits on top of main's latest commit, as if you had branched off today rather than from the older base. The result is a linear history — no merge commit, no diverging lines.

Compare with a merge: `git merge main` on feature-b would have produced a merge commit tying the two histories together. Rebase gives you a cleaner log but trades off the true timestamp and branching history.

---

## Interview Question

**"When should you NOT rebase? What's the golden rule of rebasing?"**

Never rebase commits that have already been pushed to a shared (public) branch. Rebase rewrites commit SHAs. If anyone has already pulled those commits, their local history will diverge from yours after the rebase, causing conflicts and duplicate commits when they next push or pull. The golden rule: **only rebase local, unpublished commits**. On your own feature branch that no one else has checked out, rebase freely. On `main`, `develop`, or any branch shared with teammates, always use merge instead.
