## Hints

### Task 1: Find listening TCP ports
- `ss -tlnp` is the key command: `-t` (TCP), `-l` (listening), `-n` (numeric ports), `-p` (show process)
- Redirect to file: `ss -tlnp > /tmp/devops-lab/0A-05/listening-ports.txt`

### Task 2: Find your primary IP address
- `ip addr show` lists all interfaces and their addresses
- Filter to just inet (IPv4) lines: `ip addr show | grep "inet "`
- Exclude loopback: `ip addr show | grep "inet " | grep -v "127.0.0.1"`
- The IP is in the format `inet X.X.X.X/prefix` — you want just the X.X.X.X part
- Extract with awk: `ip addr show | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d/ -f1`
- Write just the IP: `echo "IP_HERE" > /tmp/devops-lab/0A-05/my-ip.txt`

### Task 3: Find the default gateway
- `ip route` shows all routes; look for the line starting with `default via`
- Filter it: `ip route | grep "^default"`
- The gateway IP is the third word on that line
- Extract with awk: `ip route | grep "^default" | awk '{print $3}'`
- Write just the IP: `echo "GW_HERE" > /tmp/devops-lab/0A-05/gateway.txt`

### Task 4: Find what's listening on port 22
- Filter ss output: `ss -tlnp | grep ":22"`
- The process name appears in the last column, e.g., `users:(("sshd",pid=1234,fd=3))`
- It's typically `sshd` (SSH daemon)
- Write just the name: `echo "sshd" > /tmp/devops-lab/0A-05/port22-process.txt`
