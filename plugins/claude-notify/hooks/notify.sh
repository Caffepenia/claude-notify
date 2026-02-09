#!/bin/bash
# Claude Code notification hook (toggle-based: sound / title / message / banner)
# Reads ~/.claude/notify-enabled → comma-separated toggles, or missing/empty = off

config=""
[ -f ~/.claude/notify-enabled ] && config="$(cat ~/.claude/notify-enabled)"

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
if $has_banner; then
  cmd="display notification \"$message\""
  $has_title && cmd="$cmd with title \"$title\""
  osascript -e "$cmd" 2>/dev/null
fi

# Voice via say (title = event label, message = dynamic gist)
narrate_label="${title#Claude Code - }"
text=""
if $has_title && $has_message; then
  if [ -n "$gist" ]; then
    text="$narrate_label. $gist"
  else
    text="$narrate_label"
  fi
elif $has_title; then
  text="$narrate_label"
elif $has_message; then
  if [ -n "$gist" ]; then
    text="$gist"
  else
    text="$message"
  fi
fi
[ -n "$text" ] && say "$text" &

# Sound via afplay (independent of banner and voice)
if $has_sound; then
  afplay "/System/Library/Sounds/${sound}.aiff" 2>/dev/null &
fi
