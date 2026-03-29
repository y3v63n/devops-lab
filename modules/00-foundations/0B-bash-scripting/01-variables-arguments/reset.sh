#!/usr/bin/env bash
# Reset script for exercise 0B-01
WORK_DIR="/tmp/devops-lab/0B-01"

echo "Resetting exercise 0B-01..."
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
echo "Done. Work directory cleared: $WORK_DIR"
