#!/usr/bin/env bash
set -euo pipefail

# Server Health Checker — Module 0 Capstone
# Fill in each function to complete the health checker.
# Run: ./health-check.sh (text) or ./health-check.sh --json (JSON output)

JSON_MODE=false
[[ "${1:-}" == "--json" ]] && JSON_MODE=true

# ── Helper functions ─────────────────────────────────────

print_header() {
  # TODO: Print a formatted section header
  # Example: ── CPU ──────────────────────────────────
  local title="$1"
  echo ""
  echo "── ${title} ────────────────────────────────────"
}

print_report_header() {
  # TODO: Print the report header with hostname and date
  # Use: hostname, date
  echo "TODO: implement report header"
}

# ── Data collection functions ────────────────────────────

get_cpu_info() {
  # TODO: Read /proc/loadavg and print the load averages
  # Hint: cat /proc/loadavg | awk '{print $1, $2, $3}'
  echo "TODO: implement CPU info"
}

get_memory_info() {
  # TODO: Use 'free -h' to get memory usage
  # Print: Used: X / Y (Z%)
  # Hint: free -h | awk '/^Mem:/{print $3, "/", $2}'
  # For percentage: free | awk '/^Mem:/{printf "%.0f%%", $3/$2*100}'
  echo "TODO: implement memory info"
}

get_disk_info() {
  # TODO: Use 'df -h' to show disk usage for real filesystems
  # Filter out tmpfs, devtmpfs, etc.
  # Hint: df -h --type=ext4 --type=xfs --type=btrfs 2>/dev/null || df -h | grep '^/dev/'
  echo "TODO: implement disk info"
}

get_top_cpu_processes() {
  # TODO: Show top 5 processes by CPU usage
  # Hint: ps aux --sort=-%cpu | head -6
  echo "TODO: implement top CPU processes"
}

get_top_mem_processes() {
  # TODO: Show top 5 processes by memory usage
  # Hint: ps aux --sort=-%mem | head -6
  echo "TODO: implement top memory processes"
}

get_open_ports() {
  # TODO: Show listening TCP ports
  # Hint: ss -tlnp | tail -n +2
  echo "TODO: implement open ports"
}

get_service_count() {
  # TODO: Count active systemd services
  # Hint: systemctl list-units --type=service --state=active --no-pager --no-legend | wc -l
  echo "TODO: implement service count"
}

get_uptime() {
  # TODO: Show system uptime
  # Hint: uptime -p
  echo "TODO: implement uptime"
}

# ── Output functions ─────────────────────────────────────

output_text() {
  # TODO: Call each function above with print_header labels
  # See the README for the expected output format
  print_report_header
  print_header "CPU"
  get_cpu_info
  print_header "Memory"
  get_memory_info
  print_header "Disk"
  get_disk_info
  print_header "Top 5 by CPU"
  get_top_cpu_processes
  print_header "Top 5 by Memory"
  get_top_mem_processes
  print_header "Open Ports"
  get_open_ports
  print_header "Services"
  get_service_count
  print_header "Uptime"
  get_uptime
}

output_json() {
  # TODO: Output all data as a JSON object
  # Hint: Use printf or cat <<EOF to build the JSON
  # Include keys: hostname, timestamp, cpu_load, memory, disk, ports, services, uptime
  echo '{"status": "TODO: implement JSON output"}'
}

# ── Main ─────────────────────────────────────────────────

if $JSON_MODE; then
  output_json
else
  output_text
fi
