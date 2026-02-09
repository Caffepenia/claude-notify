# claude-notify

macOS desktop notifications for Claude Code. Get alerted with a sound, a spoken summary, a banner, or any combination when Claude finishes work or needs your input.

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
/claude-notify:set                    # Interactive multi-select
/claude-notify:set all                # Enable all four toggles
/claude-notify:set sound,title,banner # Sound + spoken title + banner
/claude-notify:set title,message      # Spoken title + dynamic content
/claude-notify:set off                # Disable all notifications
```

Four independent toggles:

| Toggle | 中文 | Effect |
|--------|------|--------|
| `sound` | 提示音 | Play a chime sound via `afplay` |
| `title` | 標題 | Speak the event title via `say` (e.g. "Work Complete") |
| `message` | 訊息 | Speak dynamic content via `say` (e.g. the actual question text) |
| `banner` | 橫幅 | Show macOS notification banner (title + body) |

### Voice combination logic

When both `title` and `message` are enabled, they combine intelligently:

| Toggles | Event has dynamic content? | Spoken output |
|---------|---------------------------|---------------|
| title + message | Yes (e.g. a question) | "Work Complete. Which approach?" |
| title + message | No | "Work Complete" |
| title only | — | "Work Complete" |
| message only | Yes | "Which approach?" |
| message only | No | "Finished working" (fallback) |

## Events

| Event | Trigger | Sound | Title |
|-------|---------|-------|-------|
| Stop | Claude finishes working | Glass | Claude Code - Work Complete |
| Permission | Permission prompt appears | Ping | Claude Code - Permission Required |
| Idle | Waiting for input | Purr | Claude Code - Waiting for Input |
| Question | AskUserQuestion / ExitPlanMode | Tink | Claude Code - Question for You |

## How it works

The plugin registers hooks for `Stop`, `Notification`, and `PostToolUse` events. Each hook calls `notify.sh`, which reads `~/.claude/notify-enabled` for a comma-separated list of enabled toggles (`sound`, `title`, `message`, `banner`):

- **sound** — plays a chime via `afplay`
- **title** — speaks the event label via `say` (e.g. "Work Complete")
- **message** — speaks dynamic content via `say` (e.g. the actual question being asked)
- **banner** — shows a macOS notification banner via `osascript`
- Any combination works — file missing or empty means all off

Legacy config values (`sound`, `speech`, `narrate` as single mode) are auto-converted in memory.
