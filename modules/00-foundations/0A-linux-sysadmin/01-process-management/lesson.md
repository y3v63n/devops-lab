# 0A-01: Process Management

## Theory

Every program running on a Linux system is a **process** — an instance of a program with its own memory space, resources, and unique **PID** (Process ID). The kernel assigns PIDs sequentially, and PID 1 is always `init` or `systemd`, the parent of all other processes. Processes have states: **running** (actively using the CPU), **sleeping** (waiting for I/O or an event), and **zombie** (finished but not yet cleaned up by the parent). Understanding what's running and why is the foundation of system administration.

When you need to stop a process, Linux uses **signals**. `SIGTERM` (signal 15) is the polite request — it tells the process to shut down gracefully, giving it a chance to clean up open files and child processes. `SIGKILL` (signal 9) is the hard stop — the kernel forcibly terminates the process with no cleanup. Always try SIGTERM first; reach for SIGKILL only when the process won't respond. For long-running services, Linux uses **systemd** — a service manager that starts, stops, and monitors daemons. `systemctl` is your interface to it.

---

## Tasks

### Task 1: Find the Highest-CPU Process

1. Create your work directory:
   ```bash
   mkdir -p /tmp/devops-lab/0A-01
   ```

2. Use `ps aux` to find the process currently using the most CPU:
   ```bash
   ps aux --sort=-%cpu | head -5
   ```

3. Write **only the PID** (just the number) to the output file:
   ```bash
   echo <PID> > /tmp/devops-lab/0A-01/highest-cpu.txt
   ```

---

### Task 2: Start and Kill a Background Process

1. Start a long-running background process:
   ```bash
   sleep 3600 &
   ```

2. Find its PID — `$!` gives you the PID of the last background process:
   ```bash
   echo $!
   ```

3. Write the PID to the output file:
   ```bash
   echo $! > /tmp/devops-lab/0A-01/sleep-pid.txt
   ```

4. Kill the process:
   ```bash
   kill <PID>
   ```

5. Verify it's dead — it should no longer appear:
   ```bash
   ps aux | grep sleep
   ```

---

### Task 3: Check Service Status

1. Use `systemctl` to check if the SSH service is active:
   ```bash
   systemctl is-active ssh
   ```
   (Some systems use `sshd` — try that if `ssh` doesn't work.)

2. Write exactly `active` or `inactive` to the output file:
   ```bash
   systemctl is-active ssh > /tmp/devops-lab/0A-01/ssh-status.txt
   ```

---

> **Interview Q:** What's the difference between SIGTERM (15) and SIGKILL (9)? When would you use each? What happens to a process's child processes when the parent receives SIGTERM?

---

## What Just Happened

You just practiced the core process inspection and management cycle that sysadmins run dozens of times a day. `ps aux` showed you every process on the system — who owns it, how much CPU and memory it's using, and what command started it. Starting a background job with `&` and capturing `$!` is how shell scripts coordinate async work. Using `kill` with SIGTERM is how you cleanly stop a process (scripts, servers, stuck jobs). And `systemctl is-active` is your go-to for answering "is this service actually running?"

When a deployment hangs, when a service won't start, when a server is crawling — the first thing you do is check processes. These three tools (`ps`, `kill`, `systemctl`) are where every investigation begins.
