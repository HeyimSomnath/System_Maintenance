#!/usr/bin/env bash
# backup.sh

set -euo pipefail

# --- CONFIGURATION ---
SRC="${HOME}"                              # What to back up
DEST_BASE="/var/backups/capstone_backups"  # Where to store backups
RETENTION_DAYS=7                           # How long to keep backups
TIMESTAMP="$(date +'%Y-%m-%d_%H%M%S')"     # Timestamp for this backup
USER_NAME="$(whoami)"
RSYNC_BIN="$(command -v rsync || true)"
TAR_BIN="$(command -v tar || true)"

# Check if /var/backups is writable, otherwise fallback to user home
if [ ! -w "$(dirname "$DEST_BASE")" ] || [ ! -d "$(dirname "$DEST_BASE")" ]; then
  DEST_BASE="${HOME}/capstone_backups"
fi

DEST="${DEST_BASE}/${USER_NAME}/${TIMESTAMP}"
LOGFILE="${DEST_BASE}/backup.log"

mkdir -p "${DEST}" "$(dirname "${LOGFILE}")"

echo "=== Backup started at $(date) ===" | tee -a "${LOGFILE}"

# --- Check for available space (need at least 1 GB free) ---
avail_kb=$(df --output=avail -k "${DEST_BASE}" 2>/dev/null | tail -n1 || echo 0)
if [ "${avail_kb}" -lt $((1024*1024)) ]; then
  echo "ERROR: Not enough disk space at ${DEST_BASE} (need >1GB)." | tee -a "${LOGFILE}"
  exit 2
fi

# --- Perform backup ---
if [ -n "${RSYNC_BIN}" ]; then
  echo "Using rsync to perform backup..." | tee -a "${LOGFILE}"

  EXCLUDES=(
    "--exclude=${HOME}/.cache"
    "--exclude=${HOME}/Downloads"
    "--exclude=${HOME}/.thumbnails"
    "--exclude=${HOME}/snap"
  )

  rsync -aHAX --delete "${EXCLUDES[@]}" --progress "${SRC}/" "${DEST}/" 2>&1 | tee -a "${LOGFILE}"
  echo "rsync completed with exit code ${PIPESTATUS[0]}" | tee -a "${LOGFILE}"

else
  echo "rsync not found, switching to tar archive mode..." | tee -a "${LOGFILE}"
  ARCHIVE="${DEST}.tar.gz"

  if [ -n "${TAR_BIN}" ]; then
    tar -cpzf "${ARCHIVE}" -C "${HOME}" . 2>&1 | tee -a "${LOGFILE}"
    echo "Created archive: ${ARCHIVE}" | tee -a "${LOGFILE}"
  else
    echo "ERROR: Neither rsync nor tar is available. Backup failed." | tee -a "${LOGFILE}"
    exit 3
  fi
fi

# --- Cleanup old backups ---
echo "Cleaning backups older than ${RETENTION_DAYS} days..." | tee -a "${LOGFILE}"
find "${DEST_BASE}/${USER_NAME}" -maxdepth 1 -type d -mtime +"${RETENTION_DAYS}" -exec rm -rf {} \; 2>/dev/null || true
find "${DEST_BASE}/${USER_NAME}" -maxdepth 1 -name '*.tar.gz' -mtime +"${RETENTION_DAYS}" -delete 2>/dev/null || true

echo "=== Backup finished successfully at $(date) ===" | tee -a "${LOGFILE}"
exit 0
