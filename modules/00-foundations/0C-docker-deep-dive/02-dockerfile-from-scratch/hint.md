# Hints — Exercise 0C-02: Dockerfile From Scratch

## Task 1 — Write the Dockerfile

**Hint 1:** A Dockerfile is a plain text file named exactly `Dockerfile` (no extension). Start with `FROM` to pick your base image.

**Hint 2:** The order of instructions matters for layer caching. Copy `requirements.txt` and install dependencies *before* copying the rest of the code. That way, if you only change `app.py`, Docker reuses the cached install layer.

**Hint 3 (full Dockerfile):**
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
```
Save this as `/tmp/devops-lab/0C-02/app/Dockerfile`.

---

## Task 2 — Build the image

**Hint 1:** `docker build` needs a tag (`-t`) and a build context (the directory to send to Docker). The `.` at the end means "current directory".

**Hint 2:** Make sure you are inside the `app/` directory so Docker can find the Dockerfile and the source files:
```bash
cd /tmp/devops-lab/0C-02/app
docker build -t lab-flask:latest .
```

**Hint 3:** If the build fails with a pip error, check your `requirements.txt` has `flask` on its own line with no extra whitespace. If it fails with "unable to find Dockerfile", make sure the Dockerfile is inside the `app/` directory, not the parent.

---

## Task 3 — Run and verify

**Hint 1:** You need three flags: `-d` (detached), `--name lab-flask-app`, and `-p 5050:5000` (host_port:container_port).

**Hint 2:** Full run command:
```bash
docker run -d --name lab-flask-app -p 5050:5000 lab-flask:latest
```

**Hint 3:** After starting the container, wait a moment and test:
```bash
curl localhost:5050
```
You should see `Hello, DevOps!`. If curl times out, check the container logs:
```bash
docker logs lab-flask-app
```
A common issue is the app crashing because Flask is not installed — rebuild the image and try again.
