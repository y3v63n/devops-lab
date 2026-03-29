#!/usr/bin/env bash
# reset.sh — Exercise 0D-01: Branching and Merging
# Creates a repo with a conflict scenario between main and feature-a

WORK_DIR="/tmp/devops-lab/0D-01"

echo "Resetting exercise 0D-01..."

# Clean up previous run
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

REPO="$WORK_DIR/myproject"
git init "$REPO" -b main
cd "$REPO"

git config user.email "lab@devops-lab.local"
git config user.name "DevOps Lab"

# --- Commit 1: initial files (this is the common ancestor) ---
cat > README.md <<'EOF'
# My Project
A demo project for learning Git branching and merging.
EOF

cat > config.txt <<'EOF'
# Project configuration
app=myapp
version=1.0
debug=false
EOF

git add README.md config.txt
git commit -m "Initial commit: add README and config"

# Save the SHA of the common ancestor
ANCESTOR_SHA=$(git rev-parse HEAD)

# --- Create feature-a branch from the initial commit ---
git checkout -b feature-a

cat > config.txt <<'EOF'
# Project configuration
app=myapp
version=feature
debug=true
log_level=verbose
EOF

git add config.txt
git commit -m "feature-a: enable debug mode and verbose logging"

# --- Go back to main and make a conflicting change ---
git checkout main

cat > config.txt <<'EOF'
# Project configuration
app=myapp
version=2.0
debug=false
max_connections=100
EOF

git add config.txt
git commit -m "main: bump version to 2.0 and add max_connections"

echo ""
echo "Setup complete. Repository at: $REPO"
echo ""
echo "Branch state:"
git log --oneline --graph --all
echo ""
echo "To start the exercise:"
echo "  cd $REPO"
echo "  git checkout feature-a"
