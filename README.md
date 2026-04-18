# claude-notify

Audio notification for [Claude Code](https://claude.ai/code) — plays sound after Claude finishes and you haven't returned within a configurable delay.

## What it does

When Claude stops, starts a timer. If you haven't typed anything before the timer expires, it plays a sound to let you know Claude is waiting.

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
    "delay": 60,
    "mode": "sound",
    "volume": 0.8,
    "sound_file": "sounds/mixkit-negative-tone-interface-tap-2569.wav",
    "messages": {
      "stop": "Claude is waiting for your input"
    }
  }
}
```

Only include keys you want to override — the rest use plugin defaults.

### Options

| Key | Default | Description |
|-----|---------|-------------|
| `enabled` | `true` | Enable/disable notifications |
| `delay` | `60` | Seconds to wait before notifying (e.g. `120` = 2 minutes) |
| `mode` | `"sound"` | `"sound"`, `"beep"`, `"tts"`, or `"all"` |
| `volume` | `0.8` | Playback volume (0–1) |
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

**Tip:** If your sound file is very short (< 1 second), prepend ~300ms–2s of silence to the beginning. Windows needs a moment to wake the audio device, and without leading silence the first part of the sound may be cut off.

```python
import wave
SILENCE_MS = 500
src = "your-sound.wav"
with wave.open(src, 'rb') as r:
    params = r.getparams()
    frames = r.readframes(r.getnframes())
silence = b'\x00' * int(params.framerate * SILENCE_MS / 1000) * params.nchannels * params.sampwidth
with wave.open(src, 'wb') as w:
    w.setparams(params)
    w.writeframes(silence + frames)
```

## Platform support

| Platform | Beep | Audio | TTS |
|----------|------|-------|-----|
| Windows (Git Bash / MSYS2) | ✅ | ✅ WinMM | ✅ SAPI |
| macOS | ✅ `osascript` | ✅ `afplay` | ✅ `say` |

## License

MIT
