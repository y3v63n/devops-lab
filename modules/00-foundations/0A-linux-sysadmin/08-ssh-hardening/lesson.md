# 0A-08: SSH Hardening

## Theory

SSH (Secure Shell) is the primary way to manage remote Linux servers. The security of SSH depends almost entirely on configuration: a default installation with password authentication enabled is vulnerable to brute-force attacks — bots scan the internet constantly for open port 22 and attempt thousands of password guesses per hour. The most important hardening step is **key-based authentication**: the server stores your public key; you authenticate by proving you have the corresponding private key, cryptographically, without ever sending a password. This makes brute-force attacks impossible.

Beyond key-based auth, SSH hardening follows the principle of least privilege: disable anything you don't need. **PermitRootLogin no** forces attackers to know a valid username (not just "root"). **Changing the port** from 22 reduces noise from automated scans (not real security, but reduces log pollution). **AllowUsers** or **AllowGroups** limits which accounts can SSH in at all. **Fail2ban** monitors auth logs and automatically bans IPs after repeated failures — it's not built into SSH but pairs with it in production. The key insight: each hardening step raises the cost for an attacker; stacking them creates defense in depth.

---

## Tasks

### Setup

Run `reset.sh` first — it creates a sample sshd_config with deliberately insecure settings for you to fix.

### Task 1: Generate an SSH Key Pair

1. Create your work directory:
   ```bash
   mkdir -p /tmp/devops-lab/0A-08
   ```

2. Generate an ed25519 key pair (no passphrase — press Enter when prompted):
   ```bash
   ssh-keygen -t ed25519 -f /tmp/devops-lab/0A-08/lab_key -N ""
   ```
   Flags: `-t ed25519` (key type), `-f` (output file), `-N ""` (empty passphrase)

3. Verify both files were created:
   ```bash
   ls -la /tmp/devops-lab/0A-08/lab_key*
   ```
   You should see `lab_key` (private) and `lab_key.pub` (public).

---

### Task 2: Harden the Sample Config

1. Copy the sample config to your work file:
   ```bash
   cp /tmp/devops-lab/0A-08/sshd_config_sample /tmp/devops-lab/0A-08/sshd_config_hardened
   ```

2. Edit the hardened config to fix these three issues:
   - Change `PasswordAuthentication yes` to `PasswordAuthentication no`
   - Change `PermitRootLogin yes` to `PermitRootLogin no`
   - Change `Port 22` to `Port 2222`

   You can use sed for each change:
   ```bash
   sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /tmp/devops-lab/0A-08/sshd_config_hardened
   sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /tmp/devops-lab/0A-08/sshd_config_hardened
   sed -i 's/^Port 22$/Port 2222/' /tmp/devops-lab/0A-08/sshd_config_hardened
   ```

3. Verify your changes:
   ```bash
   grep -E "^(Port|PasswordAuthentication|PermitRootLogin)" /tmp/devops-lab/0A-08/sshd_config_hardened
   ```

---

### Task 3: Write a Hardening Checklist

Create a file listing 5 SSH hardening best practices (one per line):
```bash
cat > /tmp/devops-lab/0A-08/hardening-checklist.txt << 'EOF'
Disable password authentication and require SSH key-based login only
Set PermitRootLogin to no to prevent direct root access via SSH
Change the default SSH port from 22 to reduce automated scan noise
Use AllowUsers or AllowGroups to restrict which accounts can SSH in
Install and configure fail2ban to auto-ban IPs with repeated failed logins
EOF
```

---

> **Interview Q:** Explain the SSH key exchange process. What happens cryptographically when you run `ssh user@host`? What is the purpose of the known_hosts file?

---

## What Just Happened

You generated a real ed25519 key pair and applied real hardening changes to an sshd config. ed25519 is the modern recommended key type — it's faster than RSA and has shorter keys with equivalent security. The `-N ""` flag creates a key with no passphrase, which is standard for automated systems (CI/CD, deployment scripts). For human use, always set a passphrase.

The three changes you made to the config represent the most critical SSH hardening steps in priority order: disabling password auth stops brute-force attacks entirely; disabling root login means attackers need two things instead of one; changing the port reduces noise. In production, you'd also set `MaxAuthTries 3`, `LoginGraceTime 30`, `AllowUsers deploy`, and configure certificate-based auth for large fleets. Never apply config changes to the live `/etc/ssh/sshd_config` without first running `sshd -t -f /path/to/config` to validate syntax — a bad config can lock you out permanently.
