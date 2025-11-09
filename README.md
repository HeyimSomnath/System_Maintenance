# 🧩 Capstone Project — Bash Scripting Suite for System Maintenance

## 📘 Objective
This project is part of the LinuxOS & LSP Capstone.  
The goal is to develop a **suite of Bash scripts** that automate common **system maintenance tasks**, including:
- Backups of user data  
- System updates and cleanup  
- Log monitoring and alerting  

Finally, all scripts are integrated into a **menu-driven main script** for ease of use.

---

## 📅 Day-wise Implementation (as per the official Capstone PDF)

| Day | Task | Description |
|-----|------|--------------|
| **Day 1** | Automated Backup Script | Created `backup.sh` to back up files and directories using `rsync` (or `tar` fallback). Includes logging and old backup rotation. |
| **Day 2** | System Update & Cleanup Script | Developed `update_cleanup.sh` to run OS updates, remove unnecessary packages, and clear caches. |
| **Day 3** | Log Monitoring Script | Built `log_monitor.sh` to detect errors, failures, or critical messages in system logs (or any custom log files). |
| **Day 4** | Integration | Combined all scripts into a single interactive tool `maintenance_suite.sh` with a text-based menu interface. |
| **Day 5** | Testing & Error Handling | Added proper logging, fallbacks, and verification across all scripts for robustness and user feedback. |

---

## 🧠 Project Overview

### 🗂️ Scripts Included
| Script | Purpose |
|--------|----------|
| `backup.sh` | Performs daily/weekly backups of user data to a destination directory. Supports rotation & logging. |
| `update_cleanup.sh` | Updates packages, cleans temporary and cached files, and logs results. |
| `log_monitor.sh` | Scans or watches logs for keywords like “error”, “fail”, “panic”, etc., and alerts the user. |
| `maintenance_suite.sh` | Master menu that lets the user choose which task to run, view logs, or perform all maintenance together. |

---

## ⚙️ System Requirements
- **Operating System:** Linux (Ubuntu/Debian recommended)  
- **Shell:** Bash  
- **Tools used:** `rsync`, `tar`, `apt`, `journalctl`, `grep`, `tail`, `notify-send` (optional for GUI alerts)

> 📝 Note: WSL (Windows Subsystem for Linux) works fine for testing.  
> Some log monitoring features (journalctl) may show “No journal files found” if systemd logging is disabled — that’s normal.

---

## 🧰 Installation & Setup

1. Clone or copy the project folder to your Linux system or WSL:

```
sudo apt install dos2unix -y
dos2unix *.sh
```

```
chmod +x backup.sh update_cleanup.sh log_monitor.sh maintenance_suite.sh
```

```
./maintenance_suite.sh

```
