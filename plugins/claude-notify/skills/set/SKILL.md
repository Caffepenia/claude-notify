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

Interpret `$ARGUMENTS` and update the notification config: `~/.claude/notify-enabled`
(which components fire) and `~/.claude/notify-audio-device` (where speech is routed).
The `notify.sh` hook *reads* these files; this skill only *writes* them.

## The four components

| Key | 中文 | Effect |
|-----|------|--------|
| `sound` | 提示音 | Play a chime via `afplay` |
| `title` | 標題 | Speak the event label via `say` (e.g. "Work Complete") |
| `message` | 訊息 | Speak dynamic content via `say` (e.g. the actual question text) |
| `banner` | 橫幅 | Show a macOS notification banner (title + body) |

`notify-enabled` holds these keys as a **comma-separated list, lowercase, no spaces** —
e.g. `sound,title,banner`. The hook matches each key exactly (`*,sound,*`), so a stray
space or a capital letter silently disables that component. Normalizing the input
(below) is the whole point: it keeps the file in the exact shape the hook expects.

## Interpreting `$ARGUMENTS`

Match `$ARGUMENTS` in this order (keyword comparisons are case-insensitive):

1. **empty** → interactive multi-select — see *Interactive mode*
2. **`off`** / **`關閉`** → `rm -f ~/.claude/notify-enabled` (all components off)
3. **`all`** / **`全部`** → `echo "sound,title,message,banner" > ~/.claude/notify-enabled`
4. **starts with `device`** → audio-device routing — see *Device routing*
5. **otherwise** → a component list — see *Normalizing a list*

After any change, confirm: "Notification set to **{value}**." — or
"Notifications **disabled**." for the off path.

### Normalizing a list

Real input is messy: `Sound, Title , 橫幅`, a typo, two languages mixed. Convert it to the
canonical form *before* writing, so the hook actually honors every component:

1. Split on commas.
2. For each token: trim surrounding whitespace, lowercase it, then map Chinese → English
   (`提示音`→`sound`, `標題`→`title`, `訊息`→`message`, `橫幅`→`banner`).
3. Drop empty tokens and duplicates (keep first occurrence, so order reflects intent).
4. Validate against the four keys. Anything left over is **unknown**.

Then:

- **At least one valid key** → `echo "<keys joined by commas>" > ~/.claude/notify-enabled`.
  If there were also unknown tokens, write the valid ones and say which you ignored —
  e.g. "Set **sound,banner**; ignored unknown: `tite`." A typo should cost one component,
  not the whole config.
- **Nothing valid** (the entire input was unrecognized) → write nothing. Report the problem
  and list the four valid keys. Silently emptying the config because of a typo would be a
  nasty surprise — far worse than a clear error.

### Interactive mode (empty `$ARGUMENTS`)

1. Read the current config: `cat ~/.claude/notify-enabled 2>/dev/null` (missing/empty = all off).
2. Ask with `AskUserQuestion`, **multiSelect: true**. State the current setting in the question
   text (e.g. "Currently: sound, banner") so the choice is informed. Options:
   - **sound** / 提示音 — chime
   - **title** / 標題 — speak the event label
   - **message** / 訊息 — speak the dynamic content
   - **banner** / 橫幅 — macOS banner
3. Join the selected keys with commas and write them. If the user selects nothing (or picks
   an explicit "off"): `rm -f ~/.claude/notify-enabled`.

## Device routing

Speech (`say`) can target a specific output device via `~/.claude/notify-audio-device`.
(Sound effects via `afplay` always use the system default — `afplay` can't pick a device.)
Triggered when `$ARGUMENTS` starts with `device`:

- **`device`** alone → choose interactively:
  1. List devices: `say -a '?' 2>&1` (each line is `<id> <name>`).
  2. `AskUserQuestion` with: **default** (system default — no `-a` flag), **builtin**
     (auto-detect the built-in speaker at runtime), plus each detected device name.
  3. Apply the choice as below.
- **`device default`** → `rm -f ~/.claude/notify-audio-device` (use system default)
- **`device builtin`** → `echo "builtin" > ~/.claude/notify-audio-device`
- **`device <name>`** → `echo "<name>" > ~/.claude/notify-audio-device`

Confirm: "Audio device set to **{value}**." — or "Audio device set to **system default**."
when reset/removed.

## Keeping the skill and hook in sync

The component vocabulary above is a contract with `hooks/notify.sh`, which greps
`notify-enabled` for these exact keys and migrates legacy single-word values *in memory*
(`sound`→`sound,banner`, `speech`→`title,banner`, `narrate`→`title,message,banner`).
If you add or rename a component, change it in **both** places. This skill always writes the
new comma-separated format, so it never needs to emit — or clean up — the legacy values.
