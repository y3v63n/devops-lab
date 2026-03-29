#!/usr/bin/env bash
# reset.sh — Exercise 1A-01: Architecture Overview
# Clears all task output files so you can redo the exercise from scratch.

set -euo pipefail

WORK_DIR="/tmp/devops-lab/1A-01"

echo "Resetting exercise 1A-01..."

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

echo "  ✓ Removed $WORK_DIR and recreated it (empty)"
echo ""
echo "Ready. Re-run the tasks in lesson.md to complete the exercise."
