# claude-notify

macOS desktop notifications for Claude Code. Get alerted with a sound, spoken text, or both when Claude finishes work or needs your input.

## Install

1. In Claude Code, run `/plugin` → **Add Marketplace** → enter `Caffepenia/claude-notify`
2. Enable the `claude-notify` plugin from the marketplace list

Or load directly for a single session:
```bash
claude --plugin-dir ~/claude-notify/plugins/claude-notify
```

## Usage

Toggle notification mode with the `/claude-notify:set` skill:

```
/claude-notify:set          # Show current mode
/claude-notify:set sound    # Banner + chime sound
/claude-notify:set speech   # Banner + spoken phrase
/claude-notify:set narrate  # Banner + read aloud title & message
/claude-notify:set off      # Disable notifications
```

## Events

| Event | Trigger | Sound | Speech | Narrate |
|-------|---------|-------|--------|---------|
| Stop | Claude finishes working | Glass | "Work complete" | title + message |
| Permission | Permission prompt appears | Ping | "Permission needed" | title + message |
| Idle | Waiting for input | Purr | "Idle, waiting" | title + message |
| Question | AskUserQuestion / ExitPlanMode | Tink | "Question for you" | title + message |

## How it works

The plugin registers hooks for `Stop`, `Notification`, and `PostToolUse` events. Each hook calls `notify.sh`, which reads `~/.claude/notify-enabled` to determine the mode:

- **sound** — macOS banner notification with a chime
- **speech** — macOS banner notification + short spoken phrase
- **narrate** — macOS banner notification + `say` reads full title & message
- **off** (or file missing) — silent
