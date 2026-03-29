# Hints — Exercise 0C-05: Docker Troubleshooting

## Task 1 & 2 — Start and diagnose

**Hint 1:** After running `docker compose up -d`, use `docker compose ps` to see the state of all services. Services showing `Exit` or `Restarting` have problems.

**Hint 2:** For each failing service, read its logs:
```bash
docker compose logs web
docker compose logs api
docker compose logs db
```
The error message in the log almost always tells you what is wrong.

**Hint 3:** If a service never started (pull failed), the error appears in the `docker compose up` terminal output, not in `docker compose logs`. Look for `Error response from daemon: manifest for ... not found`.

---

## Bug 1 — web port mapping

**Hint 1:** The web service runs a Python HTTP server. What port does `python -m http.server 8080` listen on?

**Hint 2:** A port mapping `"80:8080"` means host port 80 → container port 8080. But the verify script checks port 8080 on the host. What should the mapping be?

**Hint 3:** Change the ports line in docker-compose.yml:
```yaml
ports:
  - "8080:8080"
```

---

## Bug 2 — api missing environment variable

**Hint 1:** Run `docker compose logs api`. You should see an error message from the entrypoint script about a missing variable.

**Hint 2:** The logs will say something like `ERROR: Required environment variable API_SECRET is not set`. Add it to the compose file.

**Hint 3:** Find the `api` service in docker-compose.yml. Add an `environment` block:
```yaml
api:
  build:
    context: ./api
  environment:
    API_SECRET: fixed
  networks:
    - app-net
```

---

## Bug 3 — db bad image tag

**Hint 1:** When `docker compose up` runs, Docker tries to pull `postgres:99.0`. Does that tag exist?

**Hint 2:** Search Docker Hub for available PostgreSQL tags. The standard stable tag is `postgres:16-alpine` or simply `postgres:16`.

**Hint 3:** Change the db service image:
```yaml
db:
  image: postgres:16-alpine
```

---

## Task 4 & 5 — Fix and verify

**After making all fixes:**
```bash
cd /tmp/devops-lab/0C-05
docker compose up -d
docker compose ps
```

All three services should show `Up` status. Then write your diagnosis:
```bash
cat > /tmp/devops-lab/0C-05/diagnosis.txt << 'EOF'
Issue 1 (web): Port mapping was 80:8080 but verify checks port 8080 on the host. Fixed: changed to 8080:8080.
Issue 2 (api): Missing required environment variable API_SECRET. Entrypoint exited with error. Fixed: added API_SECRET=fixed to environment section.
Issue 3 (db): Image postgres:99.0 does not exist. Docker could not pull it. Fixed: changed to postgres:16-alpine.
EOF
```
