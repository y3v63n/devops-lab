#!/usr/bin/env bash
# verify.sh — Exercise 0D-01: Branching and Merging

WORK_DIR="/tmp/devops-lab/0D-01"
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

echo "Verifying: Exercise 0D-01 — Branching and Merging"
echo ""

# Check repo exists
if [[ ! -d "$REPO/.git" ]]; then
  echo "  ERROR: Repository not found at $REPO"
  echo "  Run reset.sh first."
  exit 1
fi

cd "$REPO"

# Task 1: feature-a branch exists
check "feature-a branch exists" \
  "$(git branch --list feature-a | grep -q feature-a && echo pass || echo fail)"

# Task 2 + 3: feature-a has a merge commit
MERGE_COUNT=$(git log feature-a --merges --oneline | wc -l | tr -d ' ')
check "feature-a contains a merge commit" \
  "$([[ "$MERGE_COUNT" -ge 1 ]] && echo pass || echo fail)"

# Task 3: config.txt has no conflict markers
if [[ -f config.txt ]]; then
  if grep -qE '^(<{7}|={7}|>{7})' config.txt; then
    check "config.txt has no conflict markers" "fail"
  else
    check "config.txt has no conflict markers" "pass"
  fi
else
  check "config.txt exists" "fail"
fi

# Task 3: config.txt contains content from main (version=2.0 or max_connections)
check "config.txt contains changes from main" \
  "$(grep -qE 'version=2\.0|max_connections' config.txt && echo pass || echo fail)"

# Task 3: config.txt contains content from feature-a (log_level or debug=true)
check "config.txt contains changes from feature-a" \
  "$(grep -qE 'log_level|debug=true' config.txt && echo pass || echo fail)"

# Task 4: merge commit has two parents
MERGE_SHA=$(git log feature-a --merges --format="%H" | head -1)
if [[ -n "$MERGE_SHA" ]]; then
  PARENT_COUNT=$(git cat-file -p "$MERGE_SHA" | grep -c '^parent ')
  check "merge commit has two parents" \
    "$([[ "$PARENT_COUNT" -eq 2 ]] && echo pass || echo fail)"
else
  check "merge commit has two parents" "fail"
fi

# Task 4: both main and feature-a commits appear in feature-a history
MAIN_MSG_FOUND=$(git log feature-a --oneline | grep -c "bump version to 2.0")
FEAT_MSG_FOUND=$(git log feature-a --oneline | grep -c "enable debug mode")
check "main's commit appears in feature-a history" \
  "$([[ "$MAIN_MSG_FOUND" -ge 1 ]] && echo pass || echo fail)"
check "feature-a's original commit still in history" \
  "$([[ "$FEAT_MSG_FOUND" -ge 1 ]] && echo pass || echo fail)"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
