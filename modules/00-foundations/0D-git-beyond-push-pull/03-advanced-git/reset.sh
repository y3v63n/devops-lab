#!/usr/bin/env bash
# reset.sh — Exercise 0D-03: Advanced Git (cherry-pick, stash, reflog, bisect)

WORK_DIR="/tmp/devops-lab/0D-03"

echo "Resetting exercise 0D-03..."

# Clean up previous run
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

REPO="$WORK_DIR/myproject"
git init "$REPO" -b main
cd "$REPO"

git config user.email "lab@devops-lab.local"
git config user.name "DevOps Lab"

# ---------------------------------------------------------------
# main branch: 5 commits — one introduces a "bug"
# ---------------------------------------------------------------

# Commit 1 (v1.0 — known good)
cat > app.sh <<'EOF'
#!/usr/bin/env bash
# Simple app
STATUS="ok"
echo "App status: $STATUS"
EOF
chmod +x app.sh

cat > README.md <<'EOF'
# My Project
Advanced Git power tools demo.
EOF

git add app.sh README.md
git commit -m "Initial commit: add app and README"
git tag v1.0

# Commit 2 (still good)
cat > config.sh <<'EOF'
#!/usr/bin/env bash
MAX_RETRIES=3
TIMEOUT=30
EOF
git add config.sh
git commit -m "Add config defaults"

# Commit 3 — introduces the "bug" (STATUS changes to "broken")
cat > app.sh <<'EOF'
#!/usr/bin/env bash
# Simple app
STATUS="broken"
echo "App status: $STATUS"
EOF
git add app.sh
git commit -m "Refactor app status handling"

# Commit 4 (still bad, builds on broken commit)
cat > logger.sh <<'EOF'
#!/usr/bin/env bash
log() {
    echo "[$(date +%H:%M:%S)] $*"
}
EOF
git add logger.sh
git commit -m "Add logger utility"

# Commit 5 (still bad)
echo "# Changelog" > CHANGELOG.md
echo "- Added logger" >> CHANGELOG.md
git add CHANGELOG.md
git commit -m "Update changelog"

# ---------------------------------------------------------------
# test.sh — exits 0 if STATUS=ok, exits 1 if STATUS=broken
# ---------------------------------------------------------------
cat > test.sh <<'EOF'
#!/usr/bin/env bash
# Bisect test: exits 0 (good) if app.sh reports "ok", 1 (bad) if "broken"
source ./app.sh > /dev/null 2>&1
if [[ "$STATUS" == "ok" ]]; then
    exit 0
else
    exit 1
fi
EOF
chmod +x test.sh
git add test.sh
git commit -m "Add bisect test script"

# ---------------------------------------------------------------
# hotfix branch: one commit that patches something in README
# ---------------------------------------------------------------
git checkout -b hotfix

cat >> README.md <<'EOF'

## Security Note
Always validate user input before processing.
EOF

git add README.md
git commit -m "hotfix: add security note to README"

# Return to main
git checkout main

echo ""
echo "Setup complete. Repository at: $REPO"
echo ""
echo "Branch state:"
git log --oneline --graph --all
echo ""
echo "Tags:"
git tag
echo ""
echo "To start the exercise:"
echo "  cd $REPO"
