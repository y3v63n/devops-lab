# Hints — Exercise 0C-04: Docker Compose

## The docker-compose.yml

**Hint 1:** A compose file has four top-level keys you need: `services`, `volumes`, `networks`. Each service is a named block under `services`.

**Hint 2:** For `redis`, the healthcheck needs a `test` command, an `interval`, a `timeout`, and `retries`. Redis ships with `redis-cli`, so the test is `["CMD", "redis-cli", "ping"]`.

**Hint 3 (full solution):**
```yaml
services:
  redis:
    image: redis:alpine
    networks:
      - app-net
    volumes:
      - redis-data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

  web:
    image: python:3.12-slim
    command: python -m http.server 8080
    networks:
      - app-net
    ports:
      - "8080:8080"
    depends_on:
      redis:
        condition: service_healthy

volumes:
  redis-data:

networks:
  app-net:
```

Save this as `/tmp/devops-lab/0C-04/docker-compose.yml`.

---

## Running the stack

**Hint 1:** Change to the work directory first, then use `docker compose up -d`:
```bash
cd /tmp/devops-lab/0C-04
docker compose up -d
```

**Hint 2:** Watch the startup and check status:
```bash
docker compose ps
docker compose logs
```

**Hint 3:** The `web` service will not start until Redis is healthy. If it seems stuck, check Redis's health with:
```bash
docker ps
```
Look for `(healthy)` next to the redis container. It may take 15-30 seconds on first run.

---

## Troubleshooting

- If port 8080 is already in use, stop whatever is using it or change the host port to `8081:8080`.
- If `docker compose` says the file has errors, check YAML indentation — YAML is whitespace-sensitive.
- If the web container exits immediately, check `docker compose logs web` for the error.
