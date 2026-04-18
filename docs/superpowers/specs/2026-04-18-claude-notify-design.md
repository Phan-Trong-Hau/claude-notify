# claude-notify — Design Spec

**Date:** 2026-04-18

## Overview

A Claude Code plugin that plays audio notifications (system beep + audio file + TTS) when the agent needs user attention, but **only when the user is not focused on the terminal**. Distributed as a single GitHub repo that doubles as its own plugin marketplace.

---

## Goals

- Notify user via sound when Claude stops and waits for input
- Support 3 notification layers simultaneously: system beep, audio file, TTS voice
- Skip notifications when terminal is already in focus (user is watching)
- Work on Windows and macOS with zero external dependencies
- Installable as a native Claude Code plugin via `enabledPlugins`

---

## Plugin Structure

```
claude-notify/
├── .claude-plugin/
│   ├── plugin.json          # Plugin metadata (name, version, author)
│   └── marketplace.json     # Self-referencing marketplace entry
├── hooks/
│   └── hooks.json           # Hook definitions using ${CLAUDE_PLUGIN_ROOT}
├── scripts/
│   ├── notify.sh            # Entry point: receives event, checks focus, dispatches
│   ├── focus.sh             # Focus detection per OS
│   ├── sound.sh             # Audio file playback
│   ├── tts.sh               # Text-to-speech
│   └── sysbeep.sh           # Native system beep
├── sounds/
│   ├── stop.wav
│   ├── permission.wav
│   └── notification.wav
├── config.json              # Default user config
├── package.json             # npm-style metadata
└── README.md
```

---

## Hook Events

| Event | Message |
|-------|---------|
| `Stop` | "Claude is waiting for your input" |
| `PermissionRequest` | "Claude needs your approval" |
| `Notification` | "Claude has a notification" |
| `SubagentStop` | "Background task completed" |

All hooks call `notify.sh <event>` with `async: true` so they never block Claude.

---

## Focus Detection

### Windows
Use PowerShell Win32 API (`GetForegroundWindow` + `GetWindowThreadProcessId`) to get the PID of the focused window. Walk the process tree upward to find if any ancestor matches known terminal processes: `WindowsTerminal`, `mintty`, `conhost`, `cmd`, `powershell`, `bash`, `wezterm`, `alacritty`.

If the focused window belongs to a terminal process → **skip notification**.

### macOS
Use `osascript` to get the name of the frontmost application. Compare against known terminal apps: `Terminal`, `iTerm2`, `Warp`, `Alacritty`, `kitty`, `Hyper`, `WezTerm`.

If frontmost app is a terminal → **skip notification**.

---

## Notification Layers

All 3 layers run sequentially when unfocused. Each can be individually disabled in `config.json`.

### 1. System Beep (`sysbeep.sh`)
- Windows: `powershell -Command "[console]::beep(800, 300)"`
- macOS: `osascript -e 'beep'`

### 2. Audio File (`sound.sh`)
- Windows: PowerShell `System.Windows.Media.MediaPlayer`
- macOS: `afplay -v $VOLUME $FILE`
- Falls back silently if file not found

### 3. TTS (`tts.sh`)
- Windows: PowerShell `System.Speech.Synthesis.SpeechSynthesizer`
- macOS: `say "$MESSAGE"`
- Message is per-event, configurable in `config.json`

---

## Config (`config.json`)

```json
{
  "enabled": true,
  "volume": 0.8,
  "notify": {
    "sysbeep": true,
    "sound": true,
    "tts": true
  },
  "messages": {
    "Stop": "Claude is waiting for your input",
    "PermissionRequest": "Claude needs your approval",
    "Notification": "Claude has a notification",
    "SubagentStop": "Background task completed"
  },
  "terminal_apps": {
    "macos": ["Terminal", "iTerm2", "Warp", "Alacritty", "kitty", "Hyper", "WezTerm"],
    "windows": ["WindowsTerminal", "mintty", "conhost", "cmd", "powershell", "bash", "wezterm", "alacritty"]
  }
}
```

---

## Marketplace & Install

### `marketplace.json` (self-referencing)
```json
{
  "name": "owner-name",
  "description": "Claude Code audio notification plugin",
  "plugins": [{
    "name": "claude-notify",
    "description": "Audio notifications when Claude needs attention — only when you're away",
    "version": "1.0.0",
    "source": { "source": "url", "url": "https://github.com/owner/claude-notify.git" }
  }]
}
```

### User install (manual)
Add to `~/.claude/settings.json`:
```json
"extraKnownMarketplaces": {
  "owner": { "source": { "source": "github", "repo": "owner/claude-notify" } }
},
"enabledPlugins": { "claude-notify@owner": true }
```

Or use the `/plugins` menu inside Claude Code.

---

## Error Handling

- All scripts exit `0` on failure — hooks must never block Claude
- Missing audio file: skip silently
- Unsupported OS: skip silently
- Malformed config.json: fall back to defaults
- Focus detection failure: assume unfocused → play notification (safe default)
