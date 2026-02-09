#!/bin/bash
# Claude Code notification hook (4-mode: sound / speech / narrate / off)
# Reads ~/.claude/notify-enabled → "sound", "speech", "narrate", or missing/empty = off

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

if [ "$mode" = "narrate" ]; then
  input=$(cat)
  gist=""
  case "$event" in
    question)
      gist=$(echo "$input" | jq -r '.tool_input.questions[0].question // empty' 2>/dev/null) ;;
    permission|idle)
      gist=$(echo "$input" | jq -r '.message // empty' 2>/dev/null) ;;
  esac
  narrate_label="${title#Claude Code - }"
  osascript -e "display notification \"$message\" with title \"$title\""
  if [ -n "$gist" ]; then
    say "$narrate_label. $gist" &
  else
    say "$narrate_label" &
  fi
elif [ "$mode" = "speech" ]; then
  osascript -e "display notification \"$message\" with title \"$title\""
  say "$speech"
else
  # Default: sound mode
  osascript -e "display notification \"$message\" with title \"$title\" sound name \"$sound\""
fi
