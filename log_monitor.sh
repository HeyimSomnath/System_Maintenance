#!/usr/bin/env bash
# log_monitor.sh

set -euo pipefail

LOG_OUT="${HOME}/capstone_backups/log_monitor.log"
mkdir -p "$(dirname "${LOG_OUT}")"

KEYWORDS=("error" "fail" "failed" "critical" "panic" "segfault")

DEFAULT_LOGS=("/var/log/syslog" "/var/log/auth.log" "/var/log/kern.log")

HAS_JOURNALCTL=$(command -v journalctl >/dev/null 2>&1 && echo "yes" || echo "no")
NOTIFY_CMD="$(command -v notify-send || true)"

MODE="scan"
FILES=()

# --- Parse arguments ---
for arg in "$@"; do
  case "$arg" in
    --watch|-w)
      MODE="watch"
      ;;
    *)
      FILES+=("$arg")
      ;;
  esac
done

# Use default logs if none provided
if [ "${#FILES[@]}" -eq 0 ]; then
  FILES=("${DEFAULT_LOGS[@]}")
fi

echo "=== Log monitor started at $(date) | mode=${MODE} | files=${FILES[*]:-none} ===" | tee -a "${LOG_OUT}"

# --- Helper: send alert ---
alert() {
  local msg="$1"
  echo "[ALERT] ${msg}" | tee -a "${LOG_OUT}"
  if [ -n "${NOTIFY_CMD}" ]; then
    notify-send "Log Monitor Alert" "${msg}" >/dev/null 2>&1 || true
  fi
}

# --- Helper: scan a single log file ---
scan_file() {
  local file="$1"

  if [ ! -r "${file}" ]; then
    if [ "${HAS_JOURNALCTL}" = "yes" ]; then
      echo "Can't read ${file}, checking recent journal logs instead..." | tee -a "${LOG_OUT}"
      journalctl -n 200 --no-pager | grep -i -E "$(IFS="|"; echo "${KEYWORDS[*]}")" | tee -a "${LOG_OUT}"
    else
      echo "Skipping ${file}: not readable." | tee -a "${LOG_OUT}"
    fi
    return
  fi

  for kw in "${KEYWORDS[@]}"; do
    matches=$(grep -i -E "${kw}" "${file}" || true)
    if [ -n "${matches}" ]; then
      echo "Found '${kw}' entries in ${file}:" | tee -a "${LOG_OUT}"
      echo "${matches}" | tee -a "${LOG_OUT}"
      alert "Detected '${kw}' in ${file}"
    fi
  done
}



if [ "${MODE}" = "scan" ]; then
  for f in "${FILES[@]}"; do
    scan_file "${f}" || true
  done
  echo "=== Log scan finished at $(date) ===" | tee -a "${LOG_OUT}"
  exit 0
else
  # --- Watch mode ---
  echo "Watching logs for live alerts..." | tee -a "${LOG_OUT}"

  # If log files are unreadable and system uses journald, fallback to journalctl
  if [ "${HAS_JOURNALCTL}" = "yes" ] && ! printf "%s\n" "${FILES[@]}" | xargs -I{} test -r {} 2>/dev/null; then
    echo "Falling back to journalctl -f (live logs)..." | tee -a "${LOG_OUT}"
    journalctl -f -n 0 | while read -r line; do
      lower_line=$(echo "${line}" | tr '[:upper:]' '[:lower:]')
      for kw in "${KEYWORDS[@]}"; do
        if echo "${lower_line}" | grep -q "${kw}"; then
          echo "${line}" | tee -a "${LOG_OUT}"
          alert "${line}"
          break
        fi
      done
    done
  else
    # Watch traditional log files using tail
    tail -F "${FILES[@]}" 2>/dev/null | while read -r line; do
      for kw in "${KEYWORDS[@]}"; do
        if echo "${line}" | grep -qi "${kw}"; then
          echo "${line}" | tee -a "${LOG_OUT}"
          alert "${line}"
          break
        fi
      done
    done
  fi
fi
