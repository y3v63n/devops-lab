// tooltips.js — automatic command tooltips for code blocks
//
// Scans rendered code blocks and wraps known commands, flags, and patterns
// with tooltip spans. Loaded after app.js, called after markdown rendering.

const CMD_TIPS = {
  // --- Process management ---
  'ps': 'List running processes',
  'ps aux': 'List ALL processes with details (user, CPU%, memory%, command)',
  'kill': 'Send a signal to a process (default: SIGTERM for graceful shutdown)',
  'kill -9': 'Send SIGKILL — force-kill a process immediately (no cleanup)',
  'kill -0': 'Check if a process is running (sends no signal)',
  'sleep': 'Pause execution for a specified number of seconds',
  'top': 'Real-time view of running processes and system resource usage',
  'htop': 'Interactive process viewer (improved version of top)',
  'systemctl': 'Control systemd services (start, stop, restart, status, enable, disable)',
  'systemctl start': 'Start a service',
  'systemctl stop': 'Stop a service',
  'systemctl restart': 'Stop then start a service',
  'systemctl status': 'Show service status, recent logs, and PID',
  'systemctl enable': 'Enable a service to start automatically at boot',
  'systemctl is-active': 'Check if a service is running (prints "active" or "inactive")',
  'journalctl': 'View systemd journal logs',
  'journalctl -u': 'Show logs for a specific service unit',
  'journalctl -f': 'Follow logs in real-time (like tail -f)',
  'journalctl --since': 'Show logs from a specific time',
  'journalctl -p': 'Filter by priority (emerg, alert, crit, err, warning, notice, info, debug)',

  // --- File & directory ---
  'ls': 'List directory contents',
  'ls -la': 'List all files (including hidden) with details',
  'mkdir': 'Create a directory',
  'mkdir -p': 'Create directory and any missing parent directories',
  'rm': 'Remove files',
  'rm -rf': 'Remove files/directories recursively and forcefully (dangerous!)',
  'cat': 'Display file contents',
  'head': 'Show first lines of a file (default: 10)',
  'tail': 'Show last lines of a file (default: 10)',
  'tail -f': 'Follow a file — show new lines as they are written',
  'touch': 'Create an empty file, or update its timestamp',
  'cp': 'Copy files or directories',
  'mv': 'Move or rename files',
  'chmod': 'Change file permissions (e.g., chmod 755 = rwxr-xr-x)',
  'chmod +x': 'Make a file executable',
  'chown': 'Change file owner and/or group',
  'stat': 'Display detailed file information (permissions, size, timestamps)',
  'wc': 'Count lines, words, or bytes in a file',
  'wc -l': 'Count number of lines',

  // --- Search & text processing ---
  'find': 'Search for files by name, type, size, or modification time',
  'grep': 'Search file contents for a pattern (text or regex)',
  'grep -r': 'Search recursively through directories',
  'grep -i': 'Case-insensitive search',
  'grep -l': 'Only print filenames that contain the pattern',
  'grep -n': 'Show line numbers with matches',
  'grep -E': 'Use extended regex (same as egrep)',
  'grep -v': 'Invert match — show lines that do NOT match',
  'awk': 'Text processing language — great for extracting columns from output',
  'sed': 'Stream editor — find and replace text in files or streams',
  'sort': 'Sort lines of text',
  'sort -rn': 'Sort numerically in reverse (highest first)',
  'uniq': 'Remove duplicate adjacent lines (use with sort)',
  'uniq -c': 'Count occurrences of each unique line',
  'cut': 'Extract columns/fields from text',
  'cut -d': 'Set field delimiter (e.g., cut -d, for CSV)',
  'cut -f': 'Select field number(s)',
  'tr': 'Translate or delete characters',
  'tee': 'Read from stdin and write to both stdout and a file',

  // --- Disk & storage ---
  'df': 'Show disk space usage for mounted filesystems',
  'df -h': 'Show disk space in human-readable format (GB, MB)',
  'du': 'Show disk usage of files and directories',
  'du -sh': 'Show total size of a directory in human-readable format',
  'lsblk': 'List block devices (disks, partitions)',
  'mount': 'Mount a filesystem, or show currently mounted filesystems',
  'fdisk': 'Partition table editor for disks',

  // --- User management ---
  'useradd': 'Create a new user account',
  'usermod': 'Modify a user account',
  'userdel': 'Delete a user account',
  'id': 'Show user ID (UID), group ID (GID), and groups',
  'groups': 'Show which groups a user belongs to',
  'whoami': 'Print the current username',
  'sudo': 'Run a command as root (superuser)',
  'su': 'Switch to another user account',

  // --- Networking ---
  'ss': 'Show socket statistics (modern replacement for netstat)',
  'ss -tlnp': 'Show listening TCP ports with process names',
  'ip': 'Show/manipulate network interfaces, routing, and addresses',
  'ip addr': 'Show IP addresses for all network interfaces',
  'ip route': 'Show the routing table',
  'ping': 'Send ICMP echo requests to test network connectivity',
  'curl': 'Transfer data from or to a server (HTTP, HTTPS, FTP, etc.)',
  'curl -s': 'Silent mode — no progress bar',
  'curl -sL': 'Silent + follow redirects',
  'wget': 'Download files from the web',
  'dig': 'DNS lookup utility — query DNS records',
  'nslookup': 'Query DNS servers for domain name resolution',
  'netstat': 'Show network connections (older tool, use ss instead)',
  'traceroute': 'Show the route packets take to a destination',
  'mtr': 'Network diagnostic tool combining ping and traceroute',
  'nmap': 'Network scanner — discover hosts and services',
  'lsof': 'List open files (including network connections)',
  'lsof -i': 'Show network connections and which process owns them',
  'tcpdump': 'Capture and analyze network packets',

  // --- Firewall ---
  'ufw': 'Uncomplicated Firewall — simple iptables frontend',
  'ufw status': 'Show firewall status and rules',
  'ufw enable': 'Enable the firewall',
  'ufw allow': 'Allow traffic on a port or from a source',
  'ufw deny': 'Block traffic on a port or from a source',
  'iptables': 'Low-level Linux packet filter (firewall)',
  'iptables -L': 'List all firewall rules',

  // --- SSH ---
  'ssh': 'Secure shell — connect to a remote server',
  'ssh-keygen': 'Generate SSH key pairs for authentication',
  'ssh-copy-id': 'Copy your public key to a remote server for passwordless login',
  'scp': 'Copy files over SSH',

  // --- Package management ---
  'apt': 'Debian/Ubuntu package manager',
  'apt-get': 'Debian/Ubuntu package manager (older command)',
  'apt install': 'Install a package',
  'apt update': 'Update the package index',

  // --- Docker ---
  'docker': 'Container runtime — build, run, and manage containers',
  'docker run': 'Create and start a new container from an image',
  'docker run -d': 'Run container in detached (background) mode',
  'docker run -p': 'Map a host port to a container port (HOST:CONTAINER)',
  'docker run --name': 'Assign a name to the container',
  'docker run -it': 'Run interactively with a terminal attached',
  'docker run --rm': 'Automatically remove container when it stops',
  'docker run -v': 'Mount a volume or bind-mount a directory',
  'docker ps': 'List running containers',
  'docker ps -a': 'List all containers (including stopped)',
  'docker images': 'List downloaded images',
  'docker build': 'Build an image from a Dockerfile',
  'docker build -t': 'Build and tag the image with a name',
  'docker pull': 'Download an image from a registry',
  'docker push': 'Upload an image to a registry',
  'docker exec': 'Run a command inside a running container',
  'docker exec -it': 'Open an interactive shell inside a container',
  'docker logs': 'View container output/logs',
  'docker logs -f': 'Follow container logs in real-time',
  'docker stop': 'Gracefully stop a running container',
  'docker rm': 'Remove a stopped container',
  'docker rmi': 'Remove an image',
  'docker inspect': 'Show detailed info about a container or image (JSON)',
  'docker network': 'Manage Docker networks',
  'docker network create': 'Create a custom network for containers',
  'docker network ls': 'List all Docker networks',
  'docker volume': 'Manage Docker volumes for persistent data',
  'docker volume create': 'Create a named volume',
  'docker compose': 'Define and run multi-container apps (from docker-compose.yml)',
  'docker compose up': 'Start all services defined in docker-compose.yml',
  'docker compose up -d': 'Start services in detached (background) mode',
  'docker compose down': 'Stop and remove all services, networks',
  'docker compose down -v': 'Stop services and remove volumes too',
  'docker compose logs': 'View logs for all services',
  'docker compose ps': 'List running services',
  'docker compose exec': 'Run a command in a running service container',

  // --- Git ---
  'git': 'Distributed version control system',
  'git init': 'Create a new git repository',
  'git clone': 'Download a repository from a remote',
  'git status': 'Show which files are modified, staged, or untracked',
  'git add': 'Stage files for the next commit',
  'git add .': 'Stage all changes in current directory',
  'git commit': 'Save staged changes as a new commit',
  'git commit -m': 'Commit with an inline message',
  'git push': 'Upload commits to a remote repository',
  'git pull': 'Download and merge changes from remote',
  'git fetch': 'Download changes from remote without merging',
  'git branch': 'List, create, or delete branches',
  'git branch -d': 'Delete a branch (safe — refuses if unmerged)',
  'git branch -D': 'Force-delete a branch',
  'git checkout': 'Switch branches or restore files',
  'git checkout -b': 'Create and switch to a new branch',
  'git switch': 'Switch branches (newer, clearer alternative to checkout)',
  'git switch -c': 'Create and switch to a new branch',
  'git merge': 'Merge another branch into the current branch',
  'git merge --abort': 'Cancel a merge in progress',
  'git rebase': 'Reapply commits on top of another base',
  'git rebase -i': 'Interactive rebase — squash, reorder, edit commits',
  'git log': 'Show commit history',
  'git log --oneline': 'Show compact one-line-per-commit history',
  'git log --graph': 'Show commit history with branch graph',
  'git diff': 'Show changes between commits, branches, or working tree',
  'git stash': 'Temporarily save uncommitted changes',
  'git stash push -m': 'Stash with a descriptive name',
  'git stash pop': 'Apply most recent stash and remove it',
  'git stash list': 'Show all saved stashes',
  'git cherry-pick': 'Apply a specific commit from another branch',
  'git bisect': 'Binary search through commits to find when a bug was introduced',
  'git reflog': 'Show history of HEAD changes — recover "lost" commits',
  'git reset': 'Move HEAD to a different commit (can lose changes!)',
  'git reset --hard': 'Reset working tree and index to a commit (DESTRUCTIVE)',

  // --- Terraform / OpenTofu ---
  'terraform': 'Infrastructure as Code tool for provisioning cloud resources',
  'tofu': 'OpenTofu — open-source fork of Terraform',
  'terraform init': 'Initialize — download providers and set up backend',
  'terraform plan': 'Preview what changes will be made (dry run)',
  'terraform apply': 'Apply the planned changes to create/modify infrastructure',
  'terraform destroy': 'Destroy all managed infrastructure',
  'terraform fmt': 'Format .tf files to canonical style',
  'terraform validate': 'Check configuration for syntax errors',
  'terraform state': 'Inspect or modify the state file',
  'tofu init': 'Initialize — download providers and set up backend',
  'tofu plan': 'Preview what changes will be made (dry run)',
  'tofu apply': 'Apply the planned changes to create/modify infrastructure',
  'tofu destroy': 'Destroy all managed infrastructure',

  // --- Kubernetes ---
  'kubectl': 'Kubernetes command-line tool for managing clusters',
  'kubectl get': 'List resources (pods, services, deployments, etc.)',
  'kubectl get pods': 'List all pods in the current namespace',
  'kubectl get pods -o wide': 'List pods with extra detail (node, IP)',
  'kubectl get svc': 'List all services',
  'kubectl get nodes': 'List all cluster nodes',
  'kubectl get ns': 'List all namespaces',
  'kubectl get events': 'List cluster events (useful for debugging)',
  'kubectl get pvc': 'List persistent volume claims',
  'kubectl describe': 'Show detailed info about a resource',
  'kubectl describe pod': 'Show detailed pod info (events, conditions, containers)',
  'kubectl create': 'Create a resource from a file or command',
  'kubectl create deployment': 'Create a deployment',
  'kubectl create namespace': 'Create a namespace',
  'kubectl create configmap': 'Create a ConfigMap from literals or files',
  'kubectl create secret': 'Create a Secret from literals or files',
  'kubectl apply': 'Create or update resources from a YAML file',
  'kubectl apply -f': 'Apply configuration from a file',
  'kubectl delete': 'Delete resources',
  'kubectl delete -f': 'Delete resources defined in a file',
  'kubectl delete pod': 'Delete a specific pod',
  'kubectl run': 'Create and run a pod (quick way to test an image)',
  'kubectl exec': 'Run a command inside a running pod',
  'kubectl exec -it': 'Open an interactive shell inside a pod',
  'kubectl logs': 'View pod logs',
  'kubectl logs -f': 'Follow pod logs in real-time',
  'kubectl logs --previous': 'View logs from a crashed/restarted container',
  'kubectl port-forward': 'Forward a local port to a pod or service',
  'kubectl scale': 'Change the number of replicas in a deployment',
  'kubectl set image': 'Update the container image of a deployment',
  'kubectl rollout': 'Manage deployment rollouts',
  'kubectl rollout status': 'Watch the progress of a rollout',
  'kubectl rollout history': 'View rollout revision history',
  'kubectl rollout undo': 'Rollback to a previous revision',
  'kubectl top': 'Show resource usage (CPU/memory) for pods or nodes',
  'kubectl top pods': 'Show CPU and memory usage per pod',
  'kubectl top nodes': 'Show CPU and memory usage per node',
  'kubectl config': 'Manage kubeconfig settings',
  'kubectl cluster-info': 'Show cluster endpoint information',
  'kubectl label': 'Add or update labels on resources',
  'kubectl expose': 'Create a service for a deployment or pod',
  'kubectl autoscale': 'Set up auto-scaling for a deployment',
  'minikube': 'Run a local Kubernetes cluster for development',
  'minikube start': 'Start the local Kubernetes cluster',
  'minikube stop': 'Stop the cluster (preserves state)',
  'minikube delete': 'Delete the cluster entirely',
  'minikube status': 'Show cluster status',
  'minikube dashboard': 'Open the Kubernetes web dashboard',
  'minikube tunnel': 'Create a tunnel to expose LoadBalancer services',
  'minikube service': 'Get the URL for a NodePort or LoadBalancer service',

  // --- Helm ---
  'helm': 'Kubernetes package manager for deploying applications',
  'helm install': 'Install a Helm chart as a release',
  'helm upgrade': 'Upgrade an existing release with new values or chart version',
  'helm uninstall': 'Remove a release from the cluster',
  'helm list': 'List all installed releases',
  'helm repo add': 'Add a chart repository',
  'helm repo update': 'Update chart repository index',
  'helm search repo': 'Search for charts in added repositories',
  'helm create': 'Scaffold a new Helm chart directory structure',
  'helm template': 'Render chart templates locally (dry-run, no cluster needed)',
  'helm lint': 'Validate a chart for errors and best practices',
  'helm status': 'Show the status of a deployed release',

  // --- Bash syntax ---
  'echo': 'Print text to the terminal',
  'export': 'Set an environment variable available to child processes',
  'source': 'Execute a script in the current shell (loads functions/variables)',
  'set -e': 'Exit immediately if any command fails',
  'set -u': 'Treat unset variables as errors',
  'set -o pipefail': 'A pipeline fails if ANY command in it fails (not just the last)',
  'set -euo pipefail': 'Strict mode: exit on error, unset vars, pipeline failures',
  'trap': 'Run a command when a signal is received (e.g., cleanup on EXIT)',
  'read': 'Read a line of input into a variable',
  'read -r': 'Read without interpreting backslash escapes',
  'local': 'Declare a variable scoped to the current function',
  'return': 'Exit a function with a status code (0 = success)',
  'exit': 'Exit the script with a status code',
  'test': 'Evaluate a conditional expression (same as [ ])',
  'true': 'A command that always succeeds (exit code 0)',
  'false': 'A command that always fails (exit code 1)',
  'env': 'Show all environment variables, or run a command with modified env',
  'xargs': 'Build and execute commands from stdin',
  'which': 'Show the full path of a command',
  'command -v': 'Check if a command exists (preferred over which in scripts)',
  'date': 'Show or set the system date and time',
  'uptime': 'Show how long the system has been running',
  'free': 'Show memory usage',
  'free -h': 'Show memory usage in human-readable format (GB, MB)',
  'hostname': 'Show or set the system hostname',
  'dmesg': 'Show kernel ring buffer messages (hardware, driver events)',
  'nproc': 'Show number of CPU cores',
};

// Patterns for special tokens (not plain commands)
const PATTERN_TIPS = [
  { regex: /\$\!/g, tip: 'PID of the last background process' },
  { regex: /\$\?/g, tip: 'Exit code of the last command (0 = success)' },
  { regex: /\$\$/g, tip: 'PID of the current shell process' },
  { regex: /\$#/g, tip: 'Number of arguments passed to the script' },
  { regex: /\$@/g, tip: 'All arguments passed to the script (as separate words)' },
  { regex: /\$\*/g, tip: 'All arguments as a single string' },
  { regex: /\$1\b/g, tip: 'First argument passed to the script/function' },
  { regex: /\$2\b/g, tip: 'Second argument passed to the script/function' },
  { regex: /\$0\b/g, tip: 'Name of the script itself' },
  { regex: /2>&1/g, tip: 'Redirect stderr to stdout (combine error and normal output)' },
  { regex: /2>\/dev\/null/g, tip: 'Discard error output' },
  { regex: /&>\/dev\/null/g, tip: 'Discard all output (stdout + stderr)' },
  { regex: />\s*\/dev\/null/g, tip: 'Discard normal output' },
  { regex: /\|\|/g, tip: 'OR — run next command only if previous FAILED' },
  { regex: /&&/g, tip: 'AND — run next command only if previous SUCCEEDED' },
  { regex: /(?<!\d)\|(?!\|)/g, tip: 'Pipe — send output of left command as input to right command' },
  { regex: /&$/gm, tip: 'Run the command in the background' },
];

/**
 * Apply tooltips to all code blocks within a container element.
 * Call this after markdown has been rendered and highlighted.
 */
function applyTooltips(container) {
  container.querySelectorAll('pre code').forEach(block => {
    // Skip if already processed
    if (block.dataset.tooltipped) return;
    block.dataset.tooltipped = 'true';

    let html = block.innerHTML;

    // Sort commands by length (longest first) to match multi-word commands before single-word
    const sortedCommands = Object.keys(CMD_TIPS).sort((a, b) => b.length - a.length);

    // Track positions already wrapped to avoid double-wrapping
    // We use a placeholder approach: replace matches with placeholders, then restore
    const placeholders = [];

    for (const cmd of sortedCommands) {
      // Escape special regex characters in the command
      const escaped = cmd.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      // Match the command at word boundaries, but not inside existing tooltip spans
      const regex = new RegExp(`(?<![\\w-])${escaped}(?![\\w-])(?![^<]*<\\/span>)`, 'g');
      const tip = CMD_TIPS[cmd].replace(/"/g, '&quot;');

      html = html.replace(regex, (match) => {
        const idx = placeholders.length;
        placeholders.push(`<span class="cmd-tip" data-tip="${tip}">${match}</span>`);
        return `\x00TOOLTIP${idx}\x00`;
      });
    }

    // Apply pattern-based tips
    for (const { regex, tip } of PATTERN_TIPS) {
      const safeTip = tip.replace(/"/g, '&quot;');
      const r = new RegExp(regex.source, regex.flags);
      html = html.replace(r, (match) => {
        // Don't wrap if already inside a placeholder
        if (match.includes('\x00TOOLTIP')) return match;
        const idx = placeholders.length;
        placeholders.push(`<span class="cmd-tip" data-tip="${safeTip}">${match}</span>`);
        return `\x00TOOLTIP${idx}\x00`;
      });
    }

    // Restore placeholders
    html = html.replace(/\x00TOOLTIP(\d+)\x00/g, (_, idx) => placeholders[parseInt(idx)]);

    // Parse through DOMParser to avoid direct innerHTML assignment
    const doc = new DOMParser().parseFromString(`<pre><code>${html}</code></pre>`, 'text/html');
    const newCode = doc.querySelector('code');
    block.replaceChildren(...newCode.childNodes);
  });

  // Attach event listeners for tooltip display
  initTooltipEvents(container);
}

// Global tooltip element (appended to body, avoids overflow clipping)
let tooltipEl = null;

function getTooltipEl() {
  if (!tooltipEl) {
    tooltipEl = document.createElement('div');
    tooltipEl.id = 'cmd-tooltip';
    tooltipEl.style.cssText = 'position:fixed;display:none;z-index:9999;';
    document.body.appendChild(tooltipEl);
  }
  return tooltipEl;
}

function initTooltipEvents(container) {
  container.querySelectorAll('.cmd-tip').forEach(span => {
    span.addEventListener('mouseenter', (e) => {
      const tip = getTooltipEl();
      tip.textContent = e.target.dataset.tip;
      tip.style.display = 'block';
      const rect = e.target.getBoundingClientRect();
      // Position above the element
      tip.style.left = Math.max(8, rect.left + rect.width / 2 - tip.offsetWidth / 2) + 'px';
      tip.style.top = (rect.top - tip.offsetHeight - 8) + 'px';
      // If above viewport, show below instead
      if (rect.top - tip.offsetHeight - 8 < 0) {
        tip.style.top = (rect.bottom + 8) + 'px';
      }
    });
    span.addEventListener('mouseleave', () => {
      getTooltipEl().style.display = 'none';
    });
  });
}
