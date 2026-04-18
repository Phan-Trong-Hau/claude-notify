# claude-notify

Audio + OS notification for [Claude Code](https://claude.ai/code) — notifies you when Claude stops and your terminal is not in focus.

## What it does

- **Stop** — when Claude finishes a response, checks if your terminal is focused. If not, plays a sound and shows an OS toast notification.
- **PermissionRequest** — same behavior when Claude needs you to approve a tool use.
- **Smart suppression** — no notification if you're actively in the terminal, or if you already typed a new prompt.

## Install

```bash
claude plugin marketplace add Phan-Trong-Hau/claude-plugins
claude plugin install claude-notify@Phan-Trong-Hau
```

## Config

Add a `"claude-notify"` key to `~/.claude/settings.json`:

```json
{
  "claude-notify": {
    "enabled": true,
    "delay": 0,
    "mode": "sound",
    "volume": 1.0,
    "notify_os": true,
    "sound_file": "sounds/mixkit-negative-tone-interface-tap-2569.wav",
    "messages": {
      "stop": "Claude is waiting for your input",
      "permission": "Claude needs your approval"
    }
  }
}
```

Only include keys you want to override — the rest use plugin defaults.

### Options

| Key | Default | Description |
|-----|---------|-------------|
| `enabled` | `true` | Enable/disable all notifications |
| `delay` | `0` | Seconds to wait before checking focus and notifying |
| `mode` | `"sound"` | `"sound"`, `"beep"`, `"tts"`, or `"all"` |
| `volume` | `1.0` | Playback volume (0–1) |
| `notify_os` | `true` | Show OS toast notification (set `false` to disable) |
| `sound_file` | bundled wav | Path to custom sound file (relative to plugin root) |

### Notification modes

| `mode` | Beep | Audio file | TTS voice |
|--------|------|-----------|-----------|
| `"all"` | ✅ | ✅ | ✅ |
| `"sound"` (default) | ❌ | ✅ | ❌ |
| `"beep"` | ✅ | ❌ | ❌ |
| `"tts"` | ❌ | ❌ | ✅ |

## Custom sounds

Drop a `.wav` file anywhere and point `sound_file` to it (relative to plugin root).

**Tip:** If your sound is cut off at the beginning, prepend 1–2 seconds of silence. Windows needs a moment to wake the audio device on first playback.

```python
import wave

src = "your-sound.wav"
SILENCE_SEC = 2

with wave.open(src, 'rb') as r:
    params = r.getparams()
    frames = r.readframes(r.getnframes())

silence = b'\x00' * int(params.framerate * SILENCE_SEC) * params.nchannels * params.sampwidth

with wave.open(src, 'wb') as w:
    w.setparams(params)
    w.writeframes(silence + frames)
```

## Platform support

| Platform | Beep | Audio | TTS | OS Toast | Focus detection |
|----------|------|-------|-----|----------|-----------------|
| Windows (Git Bash / MSYS2) | ✅ | ✅ WinMM | ✅ SAPI | ✅ WinRT | ✅ Win32 API |
| macOS | ✅ `osascript` | ✅ `afplay` | ✅ `say` | ✅ `osascript` | ✅ `osascript` |
| Linux (Ubuntu) | ✅ `printf \a` | ✅ `paplay` / `aplay` / `ffplay` | ✅ `espeak` | ✅ `notify-send` | ✅ `xdotool` |

> **Linux dependencies:** `notify-send` (libnotify), `xdotool`, and one of `paplay` / `aplay` / `ffplay` for audio.
> Install with: `sudo apt install libnotify-bin xdotool pulseaudio-utils`

## License

MIT
