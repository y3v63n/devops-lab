## Hints

### Task 1: Generate an ed25519 key pair
- `ssh-keygen` generates key pairs
- `-t ed25519` selects the key type (ed25519 is modern and recommended)
- `-f /path/to/key` specifies where to save the private key (public key gets `.pub` appended)
- `-N ""` sets an empty passphrase (for this exercise only — use a passphrase for real keys)
- Full command:
  ```bash
  ssh-keygen -t ed25519 -f /tmp/devops-lab/0A-08/lab_key -N ""
  ```
- This creates two files: `lab_key` (private) and `lab_key.pub` (public)

### Task 2: Harden the config with sed
- `sed -i` edits the file in-place
- `s/old/new/` is the substitution syntax
- Use `^` to anchor to the start of the line to avoid matching commented-out lines
- Three commands needed:
  ```bash
  sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /tmp/devops-lab/0A-08/sshd_config_hardened
  sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /tmp/devops-lab/0A-08/sshd_config_hardened
  sed -i 's/^Port 22$/Port 2222/' /tmp/devops-lab/0A-08/sshd_config_hardened
  ```
- Verify your changes: `grep -E "^(Port|PasswordAuthentication|PermitRootLogin)" /tmp/devops-lab/0A-08/sshd_config_hardened`

### Task 3: Write the hardening checklist
- Write 5+ practices, one per line. Topics to include:
  1. Disable password auth (require keys)
  2. Disable root login
  3. Change default port
  4. Restrict allowed users (AllowUsers directive)
  5. Use fail2ban for brute-force protection
  6. Bonus: Set MaxAuthTries to a low value (e.g., 3)
  7. Bonus: Disable X11Forwarding if not needed
- Use a heredoc for easy multi-line writing:
  ```bash
  cat > /tmp/devops-lab/0A-08/hardening-checklist.txt << 'EOF'
  Disable password authentication — require SSH keys only
  ...
  EOF
  ```
