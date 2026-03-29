# Hints — Exercise 0C-01: Docker Mental Model

## Task 1 — Pull an image and record its ID

**Hint 1:** Use `docker pull alpine:latest` to download the image. Then check what you have with `docker images`.

**Hint 2:** `docker images` shows a table. The second column is the TAG, the third is IMAGE ID. You want just the ID value (e.g. `a606584aa9aa`).

**Hint 3:** Use Go template formatting to get just the ID:
```bash
docker images alpine:latest --format "{{.ID}}"
```
Redirect that output into the file.

---

## Task 2 — Run a container and record its ID

**Hint 1:** `docker run alpine:latest echo "Hello from Docker"` will print the message and exit immediately. You need the container's ID.

**Hint 2:** After running, the container still exists in a stopped state. See it with:
```bash
docker ps -a --filter ancestor=alpine
```

**Hint 3:** Use `--format "{{.ID}}"` with `docker ps -a` to get the raw ID, then write it to the file:
```bash
docker ps -a --filter ancestor=alpine --format "{{.ID}}" | head -1 > /tmp/devops-lab/0C-01/container-id.txt
```

---

## Task 3 — Run a named detached container

**Hint 1:** Two flags are needed: `--name lab-test` (assigns the name) and `-d` (detached, runs in background).

**Hint 2:** The full command is:
```bash
docker run -d --name lab-test alpine:latest sleep 300
```
After running it, `docker ps` should show `lab-test` in the list.

**Hint 3:** If you get an error saying the name is already in use, run:
```bash
docker rm -f lab-test
```
Then retry.

---

## Task 4 — Answer the questions

**Hint 1:** Open any text editor and write three lines — one answer per question. The verify script just checks that at least three non-empty lines exist.

**Hint 2:** You can write the file directly from the terminal:
```bash
cat > /tmp/devops-lab/0C-01/answers.txt << 'EOF'
Your answer to question 1 here
Your answer to question 2 here
Your answer to question 3 here
EOF
```

**Hint 3 (full answer):** Key points for each question:
1. Data is **lost** — the writable layer is deleted with the container.
2. `docker run` creates a **new** container from an image; `docker start` restarts an **existing** stopped container.
3. A volume is persistent Docker-managed storage outside the container — data survives container deletion.
