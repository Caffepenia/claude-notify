# claude-notify

macOS desktop notifications for Claude Code. Get alerted with a sound, a banner, or both when Claude finishes work or needs your input.

## Install

1. In Claude Code, run `/plugin` → **Add Marketplace** → enter `Caffepenia/claude-notify`
2. Enable the `claude-notify` plugin from the marketplace list

Or load directly for a single session:
```bash
claude --plugin-dir ~/claude-notify/plugins/claude-notify
```

## Usage

Toggle notification components with the `/claude-notify:set` skill:

```
/claude-notify:set                # Interactive multi-select
/claude-notify:set all            # Enable sound + title + message
/claude-notify:set sound,title    # Enable sound and title only
/claude-notify:set message        # Enable message body only
/claude-notify:set off            # Disable all notifications
```

Three independent toggles:

| Toggle | Effect |
|--------|--------|
| `sound` | Play a chime sound |
| `title` | Show notification banner with event title |
| `message` | Include message body in the notification |

## Events

| Event | Trigger | Sound | Title |
|-------|---------|-------|-------|
| Stop | Claude finishes working | Glass | Claude Code - Work Complete |
| Permission | Permission prompt appears | Ping | Claude Code - Permission Required |
| Idle | Waiting for input | Purr | Claude Code - Waiting for Input |
| Question | AskUserQuestion / ExitPlanMode | Tink | Claude Code - Question for You |

## How it works

The plugin registers hooks for `Stop`, `Notification`, and `PostToolUse` events. Each hook calls `notify.sh`, which reads `~/.claude/notify-enabled` for a comma-separated list of enabled components (`sound`, `title`, `message`):

- **sound + title + message** — full banner notification with chime
- **sound** only — plays the chime without showing a banner
- **title + message** — silent banner notification
- Any combination works — file missing or empty means all off

Legacy config values (`sound`, `speech`, `narrate` as single mode) are auto-converted in memory.
