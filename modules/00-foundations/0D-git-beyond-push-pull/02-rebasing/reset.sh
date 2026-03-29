#!/usr/bin/env bash
# reset.sh — Exercise 0D-02: Rebasing
# Creates a repo with main (2 commits) and feature-b (4 messy commits)

WORK_DIR="/tmp/devops-lab/0D-02"

echo "Resetting exercise 0D-02..."

# Clean up previous run
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

REPO="$WORK_DIR/myproject"
git init "$REPO" -b main
cd "$REPO"

git config user.email "lab@devops-lab.local"
git config user.name "DevOps Lab"

# --- main: 2 commits ---
cat > README.md <<'EOF'
# My Project
A demo project for learning Git rebasing.
EOF
git add README.md
git commit -m "Initial commit: add README"

cat > app.py <<'EOF'
#!/usr/bin/env python3
# Main application

def main():
    print("Hello, world!")

if __name__ == "__main__":
    main()
EOF
git add app.py
git commit -m "Add main application entry point"

# --- feature-b: branch from here, 4 messy commits ---
git checkout -b feature-b

# Commit 1: fix typo
cat > utils.py <<'EOF'
#!/usr/bin/env python3
# Utility functions

def greet(name):
    return f"Hello, {name}!"
EOF
git add utils.py
git commit -m "fix typo in utils"

# Commit 2: add debug logging
cat > utils.py <<'EOF'
#!/usr/bin/env python3
# Utility functions
import logging

def greet(name):
    logging.debug(f"greet called with {name}")
    return f"Hello, {name}!"
EOF
git add utils.py
git commit -m "add debug logging to greet"

# Commit 3: remove debug logging (was a mistake)
cat > utils.py <<'EOF'
#!/usr/bin/env python3
# Utility functions

def greet(name):
    return f"Hello, {name}!"
EOF
git add utils.py
git commit -m "remove debug logging (oops)"

# Commit 4: actual feature — add farewell function
cat > utils.py <<'EOF'
#!/usr/bin/env python3
# Utility functions

def greet(name):
    return f"Hello, {name}!"

def farewell(name):
    return f"Goodbye, {name}!"
EOF
git add utils.py
git commit -m "feat: add farewell() utility function"

echo ""
echo "Setup complete. Repository at: $REPO"
echo ""
echo "Branch state:"
git log --oneline --graph --all
echo ""
echo "To start the exercise:"
echo "  cd $REPO"
echo "  git checkout feature-b"
echo "  git log --oneline"
