#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/0C-05"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then
    echo "  ✓ $desc"; PASS=$((PASS+1))
  else
    echo "  ✗ $desc"; FAIL=$((FAIL+1))
  fi
}

echo "Verifying: Exercise 0C-05 — Docker Troubleshooting"
echo ""

# docker-compose.yml exists
check "docker-compose.yml exists" \
  "$([[ -f "$WORK_DIR/docker-compose.yml" ]] && echo pass || echo fail)"

# All three services are running
web_running=$(docker ps --filter "name=0c-05-web" --filter "status=running" --format "{{.Names}}" 2>/dev/null | grep -c "web" || echo 0)
check "web service is running" \
  "$([[ "$web_running" -gt 0 ]] && echo pass || echo fail)"

api_running=$(docker ps --filter "name=0c-05-api" --filter "status=running" --format "{{.Names}}" 2>/dev/null | grep -c "api" || echo 0)
check "api service is running" \
  "$([[ "$api_running" -gt 0 ]] && echo pass || echo fail)"

db_running=$(docker ps --filter "name=0c-05-db" --filter "status=running" --format "{{.Names}}" 2>/dev/null | grep -c "db" || echo 0)
check "db service is running" \
  "$([[ "$db_running" -gt 0 ]] && echo pass || echo fail)"

# web responds on port 8080
echo "  (testing curl to localhost:8080)"
curl_status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:8080 2>/dev/null || echo "000")
check "web service responds on port 8080" \
  "$([[ "$curl_status" != "000" ]] && echo pass || echo fail)"

# Check that the compose file has the fixes applied
if [[ -f "$WORK_DIR/docker-compose.yml" ]]; then
  compose_content=$(cat "$WORK_DIR/docker-compose.yml")
  # Port fix: should NOT have "80:8080"
  check "web port mapping is fixed (not 80:8080)" \
    "$([[ "$compose_content" != *'"80:8080"'* && "$compose_content" != *"'80:8080'"* && "$compose_content" != *"- 80:8080"* ]] && echo pass || echo fail)"
  # API_SECRET env var present
  check "API_SECRET environment variable is present" \
    "$([[ "$compose_content" == *"API_SECRET"* ]] && echo pass || echo fail)"
  # Image tag fixed: should NOT have postgres:99.0
  check "db image tag is fixed (not postgres:99.0)" \
    "$([[ "$compose_content" != *"postgres:99.0"* ]] && echo pass || echo fail)"
fi

# diagnosis.txt exists and mentions all 3 issues
if [[ -f "$WORK_DIR/diagnosis.txt" ]]; then
  diag=$(cat "$WORK_DIR/diagnosis.txt")
  check "diagnosis.txt exists" "pass"
  check "diagnosis.txt mentions the port issue" \
    "$([[ "$diag" == *"port"* || "$diag" == *"Port"* || "$diag" == *"80"* ]] && echo pass || echo fail)"
  check "diagnosis.txt mentions the missing environment variable" \
    "$([[ "$diag" == *"API_SECRET"* || "$diag" == *"environment"* || "$diag" == *"variable"* ]] && echo pass || echo fail)"
  check "diagnosis.txt mentions the bad image tag" \
    "$([[ "$diag" == *"image"* || "$diag" == *"postgres"* || "$diag" == *"tag"* || "$diag" == *"99"* ]] && echo pass || echo fail)"
else
  check "diagnosis.txt exists" "fail"
  check "diagnosis.txt mentions the port issue" "fail"
  check "diagnosis.txt mentions the missing environment variable" "fail"
  check "diagnosis.txt mentions the bad image tag" "fail"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
