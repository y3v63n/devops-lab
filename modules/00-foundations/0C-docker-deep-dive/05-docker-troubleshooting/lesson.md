# Exercise 0C-05: Docker Troubleshooting

## Theory

Debugging a broken Docker setup is a systematic process. Start with the highest-level view and work inward. `docker compose ps` shows you which services are running, stopped, or restarting. `docker compose logs <service>` streams the application output — most crashes print their error before dying. `docker inspect <container>` gives you the full JSON configuration: environment variables, port bindings, mounts, and exit codes. `docker compose events` streams a live feed of Docker daemon events (container start, die, health_status) — useful for watching a flapping container in real time. `docker exec -it <container> sh` lets you get a shell inside a running container to poke around manually.

The three most common failure categories are: **configuration errors** (wrong port, missing environment variable, misspelled image name or tag), **dependency errors** (service starts before its dependency is ready), and **resource errors** (port already in use, volume permission denied, out of disk space). Configuration errors usually surface as immediate exits with a clear error in the logs. Dependency errors cause intermittent failures or crash-loop-backoffs. Resource errors produce OS-level messages like `bind: address already in use`.

When a container keeps restarting, check its exit code with `docker inspect <container> --format "{{.State.ExitCode}}"`. Exit code `1` typically means the application crashed. Exit code `127` means the command was not found. Exit code `137` means the container was OOM-killed. Combining the exit code with the last lines of `docker logs` usually identifies the root cause quickly.

## Setup

The reset script creates a deliberately broken compose setup at `/tmp/devops-lab/0C-05/`. Run `./reset.sh` first to put the broken files in place.

The setup contains three broken services:
1. **web** — port mapping is wrong (maps port 80, but the app listens on port 8080)
2. **api** — missing a required environment variable that the entrypoint script checks for
3. **db** — uses a non-existent image tag (`postgres:99.0`)

## Tasks

Work directory: `/tmp/devops-lab/0C-05/`

**Task 1 — Try to start the broken stack**

```bash
cd /tmp/devops-lab/0C-05
docker compose up -d
```

Observe which services fail. Do not fix anything yet.

**Task 2 — Diagnose each issue**

Use the following tools to understand what is wrong with each service:

```bash
# See overall status
docker compose ps

# Check logs for each failing service
docker compose logs web
docker compose logs api
docker compose logs db

# Inspect a container's configuration
docker inspect 0c-05-api-1
docker inspect 0c-05-web-1
```

For `db`, the failure is at the pull/create stage — check the compose output or `docker compose logs db`.

**Task 3 — Fix the docker-compose.yml**

Edit `/tmp/devops-lab/0C-05/docker-compose.yml` to fix all three issues:

1. **web**: Change the port mapping from `"80:8080"` to `"8080:8080"`
2. **api**: Add the missing environment variable `API_SECRET=fixed`
3. **db**: Change the image from `postgres:99.0` to `postgres:16-alpine`

**Task 4 — Bring the fixed stack up**

```bash
cd /tmp/devops-lab/0C-05
docker compose up -d
```

Verify all services are running:
```bash
docker compose ps
```

**Task 5 — Write your diagnosis**

Write what was wrong and how you fixed it to `/tmp/devops-lab/0C-05/diagnosis.txt`:

```bash
cat > /tmp/devops-lab/0C-05/diagnosis.txt << 'EOF'
Issue 1 (web): Port mapping was 80:8080 but the app listens on 8080, so curl to port 80 got connection refused. Fixed by changing port mapping to 8080:8080.
Issue 2 (api): Missing required environment variable API_SECRET. The entrypoint script exited with an error when the variable was absent. Fixed by adding API_SECRET=fixed to the environment section.
Issue 3 (db): Image postgres:99.0 does not exist on Docker Hub. Docker could not pull it. Fixed by changing the image tag to postgres:16-alpine.
EOF
```

## What Just Happened

You used the standard Docker debugging workflow: start at the top (`compose ps`), look at logs to understand exit reasons, inspect configuration for missing values or wrong settings, then fix and re-deploy. The broken setup represented three real-world failure modes. Wrong port mappings are common when an app is reconfigured to listen on a different port but the compose file is not updated. Missing environment variables are the most frequent cause of API service crashes in production — applications should validate their config at startup and exit clearly. Non-existent image tags cause pull failures; always use specific, verified tags rather than `latest` in production.

## Interview Question

**"A container keeps restarting. Walk me through how you would diagnose the issue."**

First, `docker compose ps` or `docker ps -a` to confirm the restart loop and get the container name. Then `docker logs <container>` to see the last error output before it died. Check the exit code with `docker inspect <container> --format "{{.State.ExitCode}}"` — exit 1 is an app crash, 127 is command not found, 137 is OOM kill. If the logs show a missing environment variable or config file, add the variable or fix the mount. If it shows a connection refused, the dependency service may not be ready — add a healthcheck and `depends_on: condition: service_healthy`. If it is an OOM kill, increase the container's memory limit or optimize the application. Once you have a hypothesis, `docker exec -it <container> sh` (or override the entrypoint) to get a shell and reproduce the issue interactively.
