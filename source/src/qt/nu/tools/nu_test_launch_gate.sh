#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  nu_test_launch_gate.sh --app APP_PATH [--build BUILD_ID] [--log CSV_PATH] [--kill-existing] [--wait SECONDS] -- [APP_ARGS...]
  nu_test_launch_gate.sh --recheck --pid PID [--build BUILD_ID] [--app APP_PATH] [--log CSV_PATH] [--wait SECONDS]

Launches a Defcoin Core Nu test build, runs the macOS Local Network Allow
clicker with OCR fallback, audits visible crash/duplicate-instance dialogs, and
records every step to a CSV file. This is a Codex/test helper; it does not alter
firewall, TCC, or wallet data.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLICKER="$SCRIPT_DIR/macos_click_lan_allow.sh"
DEFAULT_LOG="/Volumes/TB5_4TB/d/litecoincore/Defcoin Core Nu/local-dev-notes/Defcoin Core Nu/nu_launch_allow_debug_log.csv"

APP_PATH=""
BUILD_ID=""
CSV_LOG="$DEFAULT_LOG"
WAIT_SECONDS=60
KILL_EXISTING=0
RECHECK_ONLY=0
TARGET_PID=""
APP_ARGS=()

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
    printf 'timestamp,event,build_id,app_path,pid,status,details\n' > "$CSV_LOG"
  fi
}

log_event() {
  local event=$1
  local pid=${2:-}
  local status=${3:-}
  local details=${4:-}
  ensure_log
  {
    csv_escape "$(iso_now)"; printf ','
    csv_escape "$event"; printf ','
    csv_escape "$BUILD_ID"; printf ','
    csv_escape "$APP_PATH"; printf ','
    csv_escape "$pid"; printf ','
    csv_escape "$status"; printf ','
    csv_escape "$details"; printf '\n'
  } >> "$CSV_LOG"
}

json_status() {
  printf '%s' "${1:-}" | sed -n 's/.*"status":"\([^"]*\)".*/\1/p' | head -1
}

derive_build_id() {
  if [[ -n "$BUILD_ID" ]]; then
    return
  fi
  if [[ -n "$APP_PATH" && -f "$APP_PATH/Contents/Info.plist" ]]; then
    BUILD_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist" 2>/dev/null || true)
  fi
  [[ -n "$BUILD_ID" ]] || BUILD_ID="unknown"
}

kill_existing_nu() {
  pkill -x DefcoinCoreNu 2>/dev/null || true
  pkill -x "Defcoin Core Nu" 2>/dev/null || true
  local pids
  pids=$(ps -axo pid,args | awk 'index($0,"DefcoinCoreNu.app/Contents/MacOS") || index($0,"Defcoin Core Nu.app/Contents/MacOS") || index($0,"Resources/nu/bin/defcoind") || index($0,"/defcoind ") { if (!index($0,"awk")) print $1 }' || true)
  if [[ -n "$pids" ]]; then
    kill $pids 2>/dev/null || true
    sleep 2
  fi
  pids=$(ps -axo pid,args | awk 'index($0,"DefcoinCoreNu.app/Contents/MacOS") || index($0,"Defcoin Core Nu.app/Contents/MacOS") || index($0,"Resources/nu/bin/defcoind") || index($0,"/defcoind ") { if (!index($0,"awk")) print $1 }' || true)
  if [[ -n "$pids" ]]; then
    kill -9 $pids 2>/dev/null || true
    sleep 1
  fi
}

clear_problem_reporters() {
  local pids
  pids=$(ps -axo pid,args | awk '/Problem Reporter.app\/Contents\/MacOS\/Problem Reporter/ && !/awk/ {print $1}' || true)
  if [[ -z "$pids" ]]; then
    return 0
  fi
  log_event "problem_reporter_cleared" "" "started" "$pids"
  kill $pids 2>/dev/null || true
  sleep 1
  pids=$(ps -axo pid,args | awk '/Problem Reporter.app\/Contents\/MacOS\/Problem Reporter/ && !/awk/ {print $1}' || true)
  if [[ -n "$pids" ]]; then
    kill -9 $pids 2>/dev/null || true
    log_event "problem_reporter_cleared" "" "killed" "$pids"
  else
    log_event "problem_reporter_cleared" "" "closed" ""
  fi
}

wait_for_pid() {
  local app=$1
  local deadline=$((SECONDS + WAIT_SECONDS))
  local pid=""
  while (( SECONDS < deadline )); do
    pid=$(pgrep -f "$app/Contents/MacOS/DefcoinCoreNu" | head -1 || true)
    if [[ -n "$pid" ]]; then
      printf '%s\n' "$pid"
      return 0
    fi
    pid=$(pgrep -f "$app/Contents/MacOS/Defcoin Core Nu" | head -1 || true)
    if [[ -n "$pid" ]]; then
      printf '%s\n' "$pid"
      return 0
    fi
    sleep 0.5
  done
  return 1
}

dialog_audit() {
  /usr/bin/osascript <<'APPLESCRIPT' 2>/dev/null || true
tell application "System Events"
  repeat with p in (processes whose visible is true)
    set pn to name of p
    set winNames to {}
    try
      repeat with w in windows of p
        set end of winNames to (name of w as text)
      end repeat
    end try
    if (count of winNames) > 0 then
      log pn & " :: " & winNames
    end if
  end repeat
end tell
APPLESCRIPT
}

audit_has_blocking_crash_or_duplicate() {
  printf '%s\n' "${1:-}" | grep -Eiq 'unexpectedly|Another Defcoin|Another DefcoinCoreNu|another defcoin core nu|another defcoincorenu'
}

audit_has_remaining_lan_prompt() {
  printf '%s\n' "${1:-}" | grep -Eiq 'Allow .*local network|Allow .*local networks|Local Network'
}

clear_blocking_dialogs() {
  /usr/bin/osascript <<'APPLESCRIPT' 2>/dev/null || true
on joinList(itemsList, delimiter)
  set oldDelimiters to AppleScript's text item delimiters
  set AppleScript's text item delimiters to delimiter
  set joinedText to itemsList as text
  set AppleScript's text item delimiters to oldDelimiters
  return joinedText
end joinList

tell application "System Events"
  set clearedRows to {}
  repeat with p in (processes whose visible is true)
    set pn to name of p
    try
      repeat with w in windows of p
        set winName to ""
        try
          set winName to name of w as text
        end try

        set textBits to {winName}
        try
          repeat with t in static texts of w
            try
              set end of textBits to (value of t as text)
            end try
          end repeat
        end try
        set allText to joinList(textBits, " ")

        set lowerText to do shell script "/bin/echo " & quoted form of allText & " | /usr/bin/tr '[:upper:]' '[:lower:]'"
        set shouldClear to false
        if lowerText contains "quit unexpectedly" then set shouldClear to true
        if lowerText contains "another defcoin core nu window" then set shouldClear to true
        if lowerText contains "another defcoincorenu window" then set shouldClear to true

        if shouldClear then
          set buttonNames to {}
          try
            repeat with b in buttons of w
              try
                set end of buttonNames to (name of b as text)
              end try
            end repeat
          end try

          set clickedButton to ""
          repeat with preferredName in {"OK", "Ignore", "Don't Reopen", "Don’t Reopen", "Cancel", "Close"}
            if clickedButton is "" then
              try
                click button (preferredName as text) of w
                set clickedButton to preferredName as text
              end try
            end if
          end repeat

          set end of clearedRows to pn & " :: " & winName & " :: buttons=[" & joinList(buttonNames, "|") & "] :: clicked=" & clickedButton & " :: text=" & allText
        end if
      end repeat
    end try
  end repeat
  return joinList(clearedRows, "\n")
end tell
APPLESCRIPT
}

run_allow_clicker() {
  local pid=$1
  local screenshot="/tmp/defcoin-nu-lan-allow-${BUILD_ID}-${pid}.png"
  "$CLICKER" \
    --timeout "$WAIT_SECONDS" \
    --interval 2 \
    --target-pid "$pid" \
    --ocr-fallback \
    --save-last-screenshot "$screenshot" 2>&1 || true
}

verify_no_covering_dialogs_before_allow() {
  local pid=${1:-}
  local audit
  audit=$(dialog_audit)
  if audit_has_blocking_crash_or_duplicate "$audit"; then
    log_event "pre_allow_blocking_dialog_audit" "$pid" "attention" "$audit"
    local cleared_again
    cleared_again=$(clear_blocking_dialogs)
    if [[ -n "$cleared_again" ]]; then
      log_event "blocking_dialog_cleared" "$pid" "cleared_retry" "$cleared_again"
      sleep 1
    fi
    audit=$(dialog_audit)
    if audit_has_blocking_crash_or_duplicate "$audit"; then
      log_event "pre_allow_blocking_dialog_audit" "$pid" "failed" "$audit"
      printf 'Launch gate failed: a crash or duplicate-instance dialog is still visible and may cover the Local Network Allow prompt.\n' >&2
      printf '%s\n' "$audit" >&2
      return 4
    fi
  fi
  log_event "pre_allow_blocking_dialog_audit" "$pid" "clean" "$audit"
}

verify_allow_prompt_finished() {
  local pid=${1:-}
  local audit
  audit=$(dialog_audit)
  if audit_has_blocking_crash_or_duplicate "$audit"; then
    log_event "post_allow_dialog_audit" "$pid" "failed_blocking_dialog" "$audit"
    printf 'Launch gate failed: a crash or duplicate-instance dialog appeared after the Allow click attempt.\n' >&2
    printf '%s\n' "$audit" >&2
    return 4
  fi
  if audit_has_remaining_lan_prompt "$audit"; then
    log_event "post_allow_dialog_audit" "$pid" "failed_lan_prompt_visible" "$audit"
    printf 'Launch gate failed: the Local Network Allow prompt is still visible after the click attempt.\n' >&2
    printf '%s\n' "$audit" >&2
    return 4
  fi
  log_event "post_allow_dialog_audit" "$pid" "clean" "$audit"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --app) APP_PATH=$2; shift 2 ;;
      --build) BUILD_ID=$2; shift 2 ;;
      --log) CSV_LOG=$2; shift 2 ;;
      --wait|--timeout) WAIT_SECONDS=$2; shift 2 ;;
      --kill-existing) KILL_EXISTING=1; shift ;;
      --recheck) RECHECK_ONLY=1; shift ;;
      --pid|--target-pid) TARGET_PID=$2; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      --)
        shift
        APP_ARGS=("$@")
        break
        ;;
      *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
  done
}

parse_args "$@"

if [[ "$RECHECK_ONLY" -eq 0 && -z "$APP_PATH" ]]; then
  usage >&2
  exit 2
fi
if [[ "$RECHECK_ONLY" -eq 1 && -z "$TARGET_PID" ]]; then
  usage >&2
  exit 2
fi
if [[ ! "$WAIT_SECONDS" =~ ^[0-9]+$ || "$WAIT_SECONDS" -lt 1 ]]; then
  echo "--wait must be an integer >= 1." >&2
  exit 2
fi

derive_build_id
ensure_log

if [[ "$RECHECK_ONLY" -eq 1 ]]; then
  log_event "allow_recheck_start" "$TARGET_PID" "started" "wait=${WAIT_SECONDS}s"
  clear_problem_reporters
  cleared=$(clear_blocking_dialogs)
  if [[ -n "$cleared" ]]; then
    log_event "blocking_dialog_cleared" "$TARGET_PID" "cleared" "$cleared"
    sleep 1
  fi
  verify_no_covering_dialogs_before_allow "$TARGET_PID"
  click_result=$(run_allow_clicker "$TARGET_PID")
  click_status=$(json_status "$click_result")
  [[ -n "$click_status" ]] || click_status="unknown"
  log_event "allow_recheck_result" "$TARGET_PID" "$click_status" "$click_result"
  verify_allow_prompt_finished "$TARGET_PID"
  audit=$(dialog_audit)
  audit_status="clean"
  if printf '%s\n' "$audit" | grep -Eiq 'unexpectedly|Another Defcoin|Allow .*local network|Local Network'; then
    audit_status="attention"
  fi
  log_event "dialog_audit" "$TARGET_PID" "$audit_status" "$audit"
  if [[ -n "${cleared:-}" ]]; then
    printf '%s\n' "$cleared"
  fi
  printf '%s\n' "$click_result"
  printf '%s\n' "$audit"
  exit 0
fi

log_event "build_seen" "" "seen" "mtime=$(stat -f '%Sm' "$APP_PATH" 2>/dev/null || true)"

if [[ "$KILL_EXISTING" -eq 1 ]]; then
  log_event "prelaunch_kill_existing" "" "started" ""
  kill_existing_nu
  clear_problem_reporters
  remaining=$(ps -axo pid,args | awk 'index($0,"DefcoinCoreNu.app/Contents/MacOS") || index($0,"Defcoin Core Nu.app/Contents/MacOS") || index($0,"Resources/nu/bin/defcoind") || index($0,"/defcoind ") { if (!index($0,"awk")) print $0 }' || true)
  if [[ -n "$remaining" ]]; then
    log_event "prelaunch_kill_existing" "" "remaining" "$remaining"
  else
    log_event "prelaunch_kill_existing" "" "clean" ""
  fi
fi

args_text=""
if (( ${#APP_ARGS[@]} > 0 )); then
  args_text="${APP_ARGS[*]}"
fi
log_event "launch_start" "" "started" "args=$args_text"
if (( ${#APP_ARGS[@]} > 0 )); then
  /usr/bin/open "$APP_PATH" --args "${APP_ARGS[@]}"
else
  /usr/bin/open "$APP_PATH"
fi
if ! TARGET_PID=$(wait_for_pid "$APP_PATH"); then
  log_event "launch_result" "" "pid_not_found" ""
  exit 3
fi
log_event "launch_result" "$TARGET_PID" "pid_found" ""

clear_problem_reporters
cleared=$(clear_blocking_dialogs)
if [[ -n "$cleared" ]]; then
  log_event "blocking_dialog_cleared" "$TARGET_PID" "cleared" "$cleared"
  sleep 1
fi

verify_no_covering_dialogs_before_allow "$TARGET_PID"
click_result=$(run_allow_clicker "$TARGET_PID")
click_status=$(json_status "$click_result")
[[ -n "$click_status" ]] || click_status="unknown"
log_event "allow_click_result" "$TARGET_PID" "$click_status" "$click_result"
verify_allow_prompt_finished "$TARGET_PID"

audit=$(dialog_audit)
audit_status="clean"
if printf '%s\n' "$audit" | grep -Eiq 'unexpectedly|Another Defcoin|Allow .*local network|Local Network'; then
  audit_status="attention"
fi
log_event "dialog_audit" "$TARGET_PID" "$audit_status" "$audit"

printf 'pid=%s\n' "$TARGET_PID"
if [[ -n "${cleared:-}" ]]; then
  printf '%s\n' "$cleared"
fi
printf '%s\n' "$click_result"
printf '%s\n' "$audit"
