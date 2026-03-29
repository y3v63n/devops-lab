# 0A-06: Firewall

## Theory

A Linux firewall operates by inspecting network packets and applying rules to decide whether to **accept** (let through), **drop** (silently discard), or **reject** (discard and notify sender) them. The kernel's packet filtering framework is **netfilter**, and `iptables` is the traditional interface to it. **ufw** (Uncomplicated Firewall) is a higher-level tool that generates iptables rules with a more human-friendly syntax — it's the default on Ubuntu/Debian systems.

**Rule ordering is critical**: firewalls process rules top to bottom and stop at the first match. If you have a rule that allows traffic from `10.0.0.0/24` and then a rule that denies all traffic, the allow wins for that subnet — order matters. The **default policy** is what happens when no rule matches: a default of DENY means all unmatched traffic is blocked (allowlist model), while a default of ALLOW means all unmatched traffic gets through (blocklist model). Production servers should use a default DENY policy and explicitly allow only what's needed.

---

## Tasks

### Task 1: Check ufw Status

1. Create your work directory:
   ```bash
   mkdir -p /tmp/devops-lab/0A-06
   ```

2. Check if ufw is active:
   ```bash
   sudo ufw status
   ```

3. Write exactly `active` or `inactive` to the file:
   ```bash
   sudo ufw status | grep -q "Status: active" && echo "active" || echo "inactive"
   sudo ufw status | grep -q "Status: active" && echo "active" || echo "inactive" > /tmp/devops-lab/0A-06/ufw-status.txt
   ```

---

### Task 2: List Current Firewall Rules

1. List all ufw rules (or iptables rules if ufw is unavailable):
   ```bash
   sudo ufw status verbose
   # OR if ufw is not available:
   sudo iptables -L -n -v
   ```

2. Write the output to the file:
   ```bash
   sudo ufw status verbose > /tmp/devops-lab/0A-06/current-rules.txt
   ```

---

### Task 3: Find the Default Incoming Policy

1. The default incoming policy is shown in `ufw status verbose` output, or in `iptables -L INPUT` as the chain policy:
   ```bash
   sudo ufw status verbose | grep "Default:"
   ```

2. Write just the policy word (e.g., `deny` or `allow`) to the file:
   ```bash
   echo "deny" > /tmp/devops-lab/0A-06/default-policy.txt
   ```

---

### Task 4: Explain a Firewall Rule

Read this rule: `ufw allow from 10.0.0.0/24 to any port 5432 proto tcp`

Write 1-2 sentences explaining what it does in plain English to:
```bash
/tmp/devops-lab/0A-06/rule-explanation.txt
```

Think about: what source is allowed? What destination port? What protocol?

---

> **Interview Q:** Why does firewall rule ordering matter? What happens if you have an allow rule after a deny rule for the same traffic? Give an example where incorrect ordering could cause a security incident.

---

## What Just Happened

You inspected your system's firewall state without changing anything. In production, you'd never modify a server's firewall rules without a change control process and a rollback plan — a bad firewall rule can lock you out of SSH permanently. The read-only inspection commands (`ufw status verbose`, `iptables -L`) are safe to run at any time and are essential for auditing security posture.

The rule you analyzed in Task 4 is a common database access pattern: PostgreSQL (port 5432) should only accept connections from known internal subnets, not from the public internet. Understanding how to read and write firewall rules is essential for locking down production services.
