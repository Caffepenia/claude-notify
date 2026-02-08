---
disable-model-invocation: true
argument-hint: "[off|sound|speech]"
allowed-tools:
  - Bash(echo *)
  - Bash(rm *)
  - Bash(cat *)
  - AskUserQuestion
---

# /claude-notify:set — Toggle notification mode

Based on `$ARGUMENTS`, update the notification mode stored in `~/.claude/notify-enabled`.

## Rules

- If `$ARGUMENTS` is `off` or `關閉`: run `rm -f ~/.claude/notify-enabled`
- If `$ARGUMENTS` is `sound` or `提示音`: run `echo sound > ~/.claude/notify-enabled`
- If `$ARGUMENTS` is `speech` or `語音`: run `echo speech > ~/.claude/notify-enabled`
- If `$ARGUMENTS` is empty:
  1. Read the current mode: `cat ~/.claude/notify-enabled 2>/dev/null || echo "off"`
  2. Use `AskUserQuestion` to let the user pick. Show the current mode in the question. Options:
     - **sound** / 提示音 — Banner + chime sound
     - **speech** / 語音 — Banner + spoken text
     - **off** / 關閉 — Disable notifications
  3. Apply the selected mode using the rules above

After any change, confirm: "Notification mode set to **{mode}**."
