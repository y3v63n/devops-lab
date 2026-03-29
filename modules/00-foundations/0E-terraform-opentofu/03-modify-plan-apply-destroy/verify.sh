#!/usr/bin/env bash
# verify.sh — Exercise 0E-03: Modify, Plan, Apply, Destroy

WORK_DIR="/tmp/devops-lab/0E-03"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Exercise 0E-03 — Modify, Plan, Apply, Destroy"
echo ""

# ── Detect tofu/terraform ─────────────────────────────────────────────────────
TF_CMD=""
if command -v tofu &>/dev/null; then TF_CMD="tofu"
elif command -v terraform &>/dev/null; then TF_CMD="terraform"
fi

if [[ -n "$TF_CMD" ]]; then
  echo "  (using: $TF_CMD)"
else
  echo "  (note: neither 'tofu' nor 'terraform' found — checking file contents only)"
fi
echo ""

# ── main.tf was modified correctly ────────────────────────────────────────────
check "main.tf exists" \
  "$([[ -f "$WORK_DIR/main.tf" ]] && echo pass || echo fail)"

if [[ -f "$WORK_DIR/main.tf" ]]; then
  MAIN=$(cat "$WORK_DIR/main.tf")

  check "main.tf has a third local_file resource (deployment_notes)" \
    "$(echo "$MAIN" | grep -qi 'deployment_notes\|deployment-notes' && echo pass || echo fail)"

  # Count local_file resource blocks
  RESOURCE_COUNT=$(echo "$MAIN" | grep -c 'resource.*"local_file"')
  check "main.tf has 3 local_file resources (was 2, added 1)" \
    "$([[ $RESOURCE_COUNT -ge 3 ]] && echo pass || echo fail)"
fi

# ── variables.tf: environment changed to staging ──────────────────────────────
# (May be in main.tf or variables.tf depending on how student structures it)
COMBINED_CONFIG=""
[[ -f "$WORK_DIR/main.tf" ]] && COMBINED_CONFIG+=$(cat "$WORK_DIR/main.tf")
[[ -f "$WORK_DIR/variables.tf" ]] && COMBINED_CONFIG+=$(cat "$WORK_DIR/variables.tf")

check "environment default changed to 'staging'" \
  "$(echo "$COMBINED_CONFIG" | grep -q 'staging' && echo pass || echo fail)"

# ── .terraform directory and lock file ───────────────────────────────────────
check ".terraform/ directory exists (init was run)" \
  "$([[ -d "$WORK_DIR/.terraform" ]] && echo pass || echo fail)"

# ── plan-output.txt ───────────────────────────────────────────────────────────
check "plan-output.txt exists" \
  "$([[ -f "$WORK_DIR/plan-output.txt" ]] && echo pass || echo fail)"

if [[ -f "$WORK_DIR/plan-output.txt" ]]; then
  PLAN=$(cat "$WORK_DIR/plan-output.txt")

  # Should show at least 1 add and 1 change
  check "plan-output.txt shows 1 resource to add" \
    "$(echo "$PLAN" | grep -qE '1 to add|Plan:.*1.*add' && echo pass || echo fail)"

  check "plan-output.txt shows 1 resource to change (environment update)" \
    "$(echo "$PLAN" | grep -qE '1 to change|Plan:.*1.*change' && echo pass || echo fail)"

  check "plan-output.txt shows no errors" \
    "$(echo "$PLAN" | grep -qiE '^Error|^╷' && echo fail || echo pass)"
fi

# ── State file reflects operations ────────────────────────────────────────────
# After destroy, state should exist but be empty (or show 0 resources)
if [[ -f "$WORK_DIR/terraform.tfstate" ]]; then
  STATE=$(cat "$WORK_DIR/terraform.tfstate")

  # Check if destroy was run — state should show 0 resources or serial > 1
  SERIAL=$(echo "$STATE" | grep '"serial"' | grep -oE '[0-9]+' | head -1)
  check "terraform state file exists and has been modified (serial > 0)" \
    "$([[ -n "$SERIAL" && "$SERIAL" -gt 0 ]] && echo pass || echo fail)"

  # After destroy, resources array should be empty
  RESOURCE_ENTRIES=$(echo "$STATE" | grep -c '"mode"' || true)
  check "terraform state shows 0 resources after destroy" \
    "$([[ "$RESOURCE_ENTRIES" -eq 0 ]] && echo pass || echo fail)"
else
  check "terraform state file exists" fail
  check "terraform state shows 0 resources after destroy" fail
fi

# ── Output files should NOT exist (destroy removed them) ─────────────────────
check "output/config.json does NOT exist (destroyed)" \
  "$([[ ! -f "$WORK_DIR/output/config.json" ]] && echo pass || echo fail)"

check "output/README.md does NOT exist (destroyed)" \
  "$([[ ! -f "$WORK_DIR/output/README.md" ]] && echo pass || echo fail)"

check "output/deployment-notes.txt does NOT exist (destroyed)" \
  "$([[ ! -f "$WORK_DIR/output/deployment-notes.txt" ]] && echo pass || echo fail)"

# ── lifecycle-notes.txt ───────────────────────────────────────────────────────
check "lifecycle-notes.txt exists" \
  "$([[ -f "$WORK_DIR/lifecycle-notes.txt" ]] && echo pass || echo fail)"

if [[ -f "$WORK_DIR/lifecycle-notes.txt" ]]; then
  NOTES=$(cat "$WORK_DIR/lifecycle-notes.txt")
  LINE_COUNT=$(wc -l < "$WORK_DIR/lifecycle-notes.txt")

  check "lifecycle-notes.txt has substantial content (8+ lines)" \
    "$([[ $LINE_COUNT -ge 8 ]] && echo pass || echo fail)"

  check "lifecycle-notes.txt mentions 'plan'" \
    "$(echo "$NOTES" | grep -qi 'plan' && echo pass || echo fail)"

  check "lifecycle-notes.txt mentions 'apply'" \
    "$(echo "$NOTES" | grep -qi 'apply' && echo pass || echo fail)"

  check "lifecycle-notes.txt mentions 'destroy'" \
    "$(echo "$NOTES" | grep -qi 'destroy' && echo pass || echo fail)"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [[ -z "$TF_CMD" ]]; then
  echo ""
  echo "Note: Install OpenTofu to complete Tasks 2-4:"
  echo "  curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh | sh -s -- --install-method standalone"
fi

[[ $FAIL -eq 0 ]]
