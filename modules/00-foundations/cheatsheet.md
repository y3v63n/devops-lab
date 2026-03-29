# Module 0: Foundations Cheatsheet

> No AI assistance for Module 0. Use this reference during exercises.

---

## Linux Sysadmin Essentials

### Process Management

```bash
# List all running processes (full detail)
ps aux

# Show process tree
ps auxf

# Interactive process viewer (built-in)
top

# Better interactive viewer (install if needed)
htop

# Find process by name
pgrep nginx
ps aux | grep nginx

# Kill process by PID
kill 1234           # SIGTERM (graceful)
kill -9 1234        # SIGKILL (force)

# Kill all processes matching name
killall nginx
pkill -f "python app.py"

# Show process resource usage
top -p 1234         # watch specific PID
```

### systemctl (Service Management)

```bash
systemctl start nginx          # start a service
systemctl stop nginx           # stop a service
systemctl restart nginx        # stop then start
systemctl reload nginx         # reload config without stopping
systemctl enable nginx         # start on boot
systemctl disable nginx        # don't start on boot
systemctl status nginx         # show current status
systemctl is-active nginx      # returns active/inactive (exit code 0/1)
systemctl is-enabled nginx     # returns enabled/disabled
systemctl list-units --type=service    # list all services
systemctl daemon-reload        # reload systemd after editing unit files
```

### journalctl (Logs via systemd)

```bash
journalctl -u nginx            # logs for a specific service
journalctl -u nginx -f         # follow (tail) live logs
journalctl -u nginx --since "1 hour ago"
journalctl -u nginx --since "2024-01-01" --until "2024-01-02"
journalctl -p err              # only error-level and above
journalctl -p err -u nginx     # errors for specific service
journalctl -n 100              # last 100 lines
journalctl --no-pager          # don't paginate output
journalctl -b                  # logs since last boot
```

### Disk & Storage

```bash
df -h                          # disk usage, human-readable
df -h /                        # specific filesystem
du -sh /var/log                # size of a directory
du -sh *                       # size of each item in cwd
du -sh * | sort -h             # sorted by size
lsblk                          # list block devices (disks/partitions)
lsblk -f                       # include filesystem types
fdisk -l                       # list all partitions (requires root)
mount                          # show all mounted filesystems
mount /dev/sdb1 /mnt           # mount a device
umount /mnt                    # unmount
```

### Users & Permissions

```bash
# View identity
id                             # current user UID, GID, groups
id username                    # specific user
groups                         # groups for current user
whoami                         # just the username

# chmod — change file permissions
chmod 755 file                 # rwxr-xr-x (octal)
chmod 644 file                 # rw-r--r-- (octal)
chmod +x script.sh             # add execute (symbolic)
chmod -w file                  # remove write (symbolic)
chmod u=rwx,g=rx,o=r file      # explicit symbolic
chmod -R 755 /var/www          # recursive

# Octal reference:
# 4 = read (r), 2 = write (w), 1 = execute (x)
# 7 = rwx, 6 = rw-, 5 = r-x, 4 = r--, 0 = ---
# First digit = owner, second = group, third = others

# chown — change ownership
chown user file                # change owner
chown user:group file          # change owner and group
chown -R www-data:www-data /var/www   # recursive

# User management
useradd -m -s /bin/bash alice  # add user with home dir and bash shell
useradd -G sudo,docker alice   # add user to groups at creation
usermod -aG docker alice       # add existing user to group (-a = append!)
usermod -s /bin/bash alice     # change shell
userdel alice                  # delete user
userdel -r alice               # delete user and home dir

# Sudo
visudo                         # safely edit /etc/sudoers
# Add line: alice ALL=(ALL:ALL) ALL
# Passwordless: alice ALL=(ALL) NOPASSWD: ALL
```

### Finding Things

```bash
# find — search for files
find /etc -name "nginx.conf"           # by name
find /var/log -name "*.log"            # wildcard
find /home -type f                     # files only
find /home -type d                     # directories only
find /tmp -size +100M                  # larger than 100MB
find /var/log -mtime -1                # modified in last 24 hours
find /var/log -mtime +7                # modified more than 7 days ago
find . -name "*.sh" -executable        # executable shell scripts
find . -name "*.log" -exec rm {} \;    # delete all .log files
find . -name "*.conf" -exec grep -l "port" {} \;  # find configs containing "port"

# grep — search file contents
grep "error" /var/log/syslog           # basic search
grep -i "error" /var/log/syslog        # case-insensitive
grep -r "password" /etc/               # recursive search
grep -l "nginx" /etc/                  # show only filenames
grep -n "listen" /etc/nginx/nginx.conf # show line numbers
grep -v "debug" /var/log/app.log       # invert match (exclude)
grep -E "error|warning" logfile        # extended regex (OR)
grep -c "GET" access.log               # count matching lines

# awk — field processing
awk '{print $1}' file                  # print first column
awk '{print $1, $3}' file              # print columns 1 and 3
awk -F: '{print $1}' /etc/passwd       # custom delimiter (colon)
awk '/error/ {print $0}' logfile       # print lines matching pattern
awk '{sum += $3} END {print sum}' file # sum third column

# sed — stream editor
sed 's/old/new/g' file                 # replace all occurrences
sed 's/old/new/' file                  # replace first occurrence per line
sed -i 's/old/new/g' file             # edit in place
sed -n '10,20p' file                   # print lines 10-20
sed '/pattern/d' file                  # delete lines matching pattern
```

### Networking

```bash
# Show listening ports and connections
ss -tlnp                       # TCP, listening, no resolve, show process
ss -ulnp                       # UDP listening
ss -tlnp | grep :80            # check if port 80 is listening

# IP configuration
ip addr                        # show all interfaces and IPs
ip addr show eth0              # specific interface
ip route                       # show routing table
ip route get 8.8.8.8           # show route to specific host

# DNS
dig google.com                 # DNS lookup
dig google.com A               # A record only
dig @8.8.8.8 google.com        # query specific DNS server
nslookup google.com            # alternative DNS lookup

# Connectivity
ping -c 4 google.com           # ping 4 times then stop
traceroute google.com          # trace network path

# Find process using a port
lsof -i :80                    # what is using port 80
lsof -i :80 -t                 # just the PID

# HTTP requests
curl https://example.com                           # GET request
curl -I https://example.com                        # headers only
curl -X POST -d '{"key":"val"}' -H "Content-Type: application/json" URL
curl -o output.html https://example.com            # save to file
curl -L https://example.com                        # follow redirects
curl -s https://example.com                        # silent (no progress)
wget https://example.com/file.tar.gz               # download file
wget -O /tmp/file.tar.gz https://example.com/file  # save with custom name
```

### Firewall

```bash
# ufw (Uncomplicated Firewall)
ufw status                     # show status and rules
ufw status verbose             # more detail
ufw enable                     # enable firewall
ufw disable                    # disable firewall
ufw allow 22                   # allow SSH by port
ufw allow ssh                  # allow SSH by name
ufw allow 80/tcp               # allow specific protocol
ufw allow from 192.168.1.0/24  # allow from subnet
ufw deny 23                    # deny a port
ufw delete allow 80            # remove a rule
ufw reset                      # reset all rules

# iptables (lower-level)
iptables -L -n                 # list all rules (no DNS resolve)
iptables -L -n -v              # with packet/byte counts
iptables -L INPUT -n           # just INPUT chain
iptables -A INPUT -p tcp --dport 80 -j ACCEPT     # allow port 80
iptables -A INPUT -s 10.0.0.0/8 -j DROP           # block subnet
iptables -D INPUT -p tcp --dport 80 -j ACCEPT     # delete rule
```

### Logs

```bash
# Tail log files
tail -f /var/log/syslog        # follow syslog live
tail -f /var/log/nginx/access.log
tail -n 100 /var/log/auth.log  # last 100 lines

# dmesg — kernel ring buffer
dmesg                          # all kernel messages
dmesg | tail -20               # recent kernel messages
dmesg -T                       # human-readable timestamps
dmesg | grep -i error          # filter errors

# Common log locations
# /var/log/syslog       — general system log
# /var/log/auth.log     — authentication attempts
# /var/log/nginx/       — nginx access/error logs
# /var/log/apt/         — package manager logs
```

### SSH

```bash
# Key generation
ssh-keygen -t ed25519 -C "your@email.com"        # modern (preferred)
ssh-keygen -t rsa -b 4096 -C "your@email.com"    # RSA 4096-bit

# Copy public key to server
ssh-copy-id user@host                            # append to authorized_keys
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@host  # specify key

# Connect
ssh user@host
ssh -p 2222 user@host          # non-standard port
ssh -i ~/.ssh/mykey user@host  # specific key
ssh -L 8080:localhost:80 user@host   # local port forwarding

# ~/.ssh/config (per-host settings)
# Host myserver
#     HostName 192.168.1.10
#     User alice
#     Port 2222
#     IdentityFile ~/.ssh/id_ed25519

# /etc/ssh/sshd_config key options
# PasswordAuthentication no     — disable password login
# PermitRootLogin no            — disable root login
# PubkeyAuthentication yes      — enable key auth
# Port 2222                     — change default port
# AllowUsers alice bob          — whitelist users

# After editing sshd_config:
systemctl reload sshd
```

---

## Bash Scripting

### Script Header & Safety

```bash
#!/usr/bin/env bash
set -euo pipefail
# -e  exit on error
# -u  error on undefined variable
# -o pipefail  pipe fails if any command fails
```

### Variables

```bash
name="world"
echo "Hello, $name"
echo "Hello, ${name}!"         # braces for clarity

# Special variables
$0                             # script name
$1, $2, ...                    # positional arguments
$@                             # all arguments (as separate words)
$*                             # all arguments (as single string)
$#                             # number of arguments
$?                             # exit code of last command
$$                             # PID of current script
$!                             # PID of last background command

# Default values
${var:-default}                # use default if var unset or empty
${var:=default}                # assign default if var unset or empty
${var:?error message}          # exit with error if var unset or empty

# String operations
${#var}                        # length of string
${var^^}                       # uppercase
${var,,}                       # lowercase
${var#prefix}                  # remove prefix
${var%suffix}                  # remove suffix
```

### Conditionals

```bash
if [[ condition ]]; then
    echo "true"
elif [[ other ]]; then
    echo "other"
else
    echo "false"
fi

# File test flags
[[ -f file ]]        # file exists and is regular file
[[ -d dir ]]         # directory exists
[[ -e path ]]        # path exists (any type)
[[ -r file ]]        # file is readable
[[ -w file ]]        # file is writable
[[ -x file ]]        # file is executable
[[ -z "$var" ]]      # string is empty (zero length)
[[ -n "$var" ]]      # string is non-empty

# Numeric comparisons
[[ $a -eq $b ]]      # equal
[[ $a -ne $b ]]      # not equal
[[ $a -gt $b ]]      # greater than
[[ $a -lt $b ]]      # less than
[[ $a -ge $b ]]      # greater than or equal
[[ $a -le $b ]]      # less than or equal

# String comparisons
[[ "$a" == "$b" ]]   # equal
[[ "$a" != "$b" ]]   # not equal
[[ "$a" =~ regex ]]  # regex match

# Logical operators
[[ cond1 && cond2 ]] # AND
[[ cond1 || cond2 ]] # OR
[[ ! cond ]]         # NOT
```

### Loops

```bash
# for loop over list
for item in one two three; do
    echo "$item"
done

# for loop over files
for file in /var/log/*.log; do
    echo "Processing $file"
done

# C-style for loop
for ((i=0; i<10; i++)); do
    echo "$i"
done

# while loop
count=0
while [[ $count -lt 5 ]]; do
    echo "$count"
    ((count++))
done

# Read lines from file
while IFS= read -r line; do
    echo "$line"
done < /etc/hosts

# Read lines from command output
while IFS= read -r line; do
    echo "$line"
done < <(command)

# Loop over command output
while read -r user shell; do
    echo "$user uses $shell"
done < <(awk -F: '{print $1, $7}' /etc/passwd)
```

### Functions

```bash
greet() {
    local name="$1"          # local scope
    local greeting="Hello"
    echo "$greeting, $name!"
    return 0                 # 0 = success, non-zero = error
}

greet "Alice"

# Capture return value
result=$(greet "Bob")

# Check function exit code
if greet "World"; then
    echo "Success"
fi
```

### Error Handling

```bash
set -euo pipefail              # fail fast

# Trap for cleanup on exit
cleanup() {
    echo "Cleaning up..."
    rm -f /tmp/myapp.lock
}
trap 'cleanup' EXIT            # runs on any exit
trap 'cleanup' ERR             # runs on error
trap 'cleanup' INT TERM        # runs on Ctrl+C or kill

# Allow a command to fail without exiting
command || true
grep "pattern" file || true    # ok if no match

# Check exit code explicitly
if ! command; then
    echo "Command failed" >&2
    exit 1
fi

# Redirect errors to stderr
echo "Error: something failed" >&2
```

### File Processing

```bash
# Read CSV with multiple fields
while IFS=, read -r col1 col2 col3; do
    echo "Name: $col1, Age: $col2"
done < data.csv

# Skip header line
tail -n +2 data.csv | while IFS=, read -r col1 col2; do
    echo "$col1 $col2"
done

# Cut fields from delimited file
cut -d, -f2 data.csv           # second field, comma-delimited
cut -d: -f1,7 /etc/passwd      # fields 1 and 7

# Sort and count unique values
sort file.txt | uniq            # remove duplicate lines
sort file.txt | uniq -c         # count occurrences
sort file.txt | uniq -c | sort -rn    # sort by count descending
```

---

## Docker

### Images

```bash
docker build -t myapp:latest .           # build from Dockerfile in cwd
docker build -t myapp:v1.0 -f Dockerfile.prod .  # custom Dockerfile
docker images                            # list local images
docker images -a                         # include intermediate layers
docker pull nginx:alpine                 # pull image from registry
docker push myrepo/myapp:latest          # push to registry
docker rmi nginx:alpine                  # remove image
docker image prune                       # remove dangling images
docker image prune -a                    # remove all unused images
```

### Containers

```bash
# Run containers
docker run nginx                         # run in foreground
docker run -d nginx                      # detached (background)
docker run -d -p 8080:80 nginx           # port mapping HOST:CONTAINER
docker run -d -p 8080:80 --name webserver nginx
docker run -it ubuntu bash               # interactive with TTY
docker run --rm ubuntu echo "hello"      # auto-remove after exit
docker run -e ENV_VAR=value nginx        # set environment variable
docker run -v /host/path:/container/path nginx   # bind mount
docker run --network mynet nginx         # custom network

# Manage containers
docker ps                                # running containers
docker ps -a                             # all containers (including stopped)
docker stop webserver                    # graceful stop (SIGTERM)
docker kill webserver                    # force stop (SIGKILL)
docker start webserver                   # start stopped container
docker restart webserver                 # stop and start
docker rm webserver                      # remove stopped container
docker rm -f webserver                   # force remove running container

# Inspect and debug
docker logs webserver                    # view logs
docker logs -f webserver                 # follow logs live
docker logs --tail 50 webserver          # last 50 lines
docker exec -it webserver bash           # shell into running container
docker exec webserver ls /etc/nginx      # run single command
docker inspect webserver                 # detailed JSON info
docker inspect webserver | grep IPAddress
docker stats                             # live resource usage
docker top webserver                     # processes in container
docker cp webserver:/etc/nginx/nginx.conf ./  # copy file out
```

### Docker Compose

```bash
# Run from directory with docker-compose.yml
docker compose up                        # start all services (foreground)
docker compose up -d                     # detached
docker compose up -d --build             # rebuild images then start
docker compose down                      # stop and remove containers
docker compose down -v                   # also remove volumes
docker compose stop                      # stop (keep containers)
docker compose start                     # start stopped containers
docker compose restart                   # restart all services
docker compose restart nginx             # restart specific service
docker compose logs                      # all service logs
docker compose logs -f                   # follow all logs
docker compose logs -f nginx             # follow specific service
docker compose ps                        # list services and status
docker compose exec nginx bash           # shell into service
docker compose exec nginx nginx -t       # run command in service
docker compose pull                      # pull latest images
docker compose build                     # build all images
docker compose config                    # validate and view merged config

# When to use docker compose vs docker:
# docker:         quick one-off containers, debugging, single service
# docker compose: multi-service apps, consistent environments, development
```

### Networking

```bash
docker network ls                        # list networks
docker network create mynet              # create custom bridge network
docker network create --driver bridge mynet
docker network inspect mynet             # detailed network info
docker network rm mynet                  # remove network
docker network connect mynet webserver   # connect running container
docker network disconnect mynet webserver

# Containers on same network can reach each other by name
# docker run --network mynet --name db postgres
# docker run --network mynet --name app myapp
# From 'app', connect to postgres at hostname 'db'
```

### Volumes

```bash
docker volume create mydata              # create named volume
docker volume ls                         # list volumes
docker volume inspect mydata             # details (mountpoint, etc)
docker volume rm mydata                  # remove volume
docker volume prune                      # remove unused volumes

# Use volume with container
docker run -v mydata:/var/lib/postgresql/data postgres
docker run -v $(pwd):/app myapp          # bind mount current dir

# Volume types:
# Named volume:  -v mydata:/container/path  (Docker manages location)
# Bind mount:    -v /host/path:/container/path  (you control location)
# tmpfs:         --tmpfs /tmp  (in memory, not persisted)
```

---

## Git Beyond Push/Pull

### Branching

```bash
git branch                               # list local branches
git branch -a                            # list all (including remote)
git branch feature/login                 # create branch (stay on current)
git checkout feature/login               # switch to branch
git checkout -b feature/login            # create and switch
git switch feature/login                 # modern way to switch
git switch -c feature/login              # modern create and switch
git branch -d feature/login              # delete merged branch
git branch -D feature/login              # force delete
git branch -m old-name new-name          # rename branch
```

### Merging

```bash
git merge feature/login                  # merge branch into current
git merge --no-ff feature/login          # always create merge commit
git merge --squash feature/login         # squash to single commit
git merge --abort                        # abort in-progress merge

# Resolving conflicts:
# 1. Open conflicted file — look for markers:
#    <<<<<<< HEAD
#    (your changes)
#    =======
#    (incoming changes)
#    >>>>>>> feature/login
# 2. Edit to keep what you want, remove markers
# 3. git add <conflicted-file>
# 4. git commit
```

### Rebasing

```bash
git rebase main                          # rebase current branch onto main
git rebase --continue                    # continue after resolving conflict
git rebase --abort                       # abort rebase
git rebase --skip                        # skip current conflicting commit

# Interactive rebase
git rebase -i HEAD~3                     # rebase last 3 commits
git rebase -i HEAD~5                     # rebase last 5 commits

# Interactive rebase commands (in editor):
# pick    — keep commit as-is
# reword  — keep commit, edit message
# edit    — pause to amend commit
# squash  — melt into previous commit (keep message)
# fixup   — melt into previous commit (discard message)
# drop    — delete commit
```

### Cherry-Pick

```bash
git cherry-pick abc1234                  # apply commit to current branch
git cherry-pick abc1234 def5678          # apply multiple commits
git cherry-pick abc1234..def5678         # apply range of commits
git cherry-pick --no-commit abc1234      # apply changes without committing
git cherry-pick --abort                  # abort in-progress cherry-pick
```

### Stash

```bash
git stash                                # stash current changes
git stash push -m "WIP: login form"      # stash with description
git stash list                           # list all stashes
git stash show                           # show latest stash diff
git stash show stash@{1}                 # show specific stash
git stash pop                            # apply latest and remove from list
git stash apply                          # apply latest, keep in list
git stash apply stash@{2}               # apply specific stash
git stash drop stash@{1}                # remove specific stash
git stash clear                          # remove all stashes
git stash branch feature/name            # create branch from stash
```

### Bisect

```bash
# Binary search to find which commit introduced a bug
git bisect start
git bisect bad                           # mark current commit as bad
git bisect good v1.0                     # mark known good commit/tag
# Git checks out midpoint — test, then mark:
git bisect good                          # this commit is good
git bisect bad                           # this commit is bad
# Repeat until bisect identifies the culprit
git bisect reset                         # return to original HEAD
```

### Reflog

```bash
git reflog                               # history of HEAD movements
git reflog show feature/login            # reflog for specific branch

# Recover lost commits / branches
git reflog                               # find the SHA you need
git checkout -b recovered abc1234        # create branch from lost commit
git reset --hard HEAD@{3}               # reset to 3 moves ago

# Undo a bad rebase / reset
git reflog                               # find SHA before the operation
git reset --hard abc1234                 # restore to that point
```

### Other Useful Git

```bash
git log --oneline --graph --all          # visual branch history
git log --oneline -10                    # last 10 commits, compact
git diff HEAD~3                          # diff against 3 commits ago
git diff main..feature/login             # diff between branches
git show abc1234                         # show a specific commit
git blame file.txt                       # who changed each line
git shortlog -sn                         # commit count per author
```

---

## Terraform / OpenTofu

> Commands work for both `terraform` and `tofu` (OpenTofu). Substitute as needed.

### Core Workflow

```bash
terraform init                           # initialize: download providers/modules
terraform plan                           # show what will change
terraform plan -out=tfplan               # save plan to file
terraform apply                          # apply changes (prompts for confirm)
terraform apply -auto-approve            # skip confirmation prompt
terraform apply tfplan                   # apply saved plan
terraform destroy                        # destroy all managed infrastructure
terraform destroy -target=aws_instance.web   # destroy specific resource
```

### Configuration Blocks

```hcl
# Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Resource
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"

  tags = {
    Name = "WebServer"
  }
}

# Variable
variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type"
}

# Reference variable
resource "aws_instance" "web" {
  instance_type = var.instance_type
}

# Output
output "public_ip" {
  value       = aws_instance.web.public_ip
  description = "The public IP of the web server"
}

# Data source (read existing resources)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }
}

# Locals
locals {
  common_tags = {
    Project     = "my-app"
    Environment = "prod"
  }
}

resource "aws_instance" "web" {
  tags = local.common_tags
}
```

### State Management

```bash
terraform state list                     # list all resources in state
terraform state show aws_instance.web    # show details of a resource
terraform state rm aws_instance.web      # remove resource from state (doesn't destroy)
terraform state mv aws_instance.web aws_instance.app  # rename resource in state
terraform state pull                     # download and print current state
terraform state push terraform.tfstate   # upload state file
```

### Formatting & Validation

```bash
terraform fmt                            # format all .tf files in cwd
terraform fmt -recursive                 # format recursively
terraform fmt -check                     # check formatting, exit 1 if wrong
terraform validate                       # validate configuration syntax
terraform console                        # interactive expression evaluation
```

### Workspaces

```bash
terraform workspace list                 # list workspaces
terraform workspace new staging          # create new workspace
terraform workspace select staging       # switch workspace
terraform workspace show                 # current workspace
terraform workspace delete staging       # delete workspace
```

### Variables in Practice

```bash
# Set via CLI
terraform apply -var="instance_type=t3.small"
terraform apply -var-file="prod.tfvars"

# terraform.tfvars (auto-loaded)
instance_type = "t3.small"
region        = "us-west-2"

# Environment variables
export TF_VAR_instance_type="t3.small"
```
