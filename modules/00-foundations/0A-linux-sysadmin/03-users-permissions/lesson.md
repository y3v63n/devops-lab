# 0A-03: Users and Permissions

## Theory

Linux uses a **discretionary access control** model: every file and directory has an **owner** (a user) and a **group**, and three sets of permission bits — for the owner, the group, and everyone else. Each set has three flags: **read (r/4)**, **write (w/2)**, and **execute (x/1)**. Octal notation collapses each set into a single digit — `chmod 755` means owner gets 7 (rwx), group gets 5 (r-x), others get 5 (r-x). This is the standard for executable scripts. `chmod 600` gives owner rw only — no one else can touch it — which is required for SSH private keys.

**`sudo`** grants temporary root privileges to specific users, controlled by `/etc/sudoers`. Never edit sudoers directly — use `visudo`, which validates the syntax before saving. The **sticky bit** (mode bit `t`) on a directory means only the file owner (or root) can delete files inside it, even if others have write access. You see this on `/tmp`: everyone can create files there, but you can't delete other users' files. The **setuid bit** runs an executable as its owner rather than the caller — that's how `passwd` can modify `/etc/shadow` even when run by a regular user.

---

## Tasks

### Task 1: Create a Private File (600)

1. Create your work directory:
   ```bash
   mkdir -p /tmp/devops-lab/0A-03
   ```

2. Create the file with content and lock it down:
   ```bash
   echo "classified" > /tmp/devops-lab/0A-03/secret.txt
   chmod 600 /tmp/devops-lab/0A-03/secret.txt
   ```

3. Verify the permissions:
   ```bash
   ls -la /tmp/devops-lab/0A-03/secret.txt
   ```
   You should see `-rw-------`.

---

### Task 2: Create a Shared Readable File (644)

1. Create the file and set standard read-only permissions for others:
   ```bash
   echo "public" > /tmp/devops-lab/0A-03/shared.txt
   chmod 644 /tmp/devops-lab/0A-03/shared.txt
   ```

2. Verify: you should see `-rw-r--r--`.

---

### Task 3: Create an Executable Script (755)

1. Create the script and make it executable by all:
   ```bash
   printf '#!/bin/bash\necho hello\n' > /tmp/devops-lab/0A-03/script.sh
   chmod 755 /tmp/devops-lab/0A-03/script.sh
   ```

2. Test it runs:
   ```bash
   /tmp/devops-lab/0A-03/script.sh
   ```

---

### Task 4: Read /etc/passwd Permissions

1. Use `stat` to get the octal permissions of `/etc/passwd`:
   ```bash
   stat -c "%a" /etc/passwd
   ```

2. Write the octal string to the output file:
   ```bash
   stat -c "%a" /etc/passwd > /tmp/devops-lab/0A-03/passwd-perms.txt
   ```

---

> **Interview Q:** Explain the sticky bit. Where do you commonly see it and why? What's the difference between setuid on a file vs. setuid on a directory?

---

## What Just Happened

You just worked through the three most common permission patterns in production systems. `600` (rw-------) is the standard for secrets: SSH keys, config files with passwords, TLS private keys — anything that should be readable only by the owning process. `644` (rw-r--r--) is the default for most files: world-readable, owner-writable. `755` (rwxr-xr-x) is the standard for scripts and binaries: everyone can run it, only the owner can change it.

The `stat` command gives you machine-readable file metadata, including the octal permissions — much more useful in scripts than parsing `ls -l` output. When a deployment fails with "Permission denied," these tools are how you diagnose it in seconds.
