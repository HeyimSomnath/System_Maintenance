#!/usr/bin/env bash
# update_cleanup.sh

set -euo pipefail

LOGFILE="${HOME}/capstone_backups/update_cleanup.log"
mkdir -p "$(dirname "${LOGFILE}")"

echo "=== System update & cleanup started at $(date) ===" | tee -a "${LOGFILE}"

# --- Detect package manager ---
if command -v apt >/dev/null 2>&1; then
  PM="apt"
elif command -v apt-get >/dev/null 2>&1; then
  PM="apt-get"
elif command -v dnf >/dev/null 2>&1; then
  PM="dnf"
elif command -v pacman >/dev/null 2>&1; then
  PM="pacman"
else
  echo "Sorry, your distro isn’t supported. Please update manually." | tee -a "${LOGFILE}"
  exit 10
fi

echo "Detected package manager: ${PM}" | tee -a "${LOGFILE}"

# --- Run updates and cleanup based on distro ---
case "$PM" in
  apt|apt-get)
    echo "Updating package lists..." | tee -a "${LOGFILE}"
    sudo ${PM} update 2>&1 | tee -a "${LOGFILE}"

    echo "Upgrading installed packages..." | tee -a "${LOGFILE}"
    sudo ${PM} -y full-upgrade 2>&1 | tee -a "${LOGFILE}"

    echo "Removing unused packages..." | tee -a "${LOGFILE}"
    sudo ${PM} -y autoremove 2>&1 | tee -a "${LOGFILE}"

    echo "Cleaning apt cache..." | tee -a "${LOGFILE}"
    sudo ${PM} clean 2>&1 | tee -a "${LOGFILE}"
    ;;
  
  dnf)
    echo "Updating system packages with dnf..." | tee -a "${LOGFILE}"
    sudo dnf -y upgrade 2>&1 | tee -a "${LOGFILE}"

    echo "Cleaning up unused dependencies..." | tee -a "${LOGFILE}"
    sudo dnf -y autoremove 2>&1 | tee -a "${LOGFILE}"

    echo "Clearing dnf cache..." | tee -a "${LOGFILE}"
    sudo dnf clean all 2>&1 | tee -a "${LOGFILE}"
    ;;
  
  pacman)
    echo "Running system update with pacman..." | tee -a "${LOGFILE}"
    sudo pacman -Syu --noconfirm 2>&1 | tee -a "${LOGFILE}"

    echo "Removing orphaned packages..." | tee -a "${LOGFILE}"
    sudo pacman -Rns $(pacman -Qtdq || true) --noconfirm 2>&1 | tee -a "${LOGFILE}" || true
    ;;
esac

# --- Extra cleanup ---
echo "Clearing thumbnail cache and temporary files..." | tee -a "${LOGFILE}"
rm -rf "${HOME}/.cache/thumbnails/" 2>/dev/null || true
sudo rm -rf /tmp/* 2>/dev/null || true

echo "=== Update & cleanup completed successfully at $(date) ===" | tee -a "${LOGFILE}"
exit 0
