# Exercise 0C-02: Dockerfile From Scratch

## Theory

A Dockerfile is a plain text recipe that Docker reads top to bottom to build an image. Each instruction (`FROM`, `RUN`, `COPY`, `WORKDIR`, `EXPOSE`, `CMD`) adds a new read-only layer. `FROM` must come first — it declares the base image everything else builds on. `WORKDIR` sets the current directory for all subsequent instructions and for processes at runtime. `COPY` transfers files from the build context (the directory you pass to `docker build`) into the image. `RUN` executes a shell command during the build, typically to install packages. `EXPOSE` documents which port the app listens on (it does not actually publish the port — that is done at `docker run` time). `CMD` defines the default command when no command is given to `docker run`.

Multi-stage builds use multiple `FROM` instructions in one Dockerfile. The early stages compile or package the application; a final lean stage copies only the finished artifact. This produces a small production image without build tools, source code, or intermediate files. For example you might compile a Go binary in a `golang` stage then copy just the binary into a `scratch` or `alpine` stage.

The **build context** is the directory tree Docker sends to the daemon when you run `docker build`. Everything in that directory is potentially available to `COPY`. A `.dockerignore` file (like `.gitignore`) lists paths to exclude from the context — keeping the context small speeds up builds and prevents accidentally including secrets or large local caches.

## Setup

The reset script creates the following files for you:

- `/tmp/devops-lab/0C-02/app/app.py` — a minimal Flask application
- `/tmp/devops-lab/0C-02/app/requirements.txt` — containing `flask`

Run `./reset.sh` to (re)create these files before starting.

## Tasks

Work directory: `/tmp/devops-lab/0C-02/`

**Task 1 — Write the Dockerfile**

Create `/tmp/devops-lab/0C-02/app/Dockerfile` with the following requirements:

- Base image: `python:3.12-slim`
- Set the working directory inside the image to `/app`
- Copy `requirements.txt` and run `pip install --no-cache-dir -r requirements.txt`
- Copy the rest of the application code
- Expose port `5000`
- Default command: run `app.py` with Python

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
```

**Task 2 — Build the image**

From the `app/` directory, build the image and tag it `lab-flask:latest`.

```bash
cd /tmp/devops-lab/0C-02/app
docker build -t lab-flask:latest .
```

**Task 3 — Run the container and verify it responds**

Run the image as a container named `lab-flask-app`, mapping port `5050` on your host to port `5000` inside the container. Then use `curl` to verify it returns `Hello, DevOps!`.

```bash
docker run -d --name lab-flask-app -p 5050:5000 lab-flask:latest
curl localhost:5050
```

## What Just Happened

Docker read your Dockerfile and executed each instruction in order, creating a new filesystem layer for each one. The final image is a stack of those layers. Copying `requirements.txt` before the rest of the code is a deliberate cache-busting strategy: if you only change `app.py`, Docker reuses the cached `pip install` layer and only re-executes `COPY . .` and later — saving significant build time. The container runs as an isolated process; port `5050` on your machine tunnels through to port `5000` inside it.

## Interview Question

**"What is a multi-stage build? Why would you use one?"**

A multi-stage build uses multiple `FROM` statements in a single Dockerfile. Each stage produces its own image, but only the final stage becomes the shipped image. You use it to separate build-time dependencies from the runtime image — for example, compiling a Go or Java application in a stage that has the full SDK, then copying only the compiled binary into a minimal `alpine` or `distroless` base. The result is a small, secure production image with no compiler, build tools, or source code.
