---
disable-model-invocation: true
argument-hint: "[off|all|sound|title|message|banner|device ...|...]"
allowed-tools:
  - Bash(echo *)
  - Bash(rm *)
  - Bash(cat *)
  - Bash(say *)
  - AskUserQuestion
---

# /claude-notify:set — Toggle notification components

Based on `$ARGUMENTS`, update the enabled notification components stored in `~/.claude/notify-enabled`.

## Components

| Key | 中文 | Effect |
|-----|------|--------|
| `sound` | 提示音 | Play a chime sound via `afplay` |
| `title` | 標題 | Speak the event title via `say` (e.g. "Work Complete") |
| `message` | 訊息 | Speak dynamic content via `say` (e.g. the actual question text) |
| `banner` | 橫幅 | Show macOS notification banner (title + body) |

**Audio device**: Speech (`say`) can be routed to a specific output device via `~/.claude/notify-audio-device`. See the **device** argument below. Sound effects (`afplay`) always use the system default.

## Device argument

If `$ARGUMENTS` starts with `device`:

- **`device`** (no value after it):
  1. Run `say -a '?' 2>&1` to list available audio devices
  2. Parse device names from output (each line: `<id> <name>`)
  3. Use `AskUserQuestion` with options:
     - **default** — Use system default audio device (no `-a` flag)
     - **builtin** — Auto-detect built-in speaker at runtime
     - Plus each detected device name from the `say -a '?'` output
  4. If user selects "default": `rm -f ~/.claude/notify-audio-device`
  5. If user selects "builtin": `echo "builtin" > ~/.claude/notify-audio-device`
  6. Otherwise: `echo "<selected device>" > ~/.claude/notify-audio-device`
- **`device default`**: run `rm -f ~/.claude/notify-audio-device`
- **`device builtin`**: run `echo "builtin" > ~/.claude/notify-audio-device`
- **`device <name>`**: run `echo "<name>" > ~/.claude/notify-audio-device`

After any change, confirm: "Audio device set to **{value}**." or "Audio device set to **system default**." if default/removed.

## Rules

- If `$ARGUMENTS` is `off` or `關閉`: run `rm -f ~/.claude/notify-enabled`
- If `$ARGUMENTS` is `all` or `全部`: run `echo "sound,title,message,banner" > ~/.claude/notify-enabled`
- If `$ARGUMENTS` is a comma-separated list (e.g. `sound,title,banner` or `提示音,標題,橫幅`):
  1. Normalize Chinese names: 提示音→sound, 標題→title, 訊息→message, 橫幅→banner
  2. Write the normalized value: `echo "<normalized>" > ~/.claude/notify-enabled`
- If `$ARGUMENTS` is empty:
  1. Read current config: `cat ~/.claude/notify-enabled 2>/dev/null`
  2. Use `AskUserQuestion` with **multiSelect: true**. Show the current state in the question. Options:
     - **sound** / 提示音 — Play a chime sound
     - **title** / 標題 — Speak event title (e.g. "Work Complete")
     - **message** / 訊息 — Speak dynamic content (e.g. the question text)
     - **banner** / 橫幅 — Show macOS notification banner
  3. If user selects nothing (or chooses "off"): run `rm -f ~/.claude/notify-enabled`
  4. Otherwise: join selected keys with commas and write to `~/.claude/notify-enabled`

After any change, confirm: "Notification set to **{value}**." or "Notifications **disabled**." if off.

### Legacy mode names

If the file contains an old single-word mode, the hook migrates it in memory:
- `sound` → `sound,banner`
- `speech` → `title,banner`
- `narrate` → `title,message,banner`

The SKILL does **not** need to handle this — it always writes the new comma-separated format.
