#!/usr/bin/env bash
rm -rf /tmp/devops-lab/0A-08
mkdir -p /tmp/devops-lab/0A-08

# Create a sample sshd_config with deliberately insecure settings
cat > /tmp/devops-lab/0A-08/sshd_config_sample << 'EOF'
# Sample sshd_config with insecure defaults (for lab exercise only)
# DO NOT use this file as an actual SSH server config

Port 22
AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::

# Authentication
LoginGraceTime 2m
PermitRootLogin yes
StrictModes yes
MaxAuthTries 6
MaxSessions 10

PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no

UsePAM yes

X11Forwarding yes
PrintMotd no

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

# Override default of no subsystems
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

echo "Exercise reset. Work directory: /tmp/devops-lab/0A-08"
echo "Created: sshd_config_sample with insecure settings (PasswordAuthentication yes, PermitRootLogin yes, Port 22)"
