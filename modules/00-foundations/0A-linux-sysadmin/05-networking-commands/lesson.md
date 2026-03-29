# 0A-05: Networking Commands

## Theory

Linux networking is built on **sockets** — kernel objects that represent a communication endpoint. Each socket has a protocol (TCP or UDP), a local address, a local port, and optionally a remote address and port. When a service **listens** on a port, it's waiting for incoming connections; when it **establishes** a connection, it's actively exchanging data. `ss` (socket statistics) is the modern replacement for `netstat` — it reads directly from the kernel socket tables and shows you everything that's listening or connected. `ip` is the modern replacement for `ifconfig` and `route` — it controls network interfaces, addresses, and routing.

A **network interface** is the kernel's abstraction for a network connection — whether physical (eth0, ens3) or virtual (lo for loopback, docker0 for container networking). Each interface can have one or more IP addresses. The **routing table** tells the kernel which interface to use for each destination — the **default gateway** is the catch-all: traffic that doesn't match a more specific route gets sent there (usually your router). Understanding this mental model — interfaces have addresses, routes determine which interface to use — is how you debug connectivity from first principles.

---

## Tasks

### Task 1: Find All Listening TCP Ports

1. Create your work directory:
   ```bash
   mkdir -p /tmp/devops-lab/0A-05
   ```

2. Use `ss` to show listening TCP sockets:
   ```bash
   ss -tlnp
   ```
   Flags: `-t` TCP, `-l` listening only, `-n` numeric (no DNS), `-p` show process

3. Write the full output to the file:
   ```bash
   ss -tlnp > /tmp/devops-lab/0A-05/listening-ports.txt
   ```

---

### Task 2: Find Your Primary IP Address

1. Use `ip addr` to see all interfaces and addresses:
   ```bash
   ip addr show
   ```

2. Find the non-loopback IP (not 127.0.0.1). Write just the IP address (no subnet mask) to the file:
   ```bash
   echo "10.0.2.15" > /tmp/devops-lab/0A-05/my-ip.txt
   ```
   Hint: `ip addr show | grep "inet " | grep -v "127.0.0.1"` will help narrow it down.

---

### Task 3: Find the Default Gateway

1. Use `ip route` to see the routing table:
   ```bash
   ip route
   ```
   Look for the line starting with `default via`.

2. Write just the gateway IP to the file:
   ```bash
   echo "10.0.2.1" > /tmp/devops-lab/0A-05/gateway.txt
   ```
   Hint: `ip route | grep "^default"` shows just the default route.

---

### Task 4: Find What's Listening on Port 22

1. Use `ss` to find the process on port 22:
   ```bash
   ss -tlnp | grep ":22"
   ```

2. Write just the process name (e.g., `sshd`) to the file:
   ```bash
   echo "sshd" > /tmp/devops-lab/0A-05/port22-process.txt
   ```

---

> **Interview Q:** A web service isn't reachable from outside. Walk me through your debugging steps from the client side to the server side. What commands would you run at each step?

---

## What Just Happened

You just built a complete picture of your system's network state: what's listening, what address it's on, and how traffic gets routed. `ss -tlnp` is typically the first command you run when a service isn't reachable — it tells you instantly whether the service is bound to the right port and address. A service binding to `127.0.0.1:8080` instead of `0.0.0.0:8080` is invisible to external clients, which is one of the most common causes of "it works locally but not in production."

`ip route` and `ip addr` give you the information to answer "can this host reach the outside world?" — check that the interface is up, it has an IP, and there's a default route pointing somewhere. These four commands together let you diagnose most network connectivity issues in under two minutes.
