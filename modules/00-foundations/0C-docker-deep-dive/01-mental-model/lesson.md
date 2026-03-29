# Exercise 0C-01: Docker Mental Model

## Theory

Docker organizes software into four core primitives. An **image** is a read-only snapshot of a filesystem and metadata — think of it as a class or blueprint. A **container** is a running (or stopped) instance created from that image — the object instantiated from the class. Images are built from layers: each Dockerfile instruction adds a layer on top of the last, and layers are cached and shared across images to save disk space. A **volume** is a persistent storage area that lives outside any container's filesystem, so data survives container removal. A **network** connects containers together, controlling which ones can talk to each other.

The Docker lifecycle flows from image to container and back. `docker pull` fetches an image. `docker run` creates a new container from an image and starts it. `docker stop` signals a running container to shut down gracefully. `docker start` restarts a stopped container (unlike `run`, it does not create a new one). `docker rm` deletes the container record entirely. At any point `docker ps -a` shows all containers (running and stopped), while `docker images` lists local images.

Use the `docker` CLI when you are working with a single container or debugging. Use `docker compose` when you need multiple services to work together — it lets you declare the whole stack (services, networks, volumes) in one YAML file and start everything with a single command.

## Tasks

Work directory: `/tmp/devops-lab/0C-01/`

**Task 1 — Pull an image and record its ID**

Pull the `alpine:latest` image. Find its image ID (the short hash) using `docker images`. Write only the image ID to `/tmp/devops-lab/0C-01/image-id.txt`.

```bash
mkdir -p /tmp/devops-lab/0C-01
docker pull alpine:latest
docker images alpine:latest --format "{{.ID}}" > /tmp/devops-lab/0C-01/image-id.txt
```

**Task 2 — Run a container and record its ID**

Run a container from `alpine:latest` that prints `Hello from Docker` and exits. Capture the container ID using `docker ps -a` or the output of `docker run`. Write the container ID to `/tmp/devops-lab/0C-01/container-id.txt`.

```bash
docker run alpine:latest echo "Hello from Docker"
docker ps -a --filter ancestor=alpine --format "{{.ID}}" | head -1 > /tmp/devops-lab/0C-01/container-id.txt
```

**Task 3 — Run a named detached container**

Run a container with the name `lab-test` in detached mode (`-d`) that executes `sleep 300`. Confirm it is running with `docker ps`.

```bash
docker run -d --name lab-test alpine:latest sleep 300
docker ps
```

**Task 4 — Answer the questions**

Write answers to the following three questions in `/tmp/devops-lab/0C-01/answers.txt`, one answer per line:

1. What happens to data inside a container when you remove it?
2. What is the difference between `docker run` and `docker start`?
3. What is a Docker volume and why would you use one?

```bash
cat > /tmp/devops-lab/0C-01/answers.txt << 'EOF'
Data inside a container is lost when you remove it because the writable layer is deleted with the container.
docker run creates a brand new container from an image and starts it; docker start restarts an existing stopped container.
A Docker volume is persistent storage managed by Docker that exists outside the container filesystem, used to keep data alive across container restarts and removals.
EOF
```

## What Just Happened

You interacted with all four core Docker primitives. Pulling `alpine` downloaded a minimal Linux image (about 7 MB) made of a single compressed layer. Running it twice created two separate containers — each got its own writable filesystem layer on top of the shared read-only image. The `lab-test` container is still alive because `sleep 300` has not finished. The image itself is unchanged; containers never modify it.

## Interview Question

**"Explain the difference between a Docker image and a container. What is a layer?"**

An image is an immutable, layered filesystem snapshot used as a template. A container is a live process running in an isolated environment created from that image — it adds a thin writable layer on top. A layer is one incremental set of filesystem changes produced by a single Dockerfile instruction (like `RUN apt-get install` or `COPY`). Layers are cached and shared: if two images share the same base layers, Docker stores those layers only once on disk.
