#!/bin/bash
# Claude Code notification hook (3-mode: sound / speech / off)
# Reads ~/.claude/notify-enabled → "sound", "speech", or missing/empty = off

mode=""
[ -f ~/.claude/notify-enabled ] && mode="$(cat ~/.claude/notify-enabled)"
mode="${mode:-off}"
[ "$mode" = "off" ] && exit 0

event="${1:-stop}"
message="${2:-Claude Code needs your attention}"

case "$event" in
  stop)
    sound="Glass"
    speech="Work complete"
    title="Claude Code - Work Complete"
    ;;
  permission)
    sound="Ping"
    speech="Permission needed"
    title="Claude Code - Permission Required"
    ;;
  idle)
    sound="Purr"
    speech="Idle, waiting"
    title="Claude Code - Waiting for Input"
    ;;
  question)
    sound="Tink"
    speech="Question for you"
    title="Claude Code - Question for You"
    ;;
  *)
    sound="Glass"
    speech="Attention needed"
    title="Claude Code"
    ;;
esac

if [ "$mode" = "speech" ]; then
  osascript -e "display notification \"$message\" with title \"$title\""
  say "$speech"
else
  # Default: sound mode
  osascript -e "display notification \"$message\" with title \"$title\" sound name \"$sound\""
fi
