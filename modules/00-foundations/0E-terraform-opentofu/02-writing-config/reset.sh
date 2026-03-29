#!/usr/bin/env bash
# reset.sh — Exercise 0E-02: Writing a Terraform Configuration

WORK_DIR="/tmp/devops-lab/0E-02"

echo "Resetting exercise 0E-02..."

# Remove all previous work including terraform state and downloaded providers
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR/output"

echo ""
echo "Done. Work directory created: $WORK_DIR"
echo ""
echo "Your task: create the following files in $WORK_DIR:"
echo "  main.tf      — terraform block + 2 local_file resources"
echo "  variables.tf — project_name and environment variables"
echo "  outputs.tf   — outputs for both file paths"
echo ""
echo "Then run:"
echo "  cd $WORK_DIR && tofu init   (or: terraform init)"
echo "  tofu plan 2>&1 | tee $WORK_DIR/plan-output.txt"
