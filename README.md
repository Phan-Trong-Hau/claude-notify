# claude-notify

Audio notifications for [Claude Code](https://claude.ai/code) — plays sound only when you're away from the terminal.

## What it does

Hooks into Claude Code events and plays 3 layers of notification when the agent needs your attention:

1. **System beep** — native OS beep
2. **Audio file** — plays `sounds/<event>.wav` or falls back to OS system sound
3. **TTS voice** — speaks the notification message

Notifications are **skipped when your terminal is in focus** — no annoying sounds while you're watching Claude work.

## Install

```bash
claude plugin marketplace add Phan-Trong-Hau/claude-plugins
claude plugin install claude-notify@Phan-Trong-Hau
```

## Events

| Event | Default message |
|-------|----------------|
| Agent stopped (`Stop`) | "Claude is waiting for your input" |
| Permission needed (`PermissionRequest`) | "Claude needs your approval" |
| Notification push (`Notification`) | "Claude has a notification" |
| Background task done (`SubagentStop`) | "Background task completed" |

## Config

Add a `"claude-notify"` key to `~/.claude/settings.json` (recommended):

```json
{
  "claude-notify": {
    "enabled": true,
    "volume": 0.8,
    "mode": "beep",
    "messages": {
      "stop": "Claude is waiting for your input",
      "permission": "Claude needs your approval",
      "notification": "Claude has a notification",
      "subagent": "Background task completed"
    }
  }
}
```

Settings in `~/.claude/settings.json` override the plugin's defaults — you only need to include the keys you want to change.

You can also edit the plugin defaults directly at `~/.claude/plugins/cache/Phan-Trong-Hau/claude-notify/1.0.0/config.json`.

### Notification modes

| `mode` | Beep | Audio file | TTS voice |
|--------|------|-----------|-----------|
| `"all"` | ✅ | ✅ | ✅ |
| `"beep"` (default) | ✅ | ❌ | ❌ |
| `"sound"` | ❌ | ✅ | ❌ |
| `"tts"` | ❌ | ❌ | ✅ |

## Custom sounds

Drop `.wav` files into the `sounds/` directory:
- `sounds/stop.wav`
- `sounds/permission.wav`
- `sounds/notification.wav`
- `sounds/subagent.wav`

Falls back to OS system sound if files are missing.

## Platform support

| Platform | Beep | Audio | TTS |
|----------|------|-------|-----|
| Windows (Git Bash / MSYS2) | ✅ PowerShell `[console]::beep` | ✅ MediaPlayer | ✅ SAPI |
| macOS | ✅ `osascript beep` | ✅ `afplay` | ✅ `say` |

## Test

```bash
bash tests/run_tests.sh
```

## License

MIT
