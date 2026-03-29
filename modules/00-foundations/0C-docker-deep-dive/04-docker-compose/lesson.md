# Exercise 0C-04: Docker Compose

## Theory

`docker compose` manages multi-container applications defined in a YAML file. Where `docker run` is an imperative one-liner, `docker-compose.yml` is a declarative description of the entire stack: each service gets its image, environment variables, port mappings, volume mounts, network attachments, and startup conditions. Running `docker compose up -d` creates and starts everything together; `docker compose down` tears it all down. The compose file also defines named **volumes** and **networks** under top-level keys — these are created automatically and shared across services.

The `depends_on` key tells compose the order in which to start services. By default it only waits for the dependency container to *exist*, not for the application inside it to be healthy. A **healthcheck** runs a command inside the container on a schedule (e.g. `redis-cli ping`) and marks the container `healthy` once the command succeeds consistently. For true readiness-gating, combine `depends_on` with `condition: service_healthy`: compose then waits for the dependency's healthcheck to pass before starting the dependent service.

Named volumes declared under the top-level `volumes:` key persist across `docker compose down`. If you want to also remove volumes when tearing down, use `docker compose down -v`. Named networks under `networks:` allow services to communicate by their service name, similar to user-defined bridge networks in the bare Docker CLI.

## Tasks

Work directory: `/tmp/devops-lab/0C-04/`

**Task — Write and run the docker-compose.yml**

Create `/tmp/devops-lab/0C-04/docker-compose.yml` that defines:

1. A `redis` service using `redis:alpine` with:
   - A healthcheck that runs `redis-cli ping`
   - The named volume `redis-data` mounted at `/data`
   - Attached to the custom network `app-net`

2. A `web` service using `python:3.12-slim` that:
   - Runs a simple HTTP server on port 8080: `python -m http.server 8080`
   - Depends on `redis` with `condition: service_healthy`
   - Maps host port `8080` to container port `8080`
   - Attached to the custom network `app-net`

3. A named volume `redis-data`

4. A custom network `app-net`

Then bring the stack up:

```bash
cd /tmp/devops-lab/0C-04
docker compose up -d
```

**Example docker-compose.yml:**

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

## What Just Happened

Compose read the YAML, created the `app-net` network and `redis-data` volume, then started the `redis` container. It waited for Redis's healthcheck (`redis-cli ping`) to return `PONG` before starting `web`. Both services joined `app-net`, so the `web` container could reach Redis at the hostname `redis` if needed. The `web` service runs Python's built-in HTTP server — a simple way to verify a container is alive without needing a full app. Data written by Redis to `/data` goes into the `redis-data` volume and survives `docker compose down` (but not `docker compose down -v`).

## Interview Question

**"What is the difference between `depends_on` and a healthcheck? When do you need both?"**

`depends_on` controls *start order*: compose starts the dependency service before the dependent one. With the default condition (`service_started`), it only waits until the container process has launched — not until the app inside is ready. A healthcheck is a command Docker runs periodically inside the container to determine whether the application is actually responding. You need both when your dependent service (e.g. a web app) will crash or fail to initialize if the dependency (e.g. a database) is not yet accepting connections. Use `depends_on` with `condition: service_healthy` so compose waits until the healthcheck passes before starting the dependent service.
