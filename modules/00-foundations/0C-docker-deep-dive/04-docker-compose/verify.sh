#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/0C-04"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then
    echo "  ✓ $desc"; PASS=$((PASS+1))
  else
    echo "  ✗ $desc"; FAIL=$((FAIL+1))
  fi
}

echo "Verifying: Exercise 0C-04 — Docker Compose"
echo ""

# docker-compose.yml exists
check "docker-compose.yml exists" \
  "$([[ -f "$WORK_DIR/docker-compose.yml" ]] && echo pass || echo fail)"

# Validate compose file content
if [[ -f "$WORK_DIR/docker-compose.yml" ]]; then
  compose_content=$(cat "$WORK_DIR/docker-compose.yml")
  check "compose file defines a redis service" \
    "$([[ "$compose_content" == *"redis"* ]] && echo pass || echo fail)"
  check "compose file defines a web service" \
    "$([[ "$compose_content" == *"web"* ]] && echo pass || echo fail)"
  check "compose file defines redis-data volume" \
    "$([[ "$compose_content" == *"redis-data"* ]] && echo pass || echo fail)"
  check "compose file defines app-net network" \
    "$([[ "$compose_content" == *"app-net"* ]] && echo pass || echo fail)"
  check "compose file has a healthcheck" \
    "$([[ "$compose_content" == *"healthcheck"* ]] && echo pass || echo fail)"
  check "compose file has depends_on" \
    "$([[ "$compose_content" == *"depends_on"* ]] && echo pass || echo fail)"
fi

# Both services running (using compose project name based on directory)
# Check container status by name pattern
redis_running=$(docker ps --filter "name=redis" --filter "status=running" --format "{{.Names}}" 2>/dev/null | grep -c "redis" || echo 0)
check "redis service container is running" \
  "$([[ "$redis_running" -gt 0 ]] && echo pass || echo fail)"

web_running=$(docker ps --filter "name=web" --filter "status=running" --format "{{.Names}}" 2>/dev/null | grep -c "web" || echo 0)
check "web service container is running" \
  "$([[ "$web_running" -gt 0 ]] && echo pass || echo fail)"

# Redis is healthy - check via compose if possible
redis_health=$(docker ps --filter "name=redis" --format "{{.Status}}" 2>/dev/null | grep -i "healthy" | head -1)
check "redis service is healthy" \
  "$([[ -n "$redis_health" ]] && echo pass || echo fail)"

# Web accessible on port 8080
echo "  (testing curl to localhost:8080 — may take a moment)"
curl_status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:8080 2>/dev/null || echo "000")
check "web service responds on port 8080" \
  "$([[ "$curl_status" != "000" ]] && echo pass || echo fail)"

# Named volume exists
volume_exists=$(docker volume inspect 0c-04_redis-data --format "{{.Name}}" 2>/dev/null \
  || docker volume inspect redis-data --format "{{.Name}}" 2>/dev/null \
  || docker volume ls --format "{{.Name}}" | grep "redis.data" | head -1 \
  || true)
check "redis-data volume exists" \
  "$([[ -n "$volume_exists" ]] && echo pass || echo fail)"

# Custom network exists
network_exists=$(docker network ls --format "{{.Name}}" | grep "app.net" | head -1 || true)
check "app-net network exists" \
  "$([[ -n "$network_exists" ]] && echo pass || echo fail)"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
