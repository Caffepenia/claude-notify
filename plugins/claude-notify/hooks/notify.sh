#!/bin/bash
# Claude Code notification hook (toggle-based: sound / title / message)
# Reads ~/.claude/notify-enabled → comma-separated toggles, or missing/empty = off

config=""
[ -f ~/.claude/notify-enabled ] && config="$(cat ~/.claude/notify-enabled)"

# Legacy migration (in-memory only, does not write back)
case "$config" in
  sound)          config="sound,title,message" ;;
  speech|narrate) config="title,message" ;;
esac

# Parse toggles
has_sound=false; has_title=false; has_message=false
[[ ",$config," == *,sound,* ]]   && has_sound=true
[[ ",$config," == *,title,* ]]   && has_title=true
[[ ",$config," == *,message,* ]] && has_message=true

$has_sound || $has_title || $has_message || exit 0

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

# Build and send notification
if $has_title || $has_message; then
  cmd="display notification \"$($has_message && echo "$message" || echo "")\""
  $has_title && cmd="$cmd with title \"$title\""
  $has_sound && cmd="$cmd sound name \"$sound\""
  osascript -e "$cmd"
elif $has_sound; then
  afplay "/System/Library/Sounds/${sound}.aiff" &
fi
