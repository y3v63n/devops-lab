# DevOps Lab

A self-hosted, interactive DevOps learning platform with hands-on exercises, automated verification, and progress tracking.

## Quick Start

```bash
./setup.sh        # Install dependencies and set up the CLI
lab start          # Start the web server
# Open http://localhost:3333
```

## CLI Usage

```bash
lab status              # Show progress across all modules
lab list                # List all exercises
lab next                # Show next incomplete exercise
lab verify <id>         # Verify an exercise (e.g., lab verify 0A-linux-sysadmin/01-process-management)
lab reset <id>          # Reset an exercise
lab hint <id>           # Show hints
lab cheatsheet <module> # Show module cheatsheet (e.g., lab cheatsheet 00-foundations)
lab start               # Start web server
```

## Modules

| Module | Exercises | Focus |
|--------|-----------|-------|
| 0. Foundations | 25 | Linux, Bash, Docker, Git, Terraform |
| 1. Kubernetes | 20 | Pods, Deployments, Services, Helm |
| 2. CI/CD | 10 | GitHub Actions |
| 3. Networking | 10 | TCP/IP, DNS, sockets |
| 4. Ansible | 8 | Playbooks, roles, vault |
| 5. Grafana/Prometheus | 8 | PromQL, dashboards, alerting |

## Structure

Each exercise has:
- **Theory** — short, learn-by-doing focused
- **Task** — what to do on the server
- **Verification** — automated pass/fail checking
- **Hints** — when you're stuck
- **Interview questions** — relevant interview prep
