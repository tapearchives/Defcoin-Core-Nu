#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  nu_lion_remote_health_gate.sh [--host HOST] [--user USER] [--screenshot LOCAL_PNG] [--no-clear]

Checks the physical Lion iMac before or after a Nu test launch. The gate:
  - records the Nu frontend/backend process state,
  - records the newest DefcoinCoreNu crash report timestamp,
  - optionally captures a remote screenshot,
  - clears visible crash reporter processes unless --no-clear is used,
  - appends a CSV audit row for later debugging.

This is a Codex/test helper. It does not modify wallet or blockchain data.
EOF
}

LION_HOST="${LION_HOST:-192.168.0.189}"
LION_USER="${LION_USER:-david}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_rsa_defcoin_intel_mac}"
CSV_LOG="${CSV_LOG:-/Volumes/TB5_4TB/d/litecoincore/Defcoin Core Nu/local-dev-notes/Defcoin Core Nu/nu_lion_remote_crash_gate_log.csv}"
LOCAL_SCREENSHOT=""
CLEAR_CRASHERS=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      LION_HOST="${2:?missing host}"
      shift 2
      ;;
    --user)
      LION_USER="${2:?missing user}"
      shift 2
      ;;
    --screenshot)
      LOCAL_SCREENSHOT="${2:?missing screenshot path}"
      shift 2
      ;;
    --no-clear)
      CLEAR_CRASHERS=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

SSH_OPTS=(
  -i "$SSH_KEY"
  -o IdentitiesOnly=yes
  -o HostKeyAlgorithms=+ssh-rsa
  -o PubkeyAcceptedAlgorithms=+ssh-rsa
  -o ConnectTimeout=8
)

ssh_lion() {
  ssh "${SSH_OPTS[@]}" "$LION_USER@$LION_HOST" "$@"
}

csv_escape() {
  local value=${1:-}
  value=${value//$'\n'/\\n}
  value=${value//$'\r'/}
  value=${value//\"/\"\"}
  printf '"%s"' "$value"
}

iso_now() {
  /bin/date "+%Y-%m-%dT%H:%M:%S%z"
}

ensure_log() {
  mkdir -p "$(dirname "$CSV_LOG")"
  if [[ ! -f "$CSV_LOG" ]]; then
    printf 'timestamp,host,event,status,details,latest_crash,processes,screenshot\n' > "$CSV_LOG"
  fi
}

log_event() {
  local event=$1
  local status=$2
  local details=${3:-}
  local latest_crash=${4:-}
  local processes=${5:-}
  local screenshot=${6:-}
  ensure_log
  {
    csv_escape "$(iso_now)"; printf ','
    csv_escape "$LION_HOST"; printf ','
    csv_escape "$event"; printf ','
    csv_escape "$status"; printf ','
    csv_escape "$details"; printf ','
    csv_escape "$latest_crash"; printf ','
    csv_escape "$processes"; printf ','
    csv_escape "$screenshot"; printf '\n'
  } >> "$CSV_LOG"
}

processes=$(ssh_lion 'ps axww | egrep "Defcoin|ReportCrash|Problem Reporter|CrashReporter|defcoind" | grep -v egrep' 2>/dev/null || true)
latest_crash=$(ssh_lion 'stat -f "%Sm %N" -t "%Y-%m-%d %H:%M:%S %z" "$HOME/Library/Logs/DiagnosticReports"/DefcoinCoreNu*.crash 2>/dev/null | sort -r | head -1' 2>/dev/null || true)
crashers=$(printf '%s\n' "$processes" | awk '/ReportCrash|Problem Reporter|CrashReporter/ {print $1}' || true)

screenshot_status="not_requested"
if [[ -n "$LOCAL_SCREENSHOT" ]]; then
  remote_png="/tmp/nu-lion-health-$(date +%Y%m%d-%H%M%S).png"
  if ssh_lion "screencapture -x '$remote_png' >/dev/null 2>&1"; then
    mkdir -p "$(dirname "$LOCAL_SCREENSHOT")"
    if scp "${SSH_OPTS[@]}" "$LION_USER@$LION_HOST:$remote_png" "$LOCAL_SCREENSHOT" >/dev/null 2>&1; then
      screenshot_status="$LOCAL_SCREENSHOT"
    else
      screenshot_status="copy_failed:$remote_png"
    fi
  else
    screenshot_status="capture_failed"
  fi
fi

clear_status="not_needed"
if [[ "$CLEAR_CRASHERS" -eq 1 && -n "$crashers" ]]; then
  ssh_lion 'killall "Problem Reporter" ReportCrash CrashReporter 2>/dev/null || true' >/dev/null 2>&1 || true
  sleep 1
  remaining=$(ssh_lion 'ps axww | egrep "ReportCrash|Problem Reporter|CrashReporter" | grep -v egrep' 2>/dev/null || true)
  if [[ -n "$remaining" ]]; then
    ssh_lion 'killall -9 "Problem Reporter" ReportCrash CrashReporter 2>/dev/null || true' >/dev/null 2>&1 || true
    clear_status="force_killed"
  else
    clear_status="cleared"
  fi
fi

if [[ -n "$crashers" ]]; then
  status="crash_dialog_or_reporter_seen"
else
  status="clean"
fi

details="clear_status=$clear_status"
log_event "lion_health_gate" "$status" "$details" "$latest_crash" "$processes" "$screenshot_status"

printf 'status=%s\n' "$status"
printf 'latest_crash=%s\n' "${latest_crash:-none}"
printf 'clear_status=%s\n' "$clear_status"
printf 'processes=%s\n' "${processes:-none}"
printf 'screenshot=%s\n' "$screenshot_status"
