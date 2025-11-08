#!/usr/bin/env bash
# maintenance_suite.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="${SCRIPT_DIR}/backup.sh"
UPDATE="${SCRIPT_DIR}/update_cleanup.sh"
LOGMON="${SCRIPT_DIR}/log_monitor.sh"

# --- Check if helper scripts exist ---
for s in "${BACKUP}" "${UPDATE}" "${LOGMON}"; do
  if [ ! -x "${s}" ]; then
    echo "⚠️  Warning: ${s} not found or not executable."
    echo "   Please make sure it's in the same folder and run: chmod +x ${s}"
  fi
done

pause() {
  read -rp "Press Enter to continue..."
}

while true; do
  clear
  cat <<'EOF'
==============================
  Capstone Maintenance Suite
==============================
1) Run Backup
2) Run System Update & Cleanup
3) Scan Logs (one-time)
4) Watch Logs (live)
5) Run Full Maintenance (Backup + Update)
6) Install Prerequisites (rsync, inotify-tools)
7) View Recent Logs
0) Exit
EOF

  read -rp "Choose an option [0-7]: " CH
  echo ""

  case "${CH}" in
    1)
      echo "🔹 Starting backup..."
      "${BACKUP}" || echo "❌ Backup failed. Check the log file for details."
      pause
      ;;
    2)
      echo "🔹 Running system update & cleanup..."
      "${UPDATE}" || echo "❌ Update/Cleanup failed. Check the log file for details."
      pause
      ;;
    3)
      echo "🔍 Scanning system logs..."
      "${LOGMON}" || true
      pause
      ;;
    4)
      echo "👀 Watching logs (Press Ctrl+C to stop)..."
      "${LOGMON}" --watch || true
      pause
      ;;
    5)
      echo "🧰 Running full maintenance (Backup + Update)..."
      "${BACKUP}" && "${UPDATE}" || echo "⚠️  One of the tasks failed. Check log files for errors."
      pause
      ;;
    6)
      echo "📦 Installing recommended packages..."
      if command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y rsync inotify-tools || true
      else
        echo "Please install 'rsync' and 'inotify-tools' using your distro’s package manager."
      fi
      pause
      ;;
    7)
      echo "===== 📁 Backup Logs ====="
      tail -n 60 "${HOME}/capstone_backups/backup.log" 2>/dev/null || echo "(No backup.log found)"
      echo ""
      echo "===== ⚙️  Update Logs ====="
      tail -n 60 "${HOME}/capstone_backups/update_cleanup.log" 2>/dev/null || echo "(No update_cleanup.log found)"
      echo ""
      echo "===== 🪵 Log Monitor ====="
      tail -n 60 "${HOME}/capstone_backups/log_monitor.log" 2>/dev/null || echo "(No log_monitor.log found)"
      echo ""
      pause
      ;;
    0)
      echo "👋 Exiting. Take care of your system!"
      exit 0
      ;;
    *)
      echo "❗ Invalid choice. Please select an option between 0–7."
      pause
      ;;
  esac
done
