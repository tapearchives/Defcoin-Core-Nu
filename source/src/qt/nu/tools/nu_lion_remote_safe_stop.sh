#!/usr/bin/env bash
set -euo pipefail

LION_HOST=${LION_HOST:-192.168.0.189}
LION_USER=${LION_USER:-david}
LION_KEY=${LION_KEY:-$HOME/.ssh/id_rsa_defcoin_intel_mac}
WAIT_SECONDS=${WAIT_SECONDS:-300}
CSV_LOG=${CSV_LOG:-/Volumes/TB5_4TB/d/litecoincore/Defcoin\ Core\ Nu/local-dev-notes/Defcoin\ Core\ Nu/nu_lion_remote_crash_gate_log.csv}

ssh_lion() {
  ssh -i "$LION_KEY" \
    -o IdentitiesOnly=yes \
    -o HostKeyAlgorithms=+ssh-rsa \
    -o PubkeyAcceptedAlgorithms=+ssh-rsa \
    -o ConnectTimeout=8 \
    "$LION_USER@$LION_HOST" "$@"
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

log_event() {
  local event=$1
  local status=${2:-}
  local details=${3:-}
  mkdir -p "$(dirname "$CSV_LOG")"
  if [[ ! -f "$CSV_LOG" ]]; then
    printf 'timestamp,event,host,status,details\n' > "$CSV_LOG"
  fi
  {
    csv_escape "$(iso_now)"; printf ','
    csv_escape "$event"; printf ','
    csv_escape "$LION_HOST"; printf ','
    csv_escape "$status"; printf ','
    csv_escape "$details"; printf '\n'
  } >> "$CSV_LOG"
}

REMOTE_SCRIPT=$(cat <<'REMOTE'
set -e
APP="${NU_LION_APP:-/Users/david/_Distribution_Versions/Defcoin Core Nu/Nu-26.6.4ca-Lion-alpha-20260609-iMac/stage/Defcoin Core Nu.app}"
DATADIR="$HOME/Library/Application Support/Defcoin"
CLI="$APP/Contents/Resources/nu/bin/defcoin-cli"

nu_pids() {
  ps axww | awk '
    (index($0,"Defcoin Core Nu.app/Contents/MacOS/DefcoinCoreNu") || index($0,"DefcoinCoreNu.app/Contents/MacOS/DefcoinCoreNu")) && !index($0,"awk") {
      print $1
    }'
}

defcoind_pids() {
  ps axww | awk '
    index($0,"Resources/nu/bin/defcoind") && !index($0,"awk") {
      print $1
    }'
}

killall "Problem Reporter" ReportCrash CrashReporter 2>/dev/null || true
osascript -e 'tell application "Defcoin Core Nu" to quit' >/dev/null 2>&1 || true
osascript -e 'tell application "DefcoinCoreNu" to quit' >/dev/null 2>&1 || true
sleep 2

if [ -x "$CLI" ] && [ -d "$DATADIR" ]; then
  for conf in "$DATADIR"/nu-*-rpc-*.conf "$DATADIR"/nu-lion-rpc-*.conf "$DATADIR"/nu-test-rpc.conf; do
    [ -f "$conf" ] || continue
    "$CLI" -datadir="$DATADIR" -conf="$conf" stop >/tmp/nu-lion-remote-stop.log 2>&1 && break || true
  done
fi

deadline=$(( $(date +%s) + WAIT_SECONDS ))
while [ "$(date +%s)" -lt "$deadline" ]; do
  pids=$(defcoind_pids)
  [ -z "$pids" ] && break
  sleep 1
done

if [ -n "$(defcoind_pids)" ]; then
  echo "timeout waiting for defcoind clean shutdown: $(defcoind_pids)"
  exit 2
fi

front=$(nu_pids)
if [ -n "$front" ]; then
  kill $front 2>/dev/null || true
  sleep 2
fi
front=$(nu_pids)
if [ -n "$front" ]; then
  kill -9 $front 2>/dev/null || true
fi

echo "clean"
REMOTE
)

export WAIT_SECONDS
result=$(ssh_lion "WAIT_SECONDS=$WAIT_SECONDS sh -s" <<< "$REMOTE_SCRIPT" 2>&1) || {
  log_event "lion_remote_safe_stop" "failed" "$result"
  printf '%s\n' "$result" >&2
  exit 1
}

log_event "lion_remote_safe_stop" "clean" "$result"
printf '%s\n' "$result"
