## Hints

### Finding the highest-CPU process
- `ps aux --sort=-%cpu | head -5` sorts all processes by CPU usage (highest first)
- The PID is in the second column
- You can extract it with: `ps aux --sort=-%cpu | head -2 | tail -1 | awk '{print $2}'`
- Write it to the file: `echo <PID> > /tmp/devops-lab/0A-01/highest-cpu.txt`

### Starting and killing a background process
- `sleep 3600 &` starts a sleep process in the background
- `echo $!` gives you the PID of the last background process
- Save it: `echo $! > /tmp/devops-lab/0A-01/sleep-pid.txt`
- Kill it: `kill <PID>` (or `kill $(cat /tmp/devops-lab/0A-01/sleep-pid.txt)`)
- Verify it's gone: `ps aux | grep sleep`

### Checking service status
- `systemctl is-active ssh` prints "active" or "inactive"
- Some systems use `sshd` instead of `ssh` — try both
- Write the result: `systemctl is-active ssh > /tmp/devops-lab/0A-01/ssh-status.txt`
