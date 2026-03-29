#!/usr/bin/env bash
# verify.sh — Exercise 0D-03: Advanced Git

WORK_DIR="/tmp/devops-lab/0D-03"
REPO="$WORK_DIR/myproject"
PASS=0
FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then
    echo "  ✓ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "Verifying: Exercise 0D-03 — Advanced Git"
echo ""

# Check repo exists
if [[ ! -d "$REPO/.git" ]]; then
  echo "  ERROR: Repository not found at $REPO"
  echo "  Run reset.sh first."
  exit 1
fi

cd "$REPO"

# ---------------------------------------------------------------
# Task 1: cherry-picked.txt exists and SHA is valid and on main
# ---------------------------------------------------------------
CHERRY_FILE="$WORK_DIR/cherry-picked.txt"
check "cherry-picked.txt exists" \
  "$([[ -f "$CHERRY_FILE" ]] && echo pass || echo fail)"

if [[ -f "$CHERRY_FILE" ]]; then
  CHERRY_SHA=$(tr -d '[:space:]' < "$CHERRY_FILE")

  # SHA must be a valid git object
  check "cherry-picked.txt contains a valid commit SHA" \
    "$(git cat-file -t "$CHERRY_SHA" 2>/dev/null | grep -q commit && echo pass || echo fail)"

  # That SHA must be reachable from main
  check "cherry-picked commit is on main branch" \
    "$(git merge-base --is-ancestor "$CHERRY_SHA" main 2>/dev/null && echo pass || echo fail)"

  # The commit message should mention the hotfix content
  CHERRY_MSG=$(git log --format="%s" -1 "$CHERRY_SHA" 2>/dev/null)
  check "cherry-picked commit message references hotfix" \
    "$(echo "$CHERRY_MSG" | grep -qi 'hotfix\|security' && echo pass || echo fail)"
fi

# ---------------------------------------------------------------
# Task 2: stash-list.txt exists and is non-empty
# ---------------------------------------------------------------
STASH_FILE="$WORK_DIR/stash-list.txt"
check "stash-list.txt exists" \
  "$([[ -f "$STASH_FILE" ]] && echo pass || echo fail)"

if [[ -f "$STASH_FILE" ]]; then
  check "stash-list.txt is non-empty (at least one stash recorded)" \
    "$([[ -s "$STASH_FILE" ]] && echo pass || echo fail)"

  check "stash-list.txt contains 'work-in-progress' entry" \
    "$(grep -q 'work-in-progress' "$STASH_FILE" && echo pass || echo fail)"
fi

# ---------------------------------------------------------------
# Task 3: recovered-sha.txt exists and SHA is in reflog
# ---------------------------------------------------------------
RECOVERED_FILE="$WORK_DIR/recovered-sha.txt"
check "recovered-sha.txt exists" \
  "$([[ -f "$RECOVERED_FILE" ]] && echo pass || echo fail)"

if [[ -f "$RECOVERED_FILE" ]]; then
  RECOVERED_SHA=$(tr -d '[:space:]' < "$RECOVERED_FILE")

  # SHA must be a valid git object
  check "recovered-sha.txt contains a valid commit SHA" \
    "$(git cat-file -t "$RECOVERED_SHA" 2>/dev/null | grep -q commit && echo pass || echo fail)"

  # SHA must appear in the reflog
  check "recovered SHA appears in git reflog" \
    "$(git reflog --all | grep -q "${RECOVERED_SHA:0:7}" && echo pass || echo fail)"

  # The important commit must be on current main (was cherry-picked back)
  check "recovered commit was cherry-picked back onto main" \
    "$(git log main --format='%s' | grep -q 'important: do not lose' && echo pass || echo fail)"
fi

# ---------------------------------------------------------------
# Task 4: bisect-result.txt exists and SHA is the "bad" commit
# ---------------------------------------------------------------
BISECT_FILE="$WORK_DIR/bisect-result.txt"
check "bisect-result.txt exists" \
  "$([[ -f "$BISECT_FILE" ]] && echo pass || echo fail)"

if [[ -f "$BISECT_FILE" ]]; then
  BISECT_SHA=$(tr -d '[:space:]' < "$BISECT_FILE")

  # Must be a valid SHA
  check "bisect-result.txt contains a valid commit SHA" \
    "$(git cat-file -t "$BISECT_SHA" 2>/dev/null | grep -q commit && echo pass || echo fail)"

  # The correct bad commit should have "Refactor app status handling" in its message
  BISECT_MSG=$(git log --format="%s" -1 "$BISECT_SHA" 2>/dev/null)
  check "bisect result points to the commit that introduced the bug" \
    "$(echo "$BISECT_MSG" | grep -qi 'Refactor app status' && echo pass || echo fail)"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
