#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  udp_lan_permission_gate.sh [--log PATH] [--log PATH ...] [--timeout SECONDS] [--quiet]

Watches Defcoin Core Nu launch/test logs for UDP Fast Sync or Quick Clone
activity. If no UDP receive/ack evidence appears before the timeout, the script
alerts loudly so the operator can check for a macOS Local Network permission
prompt before protocol debugging continues.

This is a test helper only. It does not change firewall, TCC, or network
settings.
EOF
}

LOG_PATHS=()

add_default_logs_for_datadir() {
  local datadir=$1
  [[ -n "$datadir" ]] || return 0
  LOG_PATHS+=("$datadir/console.log")
  LOG_PATHS+=("$datadir/debug.log")
}

add_default_logs_for_datadir "${DEFCOIN_DATADIR:-}"
add_default_logs_for_datadir "${HOME}/Library/Application Support/Defcoin"
add_default_logs_for_datadir "/Volumes/TB5_4TB/d/Library/Application Support/Defcoin"

# Keep the list deterministic while avoiding duplicate paths when DEFCOIN_DATADIR
# points at one of the normal locations.
declare -a LOG_PATHS_DEDUPED=()
for log_path in "${LOG_PATHS[@]}"; do
  seen=0
  if ((${#LOG_PATHS_DEDUPED[@]} > 0)); then
    for existing in "${LOG_PATHS_DEDUPED[@]}"; do
      if [[ "$existing" == "$log_path" ]]; then
        seen=1
        break
      fi
    done
  fi
  [[ "$seen" -eq 1 ]] || LOG_PATHS_DEDUPED+=("$log_path")
done
LOG_PATHS=("${LOG_PATHS_DEDUPED[@]}")
TIMEOUT_SECONDS=35
QUIET=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --log)
      if [[ "${LOG_PATHS_CUSTOM:-0}" -eq 0 ]]; then
        LOG_PATHS=()
        LOG_PATHS_CUSTOM=1
      fi
      LOG_PATHS+=("$2")
      shift 2
      ;;
    --timeout) TIMEOUT_SECONDS=$2; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ ! "$TIMEOUT_SECONDS" =~ ^[0-9]+$ || "$TIMEOUT_SECONDS" -lt 5 ]]; then
  echo "Timeout must be an integer >= 5 seconds." >&2
  exit 2
fi

declare -a START_SIZES=()
for log_path in "${LOG_PATHS[@]}"; do
  mkdir -p "$(dirname "$log_path")"
  touch "$log_path"
  START_SIZES+=("$(wc -c < "$log_path" | tr -d ' ')")
done

deadline=$((SECONDS + TIMEOUT_SECONDS))

success_re='(UDP.*(ack|accepted|received|chunk|block)|Fast Sync.*UDP.*(accepted|received|ack)|Quick Clone.*UDP.*(accepted|received|ack)|delivered block.*UDP)'
blocker_re='(Local Network|permission|Operation not permitted|Network is unreachable|UDP.*(blocked|bind failed|permission denied|cooldown|timeout))'

alert() {
  local message=$1
  /usr/bin/osascript -e 'beep 3' >/dev/null 2>&1 || true
  /usr/bin/say "$message" >/dev/null 2>&1 || true
  echo "$message"
}

[[ "$QUIET" -eq 1 ]] || {
  echo "Watching UDP LAN activity for ${TIMEOUT_SECONDS}s in:"
  printf '  %s\n' "${LOG_PATHS[@]}"
}

while (( SECONDS < deadline )); do
  recent=""
  for i in "${!LOG_PATHS[@]}"; do
    log_path=${LOG_PATHS[$i]}
    start_size=${START_SIZES[$i]}
    recent+=$'\n'
    recent+="$(tail -c "+$((start_size + 1))" "$log_path" 2>/dev/null || true)"
  done
  if printf '%s\n' "$recent" | grep -Eiq "$success_re"; then
    [[ "$QUIET" -eq 1 ]] || echo "UDP LAN activity observed."
    exit 0
  fi
  if printf '%s\n' "$recent" | grep -Eiq "$blocker_re"; then
    alert "Defcoin Core Nu UDP LAN test may be blocked. Please check for a Local Network permission prompt."
    exit 3
  fi
  sleep 1
done

alert "Defcoin Core Nu UDP LAN test did not show UDP activity. Please check for a Local Network permission prompt."
exit 3
