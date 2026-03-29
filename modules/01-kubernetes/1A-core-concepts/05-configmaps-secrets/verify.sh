#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1A-05"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then
    echo "  ✓ $desc"
    PASS=$((PASS+1))
  else
    echo "  ✗ $desc"
    FAIL=$((FAIL+1))
  fi
}

echo "Verifying: Exercise 1A-05 — ConfigMaps and Secrets"
echo ""

# Task 1: configmap.yaml
if [[ -f "$WORK_DIR/configmap.yaml" ]] && [[ -s "$WORK_DIR/configmap.yaml" ]]; then
  check "configmap.yaml exists and is non-empty" "pass"
else
  check "configmap.yaml exists and is non-empty" "fail"
fi

if grep -q "kind: ConfigMap" "$WORK_DIR/configmap.yaml" 2>/dev/null; then
  check "configmap.yaml has kind: ConfigMap" "pass"
else
  check "configmap.yaml has kind: ConfigMap" "fail"
fi

for key in DB_HOST DB_PORT LOG_LEVEL; do
  if grep -q "$key" "$WORK_DIR/configmap.yaml" 2>/dev/null; then
    check "configmap.yaml contains key $key" "pass"
  else
    check "configmap.yaml contains key $key" "fail"
  fi
done

# Task 2: secret.yaml
if [[ -f "$WORK_DIR/secret.yaml" ]] && [[ -s "$WORK_DIR/secret.yaml" ]]; then
  check "secret.yaml exists and is non-empty" "pass"
else
  check "secret.yaml exists and is non-empty" "fail"
fi

if grep -q "kind: Secret" "$WORK_DIR/secret.yaml" 2>/dev/null; then
  check "secret.yaml has kind: Secret" "pass"
else
  check "secret.yaml has kind: Secret" "fail"
fi

if grep -q "DB_PASSWORD" "$WORK_DIR/secret.yaml" 2>/dev/null; then
  check "secret.yaml contains DB_PASSWORD key" "pass"
else
  check "secret.yaml contains DB_PASSWORD key" "fail"
fi

# Verify value is base64 (not plaintext)
if grep -qv "superSecretPassword123" "$WORK_DIR/secret.yaml" 2>/dev/null || \
   grep -q "DB_PASSWORD:" "$WORK_DIR/secret.yaml" 2>/dev/null; then
  check "secret.yaml value appears encoded (not raw plaintext)" "pass"
else
  check "secret.yaml value appears encoded (not raw plaintext)" "fail"
fi

# Task 3: env-output.txt
if [[ -f "$WORK_DIR/env-output.txt" ]] && [[ -s "$WORK_DIR/env-output.txt" ]]; then
  check "env-output.txt exists and is non-empty" "pass"
else
  check "env-output.txt exists and is non-empty" "fail"
fi

if grep -q "DB_HOST=" "$WORK_DIR/env-output.txt" 2>/dev/null; then
  check "env-output.txt contains DB_HOST env var" "pass"
else
  check "env-output.txt contains DB_HOST env var" "fail"
fi

if grep -q "DB_PASSWORD=" "$WORK_DIR/env-output.txt" 2>/dev/null; then
  check "env-output.txt contains DB_PASSWORD env var" "pass"
else
  check "env-output.txt contains DB_PASSWORD env var" "fail"
fi

# Task 4: volume-mount.txt
if [[ -f "$WORK_DIR/volume-mount.txt" ]] && [[ -s "$WORK_DIR/volume-mount.txt" ]]; then
  check "volume-mount.txt exists and is non-empty" "pass"
else
  check "volume-mount.txt exists and is non-empty" "fail"
fi

for key in DB_HOST DB_PORT LOG_LEVEL; do
  if grep -q "$key" "$WORK_DIR/volume-mount.txt" 2>/dev/null; then
    check "volume-mount.txt shows file $key in /etc/config" "pass"
  else
    check "volume-mount.txt shows file $key in /etc/config" "fail"
  fi
done

# Bonus: live cluster checks
echo ""
echo "  [Bonus — requires live cluster]"
if kubectl cluster-info &>/dev/null; then
  if kubectl get configmap app-config &>/dev/null 2>&1; then
    check "ConfigMap app-config exists in cluster" "pass"
  else
    echo "  ~ ConfigMap app-config not found"
  fi
  if kubectl get secret app-secret &>/dev/null 2>&1; then
    check "Secret app-secret exists in cluster" "pass"
  else
    echo "  ~ Secret app-secret not found"
  fi
else
  echo "  ~ cluster unreachable — skipping live checks"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
