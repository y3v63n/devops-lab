## Hints

### Task 1: Check ufw status
- `sudo ufw status` shows "Status: active" or "Status: inactive"
- To write exactly "active" or "inactive":
  ```bash
  sudo ufw status | grep -q "Status: active" && echo "active" || echo "inactive" > /tmp/devops-lab/0A-06/ufw-status.txt
  ```
- If ufw is not installed: `echo "inactive" > /tmp/devops-lab/0A-06/ufw-status.txt`

### Task 2: List current firewall rules
- With ufw: `sudo ufw status verbose > /tmp/devops-lab/0A-06/current-rules.txt`
- Without ufw: `sudo iptables -L -n -v > /tmp/devops-lab/0A-06/current-rules.txt`
- The verbose flag (`verbose`) shows more detail including default policies

### Task 3: Find the default incoming policy
- In `ufw status verbose` output, look for a line like: `Default: deny (incoming), allow (outgoing)`
- The first word after "Default:" for incoming is your answer
- Extract it: `sudo ufw status verbose | grep "Default:" | awk '{print $2}'`
- Write it: `echo "deny" > /tmp/devops-lab/0A-06/default-policy.txt`
- With iptables: `sudo iptables -L INPUT | head -1` shows the chain policy

### Task 4: Explain the firewall rule
The rule: `ufw allow from 10.0.0.0/24 to any port 5432 proto tcp`

Break it down:
- `allow` — this is a permit rule
- `from 10.0.0.0/24` — source must be in this subnet (192 IPs: 10.0.0.0–10.0.0.255)
- `to any` — can connect to any local address
- `port 5432` — only this destination port (PostgreSQL default)
- `proto tcp` — TCP protocol only

Write your explanation in 1-2 sentences:
```bash
cat > /tmp/devops-lab/0A-06/rule-explanation.txt << 'EOF'
This rule allows TCP connections from any host in the 10.0.0.0/24 subnet to port 5432, which is the default PostgreSQL database port. It restricts database access to internal network hosts only, blocking all external connections to the database.
EOF
```
