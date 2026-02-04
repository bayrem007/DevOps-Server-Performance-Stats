#!/usr/bin/env bash
# server-stats.sh - Basic Linux server performance stats (portable, no extra deps)
# Usage: ./server-stats.sh

set -euo pipefail

hr() { printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' '-'; }

# --- CPU usage (total) using /proc/stat deltas ---
cpu_usage_total() {
  # Read aggregate CPU counters twice, compute utilization over the interval.
  # Fields: user nice system idle iowait irq softirq steal guest guest_nice
  local -a a b
  read -r _ a[0] a[1] a[2] a[3] a[4] a[5] a[6] a[7] _ _ < /proc/stat
  sleep 0.7
  read -r _ b[0] b[1] b[2] b[3] b[4] b[5] b[6] b[7] _ _ < /proc/stat

  local idle_a=$((a[3] + a[4]))
  local idle_b=$((b[3] + b[4]))
  local non_a=$((a[0] + a[1] + a[2] + a[5] + a[6] + a[7]))
  local non_b=$((b[0] + b[1] + b[2] + b[5] + b[6] + b[7]))

  local total_a=$((idle_a + non_a))
  local total_b=$((idle_b + non_b))

  local total_d=$((total_b - total_a))
  local idle_d=$((idle_b - idle_a))

  # Guard against divide-by-zero
  if (( total_d <= 0 )); then
    echo "N/A"
    return
  fi

  # percent = (total_d - idle_d) / total_d * 100
  awk -v td="$total_d" -v id="$idle_d" 'BEGIN { printf "%.1f%%", ((td-id)/td)*100 }'
}

# --- Memory usage (total) using /proc/meminfo ---
mem_usage() {
  # Using MemTotal and MemAvailable for a realistic "used" measure.
  local mem_total_kb mem_avail_kb
  mem_total_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
  mem_avail_kb=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)

  local mem_used_kb=$((mem_total_kb - mem_avail_kb))

  awk -v t="$mem_total_kb" -v u="$mem_used_kb" -v a="$mem_avail_kb" '
    BEGIN {
      used_pct  = (u/t)*100
      free_pct  = (a/t)*100
      # Convert kB -> GiB
      tg = t/1024/1024
      ug = u/1024/1024
      ag = a/1024/1024
      printf "Used: %.2f GiB (%.1f%%) | Free/Avail: %.2f GiB (%.1f%%) | Total: %.2f GiB", ug, used_pct, ag, free_pct, tg
    }'
}

# --- Disk usage (total) across local filesystems ---
disk_usage_total() {
  # Exclude tmpfs/devtmpfs; keep POSIX output (-P) for stable parsing.
  # Using --total gives a clean aggregated line.
  if df -P -x tmpfs -x devtmpfs --total >/dev/null 2>&1; then
    df -P -x tmpfs -x devtmpfs --total -h | awk '
      $1=="total" {
        # Columns: Filesystem Size Used Avail Use% Mounted_on
        printf "Used: %s (%s) | Free: %s | Total: %s\n", $3, $5, $4, $2
      }'
  else
    # Fallback (older df): aggregate manually in 1K blocks
    df -P -x tmpfs -x devtmpfs | awk '
      NR>1 { size+=$2; used+=$3; avail+=$4 }
      END {
        if (size==0) { print "N/A"; exit }
        pct=(used/size)*100
        # Convert KiB -> GiB
        printf "Used: %.2f GiB (%.1f%%) | Free: %.2f GiB | Total: %.2f GiB\n", used/1024/1024, pct, avail/1024/1024, size/1024/1024
      }'
  fi
}

# --- OS / uptime / load / users / failed logins (best-effort) ---
os_pretty_name() {
  if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    echo "${PRETTY_NAME:-unknown}"
  else
    echo "unknown"
  fi
}

uptime_human() {
  if command -v uptime >/dev/null 2>&1; then
    uptime -p 2>/dev/null || true
  else
    # /proc/uptime seconds
    awk '{print int($1)}' /proc/uptime | awk '
      { s=$1; d=int(s/86400); s%=86400; h=int(s/3600); s%=3600; m=int(s/60);
        printf "up %d days, %d hours, %d minutes\n", d, h, m }'
  fi
}

load_avg() {
  awk '{printf "%s %s %s\n",$1,$2,$3}' /proc/loadavg
}

logged_in_users() {
  if command -v who >/dev/null 2>&1; then
    who | awk 'END{print NR+0}'
  else
    echo "N/A"
  fi
}

failed_logins() {
  # Tries journalctl first (systemd), then /var/log/auth.log (Debian/Ubuntu),
  # then /var/log/secure (RHEL/CentOS). Returns count over last 24h when possible.
  if command -v journalctl >/dev/null 2>&1; then
    # Some systems require root for auth logs; still best-effort.
    journalctl --since "24 hours ago" 2>/dev/null | grep -Ei "Failed password|authentication failure|Invalid user" | wc -l | tr -d ' '
    return
  fi

  if [[ -r /var/log/auth.log ]]; then
    grep -Ei "Failed password|authentication failure|Invalid user" /var/log/auth.log | wc -l | tr -d ' '
    return
  fi

  if [[ -r /var/log/secure ]]; then
    grep -Ei "Failed password|authentication failure|Invalid user" /var/log/secure | wc -l | tr -d ' '
    return
  fi

  echo "N/A"
}

top5_cpu() {
  # pid, command, %cpu, %mem sorted by CPU
  ps -eo pid=,comm=,%cpu=,%mem= --sort=-%cpu 2>/dev/null | head -n 5
}

top5_mem() {
  # pid, command, %cpu, %mem sorted by MEM
  ps -eo pid=,comm=,%cpu=,%mem= --sort=-%mem 2>/dev/null | head -n 5
}

# -------------------- Output --------------------
echo "Server Stats ($(date))"
hr

printf "OS Version      : %s\n" "$(os_pretty_name)"
printf "Uptime          : %s\n" "$(uptime_human)"
printf "Load Average    : %s\n" "$(load_avg)"
printf "Logged-in Users : %s\n" "$(logged_in_users)"
printf "Failed Logins   : %s (best-effort, last 24h)\n" "$(failed_logins)"

hr
printf "Total CPU Usage : %s\n" "$(cpu_usage_total)"
printf "Memory Usage    : %s\n" "$(mem_usage)"
printf "Disk Usage      : %s" "$(disk_usage_total)"

hr
echo "Top 5 Processes by CPU Usage"
printf "%-8s %-22s %-8s %-8s\n" "PID" "COMMAND" "%CPU" "%MEM"
top5_cpu | awk '{printf "%-8s %-22.22s %-8s %-8s\n",$1,$2,$3,$4}'

hr
echo "Top 5 Processes by Memory Usage"
printf "%-8s %-22s %-8s %-8s\n" "PID" "COMMAND" "%CPU" "%MEM"
top5_mem | awk '{printf "%-8s %-22.22s %-8s %-8s\n",$1,$2,$3,$4}'

hr
echo "End of Report"