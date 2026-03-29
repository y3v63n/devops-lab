# Exercise 0C-03: Docker Networking

## Theory

Docker provides several network drivers. The **bridge** driver is the default: Docker creates a virtual switch on your host, and containers attached to the same bridge can talk to each other via IP. The default bridge network (`bridge`) gives containers IP addresses but does not give them DNS names — you can only reach other containers by IP. A **custom bridge network** you create yourself enables automatic DNS: containers refer to each other by their container name or network alias, and Docker's built-in DNS resolver handles the lookup. The **host** driver removes network isolation entirely — the container shares the host's network stack. The **none** driver gives the container no network access at all.

When you create a custom bridge network, Docker allocates a subnet for it (e.g. `172.20.0.0/16`) and assigns each container an IP from that range. Docker also runs an embedded DNS server at `127.0.0.11` inside each container. When a container on a custom network tries to resolve `net-pong`, the DNS server looks up which container on the same network has that name and returns its IP. This is why containers on custom networks can ping each other by name without any `/etc/hosts` editing.

You inspect networks with `docker network inspect <name>`, which returns JSON describing the network's configuration, attached containers, and their IP addresses. The `Subnet` field inside `IPAM.Config` is the CIDR range for the network.

## Tasks

Work directory: `/tmp/devops-lab/0C-03/`

**Task 1 — Create a custom bridge network**

Create a Docker network named `lab-net`.

```bash
mkdir -p /tmp/devops-lab/0C-03
docker network create lab-net
```

**Task 2 — Run two containers on the network**

Run two `alpine:latest` containers named `net-ping` and `net-pong`, both attached to `lab-net`, in detached mode running `sleep 300`.

```bash
docker run -d --name net-ping --network lab-net alpine:latest sleep 300
docker run -d --name net-pong --network lab-net alpine:latest sleep 300
```

**Task 3 — Ping by name and record the output**

From the `net-ping` container, ping `net-pong` by name (3 packets). Write the ping output to `/tmp/devops-lab/0C-03/ping-result.txt`.

```bash
docker exec net-ping ping -c 3 net-pong | tee /tmp/devops-lab/0C-03/ping-result.txt
```

**Task 4 — Record the network subnet**

Inspect the `lab-net` network and write the subnet CIDR to `/tmp/devops-lab/0C-03/subnet.txt`.

```bash
docker network inspect lab-net --format "{{range .IPAM.Config}}{{.Subnet}}{{end}}" \
  > /tmp/devops-lab/0C-03/subnet.txt
```

## What Just Happened

On the default `bridge` network, `net-ping` would not be able to resolve the hostname `net-pong` — you would get `bad address`. On your custom `lab-net` network, Docker's embedded DNS server automatically registers `net-ping` and `net-pong` as hostnames. When `net-ping` ran `ping net-pong`, the libc resolver inside the container queried `127.0.0.11:53`, which Docker answered with `net-pong`'s IP on the `lab-net` subnet. This is the foundation of service discovery in docker compose: each service name is a DNS name that other services can use.

## Interview Question

**"How does Docker DNS work? How do containers on the same network resolve each other's names?"**

Docker runs an embedded DNS server at the virtual IP `127.0.0.11` inside every container that is connected to a custom network. When the container tries to resolve a hostname, its `/etc/resolv.conf` points to that address. The Docker daemon handles the query: it looks up which containers are on the same custom network and returns the matching container's IP. Containers on the default `bridge` network do not get this service — name-based discovery requires a user-defined network. This is why `docker compose` always creates a project-specific network and why services can refer to each other simply by their service name.
