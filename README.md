A lightweight Bash script that analyzes basic Linux server performance metrics using standard system interfaces.
It is designed to be portable, dependency-free, and runnable on any Linux server.

✨ Features

The script reports the following system statistics:

Total CPU usage (%)

Calculated using /proc/stat over a short interval

Memory usage

Used vs Available memory

Includes percentages

Disk usage

Used vs Free space

Aggregated across local filesystems (excluding tmpfs)

Top 5 processes by CPU usage

Top 5 processes by memory usage

🔹 Optional / Stretch Metrics

OS version

System uptime

Load average (1, 5, 15 min)

Logged-in users

Failed login attempts (best-effort)

🛠️ How It Works

This project relies only on:

Linux kernel virtual filesystems (/proc)

Standard Unix utilities (ps, df, awk, grep)

No external packages or monitoring agents are required.

Key data sources:

/proc/stat → CPU usage

/proc/meminfo → memory usage

/proc/loadavg → system load

ps → process statistics

df → disk usage

📦 Requirements

Linux OS

Bash (>= 4.x recommended)

Standard GNU tools (ps, df, awk)

No root access required
(Some optional stats like failed logins may require elevated permissions)

🚀 Usage
1️⃣ Clone the repository
git clone https://github.com/your-username/server-stats.git
cd server-stats

2️⃣ Make the script executable
chmod +x server-stats.sh

3️⃣ Run the script
./server-stats.sh

📋 Sample Output
Server Stats (Mon Feb 3 12:10:22 CET 2026)
------------------------------------------------------------
OS Version      : Ubuntu 22.04.3 LTS
Uptime          : up 3 days, 4 hours
Load Average    : 0.12 0.09 0.05
Logged-in Users : 1
Failed Logins   : 0 (last 24h)

------------------------------------------------------------
Total CPU Usage : 18.4%
Memory Usage    : Used: 2.31 GiB (46.2%) | Free: 2.69 GiB (53.8%)
Disk Usage      : Used: 38G (62%) | Free: 23G | Total: 61G

------------------------------------------------------------
Top 5 Processes by CPU Usage
PID      COMMAND                 %CPU     %MEM
2413     java                    22.1     18.3
1890     docker                  10.4      6.2
...

------------------------------------------------------------
Top 5 Processes by Memory Usage
PID      COMMAND                 %CPU     %MEM
2413     java                    22.1     18.3
