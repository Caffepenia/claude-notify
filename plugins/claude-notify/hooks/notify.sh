#!/bin/bash
# Claude Code notification hook (toggle-based: sound / title / message / banner)
# Reads ~/.claude/notify-enabled → comma-separated toggles, or missing/empty = off

# Per-session PID file (PPID = the Claude Code process that spawned this hook)
pidfile="/tmp/claude-notify-pids-$PPID"

# Cancel mode: kill running say/afplay from previous notifications
if [ "$1" = "cancel" ]; then
  if [ -f "$pidfile" ]; then
    while read -r pid; do
      kill "$pid" 2>/dev/null
      pkill -P "$pid" 2>/dev/null
    done < "$pidfile"
    rm -f "$pidfile"
  fi
  exit 0
fi

config=""
[ -f ~/.claude/notify-enabled ] && config="$(cat ~/.claude/notify-enabled)"

audio_device=""
[ -f ~/.claude/notify-audio-device ] && audio_device="$(cat ~/.claude/notify-audio-device)"

say_device_args=()
if [ -n "$audio_device" ] && [ "$audio_device" != "default" ]; then
  if [ "$audio_device" = "builtin" ]; then
    audio_device=$(say -a '?' 2>&1 | sed 's/^ *[0-9]* //' | grep -iE "^(Mac|iMac).*Speakers" | head -1)
  fi
  [ -n "$audio_device" ] && say_device_args=(-a "$audio_device")
fi

# Legacy migration (in-memory only, does not write back)
case "$config" in
  sound)          config="sound,banner" ;;
  speech)         config="title,banner" ;;
  narrate)        config="title,message,banner" ;;
esac

# Parse toggles
has_sound=false; has_title=false; has_message=false; has_banner=false
[[ ",$config," == *,sound,* ]]   && has_sound=true
[[ ",$config," == *,title,* ]]   && has_title=true
[[ ",$config," == *,message,* ]] && has_message=true
[[ ",$config," == *,banner,* ]]  && has_banner=true

$has_sound || $has_title || $has_message || $has_banner || exit 0

# Event definitions
event="${1:-stop}"
message="${2:-Claude Code needs your attention}"

case "$event" in
  stop)       sound="Glass"; title="Claude Code - Work Complete" ;;
  permission) sound="Ping";  title="Claude Code - Permission Required" ;;
  idle)       sound="Purr";  title="Claude Code - Waiting for Input" ;;
  question)   sound="Tink";  title="Claude Code - Question for You" ;;
  *)          sound="Glass"; title="Claude Code" ;;
esac

# Read stdin for dynamic gist (used by title/message voice)
gist=""
if $has_message; then
  input=$(cat)
  case "$event" in
    question)
      gist=$(echo "$input" | jq -r '.tool_input.questions[0].question // empty' 2>/dev/null) ;;
    permission|idle)
      gist=$(echo "$input" | jq -r '.message // empty' 2>/dev/null) ;;
  esac
fi

# Banner notification (macOS notification center)
# Escape backslashes and double quotes to prevent AppleScript injection
if $has_banner; then
  _as_msg="${message//\\/\\\\}"; _as_msg="${_as_msg//\"/\\\"}"
  _as_title="${title//\\/\\\\}"; _as_title="${_as_title//\"/\\\"}"
  cmd="display notification \"$_as_msg\""
  $has_title && cmd="$cmd with title \"$_as_title\""
  osascript -e "$cmd" 2>/dev/null
fi

# Voice via say (title = event label, message = dynamic gist)
# Use Meijia voice for Chinese text, default voice for English
_say_smart() {
  local _b _c
  _b=$(printf "%s" "$1" | wc -c | tr -d " ")
  _c=${#1}
  if [ "$_b" -gt "$_c" ]; then
    say "${say_device_args[@]}" -v Meijia "$1"
  else
    say "${say_device_args[@]}" "$1"
  fi
}

# Run a command in the background, track its PID, and detach it
_run_bg() {
  "$@" </dev/null >/dev/null 2>&1 &
  echo $! >> "$pidfile"
  disown $! 2>/dev/null
}

# Speak event label then dynamic gist (used as a single backgrounded unit)
_narrate_with_gist() {
  say "${say_device_args[@]}" "$1" && _say_smart "$2"
}

# Cancel any still-running previous notification (prevents voice overlap)
if [ -f "$pidfile" ]; then
  while read -r pid; do
    kill "$pid" 2>/dev/null
    pkill -P "$pid" 2>/dev/null
  done < "$pidfile"
fi
: > "$pidfile"

narrate_label="${title#Claude Code - }"
if $has_title && $has_message; then
  if [ -n "$gist" ]; then
    _run_bg _narrate_with_gist "$narrate_label" "$gist"
  else
    _run_bg say "${say_device_args[@]}" "$narrate_label"
  fi
elif $has_title; then
  _run_bg say "${say_device_args[@]}" "$narrate_label"
elif $has_message; then
  if [ -n "$gist" ]; then
    _run_bg _say_smart "$gist"
  else
    _run_bg _say_smart "$message"
  fi
fi

# Sound via afplay (independent of banner and voice)
if $has_sound; then
  _run_bg afplay "/System/Library/Sounds/${sound}.aiff"
fi
