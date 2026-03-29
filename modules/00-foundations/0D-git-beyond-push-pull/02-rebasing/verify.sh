#!/usr/bin/env bash
# verify.sh — Exercise 0D-02: Rebasing

WORK_DIR="/tmp/devops-lab/0D-02"
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

echo "Verifying: Exercise 0D-02 — Rebasing"
echo ""

# Check repo exists
if [[ ! -d "$REPO/.git" ]]; then
  echo "  ERROR: Repository not found at $REPO"
  echo "  Run reset.sh first."
  exit 1
fi

cd "$REPO"

# Task 1: feature-b branch exists
check "feature-b branch exists" \
  "$(git branch --list feature-b | grep -q feature-b && echo pass || echo fail)"

# Task 2: feature-b has exactly 2 commits on top of main
# Count commits reachable from feature-b but not from main
COMMITS_AHEAD=$(git rev-list feature-b ^main --count 2>/dev/null)
check "feature-b has exactly 2 commits ahead of main (squashed from 4)" \
  "$([[ "$COMMITS_AHEAD" -eq 2 ]] && echo pass || echo fail)"

# Task 2: no merge commits on feature-b
MERGE_COUNT=$(git log feature-b --merges --oneline | wc -l | tr -d ' ')
check "feature-b has no merge commits (history is linear)" \
  "$([[ "$MERGE_COUNT" -eq 0 ]] && echo pass || echo fail)"

# Task 3: feature-b is based on top of main (main commits are ancestors)
MAIN_TIP=$(git rev-parse main)
FEATURE_BASE=$(git rev-parse "feature-b~${COMMITS_AHEAD}" 2>/dev/null)
check "feature-b is rebased onto main (main tip is the base)" \
  "$([[ "$FEATURE_BASE" == "$MAIN_TIP" ]] && echo pass || echo fail)"

# Task 3: utils.py contains farewell function (final feature work preserved)
git show feature-b:utils.py > /tmp/devops-lab-utils-check.py 2>/dev/null
check "utils.py on feature-b contains farewell() function" \
  "$(grep -q 'def farewell' /tmp/devops-lab-utils-check.py && echo pass || echo fail)"
rm -f /tmp/devops-lab-utils-check.py

# Task 4: final-log.txt exists and is non-empty
LOG_FILE="$WORK_DIR/final-log.txt"
check "final-log.txt exists" \
  "$([[ -f "$LOG_FILE" ]] && echo pass || echo fail)"

if [[ -f "$LOG_FILE" ]]; then
  LOG_LINES=$(wc -l < "$LOG_FILE" | tr -d ' ')
  check "final-log.txt is non-empty (has commit entries)" \
    "$([[ "$LOG_LINES" -ge 1 ]] && echo pass || echo fail)"

  # Log should not contain any merge commits (no "Merge" entries)
  check "final-log.txt shows linear history (no merge commits)" \
    "$(! grep -qi '^[a-f0-9]* Merge' "$LOG_FILE" && echo pass || echo fail)"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
