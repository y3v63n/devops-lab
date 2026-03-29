#!/usr/bin/env bash
# verify.sh — Exercise 0E-01: Reading Terraform Config Files

WORK_DIR="/tmp/devops-lab/0E-01"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Exercise 0E-01 — Reading Terraform Config Files"
echo ""

# ── Sample config exists ──────────────────────────────────────────────────────
check "sample-config/main.tf exists" \
  "$([[ -f "$WORK_DIR/sample-config/main.tf" ]] && echo pass || echo fail)"

check "sample-config/variables.tf exists" \
  "$([[ -f "$WORK_DIR/sample-config/variables.tf" ]] && echo pass || echo fail)"

# ── annotations.txt exists and has content ────────────────────────────────────
check "annotations.txt file exists" \
  "$([[ -f "$WORK_DIR/annotations.txt" ]] && echo pass || echo fail)"

if [[ -f "$WORK_DIR/annotations.txt" ]]; then
  ANNOT=$(cat "$WORK_DIR/annotations.txt")

  # Must mention exactly 1 provider (aws)
  if echo "$ANNOT" | grep -qi "aws"; then
    check "annotations.txt mentions the aws provider" pass
  else
    check "annotations.txt mentions the aws provider" fail
  fi

  # Must mention correct resource count (3) or list all three resource types
  if echo "$ANNOT" | grep -qiE "(3 resource|three resource|aws_instance|aws_security_group|aws_key_pair)"; then
    check "annotations.txt identifies resources (aws_instance, aws_security_group, aws_key_pair)" pass
  else
    check "annotations.txt identifies resources (aws_instance, aws_security_group, aws_key_pair)" fail
  fi

  # Must identify ami_id as required (no default)
  if echo "$ANNOT" | grep -qi "ami_id"; then
    check "annotations.txt identifies ami_id as required variable" pass
  else
    check "annotations.txt identifies ami_id as required variable" fail
  fi

  # Must mention outputs
  if echo "$ANNOT" | grep -qiE "(output|instance_ip|security_group_id)"; then
    check "annotations.txt describes the outputs" pass
  else
    check "annotations.txt describes the outputs" fail
  fi

  # Must mention at least one resource dependency reference
  if echo "$ANNOT" | grep -qiE "(depend|reference|aws_key_pair\.deployer|aws_security_group\.web)"; then
    check "annotations.txt identifies at least one resource dependency" pass
  else
    check "annotations.txt identifies at least one resource dependency" fail
  fi
else
  check "annotations.txt mentions the aws provider" fail
  check "annotations.txt identifies resources (aws_instance, aws_security_group, aws_key_pair)" fail
  check "annotations.txt identifies ami_id as required variable" fail
  check "annotations.txt describes the outputs" fail
  check "annotations.txt identifies at least one resource dependency" fail
fi

# ── security-review.txt exists and has 2+ concerns ───────────────────────────
check "security-review.txt file exists" \
  "$([[ -f "$WORK_DIR/security-review.txt" ]] && echo pass || echo fail)"

if [[ -f "$WORK_DIR/security-review.txt" ]]; then
  SEC=$(cat "$WORK_DIR/security-review.txt")
  LINE_COUNT=$(wc -l < "$WORK_DIR/security-review.txt")

  # Must have at least 10 lines (enough to cover 2 concerns with explanation)
  check "security-review.txt has substantial content (10+ lines)" \
    "$([[ $LINE_COUNT -ge 10 ]] && echo pass || echo fail)"

  # Must mention SSH or port 22 exposure
  if echo "$SEC" | grep -qiE "(ssh|port 22|0\.0\.0\.0/0.*22|22.*0\.0\.0\.0)"; then
    check "security-review.txt identifies SSH/port 22 exposure to 0.0.0.0/0" pass
  else
    check "security-review.txt identifies SSH/port 22 exposure to 0.0.0.0/0" fail
  fi

  # Must mention at least one other concern (key path, no encryption, broad egress, no VPC, etc.)
  if echo "$SEC" | grep -qiE "(key|encrypt|egress|vpc|public_key|hardcod|versioning|state|lock|tag|imds|metadata)"; then
    check "security-review.txt identifies a second security concern" pass
  else
    check "security-review.txt identifies a second security concern" fail
  fi
else
  check "security-review.txt has substantial content (10+ lines)" fail
  check "security-review.txt identifies SSH/port 22 exposure to 0.0.0.0/0" fail
  check "security-review.txt identifies a second security concern" fail
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
