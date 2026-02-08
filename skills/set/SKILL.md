---
disable-model-invocation: true
argument-hint: "[off|sound|speech]"
allowed-tools:
  - Bash(echo *)
  - Bash(rm *)
  - Bash(cat *)
---

# /claude-notify:set — Toggle notification mode

Based on `$ARGUMENTS`, update the notification mode stored in `~/.claude/notify-enabled`.

## Rules

- If `$ARGUMENTS` is `off` or `關閉`: run `rm -f ~/.claude/notify-enabled`
- If `$ARGUMENTS` is `sound` or `提示音`: run `echo sound > ~/.claude/notify-enabled`
- If `$ARGUMENTS` is `speech` or `語音`: run `echo speech > ~/.claude/notify-enabled`
- If `$ARGUMENTS` is empty: read and report the current mode:
  - Run `cat ~/.claude/notify-enabled 2>/dev/null || echo "(off)"`
  - Report the result as: "Notification mode: **{mode}**"

After any change, confirm: "Notification mode set to **{mode}**."
