# Hints — Exercise 0C-03: Docker Networking

## Task 1 — Create a custom bridge network

**Hint 1:** Docker networks are created with `docker network create`. By default this creates a bridge-type network.

**Hint 2:** The command is:
```bash
docker network create lab-net
```
Verify it was created with:
```bash
docker network ls
```

---

## Task 2 — Run two containers on the network

**Hint 1:** To attach a container to a specific network, use the `--network` flag with `docker run`.

**Hint 2:** Run each container in detached mode (`-d`) with a specific name and `sleep 300` so they stay alive:
```bash
docker run -d --name net-ping --network lab-net alpine:latest sleep 300
docker run -d --name net-pong --network lab-net alpine:latest sleep 300
```

**Hint 3:** Verify both are running:
```bash
docker ps
```
Both `net-ping` and `net-pong` should appear.

---

## Task 3 — Ping by name and record output

**Hint 1:** Use `docker exec` to run a command inside a running container. The `-c 3` flag tells ping to send 3 packets.

**Hint 2:** The `tee` command writes output to both stdout and a file at the same time:
```bash
docker exec net-ping ping -c 3 net-pong | tee /tmp/devops-lab/0C-03/ping-result.txt
```

**Hint 3:** If ping says `bad address 'net-pong'`, both containers are probably not on the same custom network. Check with:
```bash
docker network inspect lab-net
```
Look for both container names under `"Containers"`.

---

## Task 4 — Record the subnet

**Hint 1:** `docker network inspect lab-net` returns a large JSON blob. You need the `Subnet` value inside `IPAM.Config`.

**Hint 2:** Use the `--format` flag to extract just the subnet:
```bash
docker network inspect lab-net --format "{{range .IPAM.Config}}{{.Subnet}}{{end}}"
```

**Hint 3:** Redirect that output into the file:
```bash
docker network inspect lab-net --format "{{range .IPAM.Config}}{{.Subnet}}{{end}}" \
  > /tmp/devops-lab/0C-03/subnet.txt
cat /tmp/devops-lab/0C-03/subnet.txt
```
It should look like `172.20.0.0/16` or similar.
