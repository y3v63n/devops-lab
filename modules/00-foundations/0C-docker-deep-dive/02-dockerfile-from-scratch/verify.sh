#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/0C-02"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then
    echo "  ✓ $desc"; PASS=$((PASS+1))
  else
    echo "  ✗ $desc"; FAIL=$((FAIL+1))
  fi
}

echo "Verifying: Exercise 0C-02 — Dockerfile From Scratch"
echo ""

# Task 1: Dockerfile exists
check "Dockerfile exists at app/Dockerfile" \
  "$([[ -f "$WORK_DIR/app/Dockerfile" ]] && echo pass || echo fail)"

# Task 1: Dockerfile has required instructions
if [[ -f "$WORK_DIR/app/Dockerfile" ]]; then
  df_content=$(cat "$WORK_DIR/app/Dockerfile")
  check "Dockerfile uses python:3.12-slim as base" \
    "$([[ "$df_content" == *"python:3.12-slim"* ]] && echo pass || echo fail)"
  check "Dockerfile sets WORKDIR" \
    "$([[ "$df_content" == *"WORKDIR"* ]] && echo pass || echo fail)"
  check "Dockerfile has EXPOSE instruction" \
    "$([[ "$df_content" == *"EXPOSE"* ]] && echo pass || echo fail)"
  check "Dockerfile has CMD instruction" \
    "$([[ "$df_content" == *"CMD"* ]] && echo pass || echo fail)"
else
  check "Dockerfile uses python:3.12-slim as base" "fail"
  check "Dockerfile sets WORKDIR" "fail"
  check "Dockerfile has EXPOSE instruction" "fail"
  check "Dockerfile has CMD instruction" "fail"
fi

# Task 2: lab-flask:latest image exists
flask_image=$(docker images lab-flask:latest --format "{{.ID}}" 2>/dev/null)
check "lab-flask:latest image exists" \
  "$([[ -n "$flask_image" ]] && echo pass || echo fail)"

# Task 3: lab-flask-app container is running
container_status=$(docker inspect --format "{{.State.Status}}" lab-flask-app 2>/dev/null)
check "lab-flask-app container is running" \
  "$([[ "$container_status" == "running" ]] && echo pass || echo fail)"

# Task 3: container responds on port 5050
echo "  (testing curl to localhost:5050 — may take a moment)"
curl_output=$(curl -s --max-time 5 http://localhost:5050 2>/dev/null || true)
check "curl localhost:5050 returns 'Hello, DevOps!'" \
  "$([[ "$curl_output" == *"Hello, DevOps!"* ]] && echo pass || echo fail)"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
