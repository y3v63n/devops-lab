#!/usr/bin/env bash
# verify.sh — Exercise 0E-02: Writing a Terraform Configuration

WORK_DIR="/tmp/devops-lab/0E-02"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Exercise 0E-02 — Writing a Terraform Configuration"
echo ""

# ── Check for tofu/terraform ──────────────────────────────────────────────────
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

# ── main.tf ───────────────────────────────────────────────────────────────────
check "main.tf exists" \
  "$([[ -f "$WORK_DIR/main.tf" ]] && echo pass || echo fail)"

if [[ -f "$WORK_DIR/main.tf" ]]; then
  MAIN=$(cat "$WORK_DIR/main.tf")

  check "main.tf has terraform {} block with local provider" \
    "$(echo "$MAIN" | grep -q 'hashicorp/local' && echo pass || echo fail)"

  check "main.tf has local_file resource named config_json" \
    "$(echo "$MAIN" | grep -q 'local_file.*config_json\|local_file" "config_json' && echo pass || echo fail)"

  check "main.tf has local_file resource named readme" \
    "$(echo "$MAIN" | grep -qi 'local_file.*readme\|local_file" "readme' && echo pass || echo fail)"

  check "main.tf references var.project_name" \
    "$(echo "$MAIN" | grep -q 'var\.project_name' && echo pass || echo fail)"

  check "main.tf references var.environment" \
    "$(echo "$MAIN" | grep -q 'var\.environment' && echo pass || echo fail)"

  check "main.tf has AWS equivalent comment" \
    "$(echo "$MAIN" | grep -qi 'aws\|# aws\|AWS' && echo pass || echo fail)"
fi

# ── variables.tf ──────────────────────────────────────────────────────────────
check "variables.tf exists" \
  "$([[ -f "$WORK_DIR/variables.tf" ]] && echo pass || echo fail)"

if [[ -f "$WORK_DIR/variables.tf" ]]; then
  VARS=$(cat "$WORK_DIR/variables.tf")

  check "variables.tf declares project_name variable" \
    "$(echo "$VARS" | grep -q 'variable.*project_name' && echo pass || echo fail)"

  check "variables.tf declares environment variable" \
    "$(echo "$VARS" | grep -q 'variable.*environment' && echo pass || echo fail)"

  check "project_name has default 'devops-lab'" \
    "$(echo "$VARS" | grep -q 'devops-lab' && echo pass || echo fail)"

  check "environment has a default value" \
    "$(echo "$VARS" | grep -q 'default' && echo pass || echo fail)"
fi

# ── outputs.tf ────────────────────────────────────────────────────────────────
check "outputs.tf exists" \
  "$([[ -f "$WORK_DIR/outputs.tf" ]] && echo pass || echo fail)"

if [[ -f "$WORK_DIR/outputs.tf" ]]; then
  OUTS=$(cat "$WORK_DIR/outputs.tf")

  check "outputs.tf has at least 2 output blocks" \
    "$(echo "$OUTS" | grep -c '^output' | xargs -I{} bash -c '[[ {} -ge 2 ]] && echo pass || echo fail')"
fi

# ── terraform init ran (.terraform dir exists) ────────────────────────────────
check ".terraform/ directory exists (init was run)" \
  "$([[ -d "$WORK_DIR/.terraform" ]] && echo pass || echo fail)"

check ".terraform.lock.hcl exists" \
  "$([[ -f "$WORK_DIR/.terraform.lock.hcl" ]] && echo pass || echo fail)"

# ── plan-output.txt ───────────────────────────────────────────────────────────
check "plan-output.txt exists" \
  "$([[ -f "$WORK_DIR/plan-output.txt" ]] && echo pass || echo fail)"

if [[ -f "$WORK_DIR/plan-output.txt" ]]; then
  PLAN=$(cat "$WORK_DIR/plan-output.txt")

  check "plan-output.txt shows 2 resources to add" \
    "$(echo "$PLAN" | grep -qE '2 to add|Plan: 2' && echo pass || echo fail)"

  check "plan-output.txt shows no errors" \
    "$(echo "$PLAN" | grep -qiE '^(Error|╷)' && echo fail || echo pass)"
fi

# ── If tofu/terraform available, validate the config ─────────────────────────
if [[ -n "$TF_CMD" && -d "$WORK_DIR/.terraform" ]]; then
  VALIDATE_OUT=$(cd "$WORK_DIR" && $TF_CMD validate 2>&1)
  check "terraform validate passes" \
    "$(echo "$VALIDATE_OUT" | grep -q 'Success' && echo pass || echo fail)"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [[ -z "$TF_CMD" ]]; then
  echo ""
  echo "Note: Install OpenTofu to complete Tasks 2 and 3:"
  echo "  curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh | sh -s -- --install-method standalone"
fi

[[ $FAIL -eq 0 ]]
