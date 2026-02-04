# Server Performance Stats (Bash)

A small Bash script that displays **basic Linux server performance statistics**.  
The goal of this project is to practice Linux fundamentals and system monitoring using only **built-in tools**.

This script works on **any Linux server** and does **not require external dependencies**.

Inspired by the Server Stats project on roadmap.sh:
https://roadmap.sh/projects/server-stats

---

## What the script shows

- Total **CPU usage (%)**
- **Memory usage**
  - Used vs Available memory
  - Percentage included
- **Disk usage**
  - Used vs Free space
  - Percentage included
- **Top 5 processes by CPU usage**
- **Top 5 processes by memory usage**

### Optional information
- OS version
- System uptime
- Load average (1, 5, 15 minutes)
- Logged-in users
- Failed login attempts (best effort)

---

## How it works

The script relies on standard Linux system interfaces:

- `/proc/stat` → CPU usage
- `/proc/meminfo` → memory statistics
- `/proc/loadavg` → system load
- `ps` → process information
- `df` → disk usage

No monitoring agents, no extra packages.

---

## Requirements

- Linux OS
- Bash
- Standard system tools (`ps`, `df`, `awk`, `grep`)

Root access is **not required**  
(Some optional stats may need elevated permissions)

---

## Usage

### Clone the repository
```bash
git clone https://github.com/your-username/server-stats.git
cd server-stats

Make the script executable
chmod +x server-stats.sh

Run the script
./server-stats.sh

Example output

Server Stats (Mon Feb 3 12:10:22 CET 2026)
------------------------------------------------------------
OS Version      : Ubuntu 22.04.3 LTS
Uptime          : up 3 days, 4 hours
Load Average    : 0.12 0.09 0.05
Logged-in Users : 1
Failed Logins   : 0

------------------------------------------------------------
Total CPU Usage : 18.4%
Memory Usage    : Used: 2.31 GiB (46.2%) | Free: 2.69 GiB (53.8%)
Disk Usage      : Used: 38G (62%) | Free: 23G | Total: 61G

------------------------------------------------------------
Top 5 Processes by CPU Usage
PID      COMMAND                 %CPU     %MEM
2413     java                    22.1     18.3
1890     docker                  10.4      6.2

------------------------------------------------------------
Top 5 Processes by Memory Usage
PID      COMMAND                 %CPU     %MEM
2413     java                    22.1     18.3
