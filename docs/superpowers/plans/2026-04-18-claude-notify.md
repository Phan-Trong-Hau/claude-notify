# claude-notify Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Claude Code plugin that plays sound notifications (beep + audio + TTS) only when the terminal is not in focus.

**Architecture:** Bash entry point (`notify.sh`) receives a hook event, checks terminal focus via OS-native methods, then dispatches to three independent notification scripts. Config is read by a Python helper that normalizes Windows/Unix paths.

**Tech Stack:** Bash, Python 3 (config reading), PowerShell (Windows audio/TTS/focus), osascript (macOS focus), afplay + say (macOS audio/TTS). Zero external dependencies.

---

## File Map

| File | Responsibility |
|------|---------------|
| `package.json` | npm-style plugin metadata |
| `.claude-plugin/plugin.json` | Claude Code plugin identity |
| `.claude-plugin/marketplace.json` | Self-referencing marketplace entry |
| `config.json` | Default user config (copy & edit to override) |
| `hooks/hooks.json` | Hook definitions — calls `notify.sh <event>` |
| `scripts/config.py` | Read scalar values from config.json, handles Windows path |
| `scripts/sysbeep.sh` | Native system beep (Windows/macOS) |
| `scripts/tts.sh` | Text-to-speech (Windows SAPI / macOS say) |
| `scripts/sound.sh` | Play audio file with volume (Windows MediaPlayer / macOS afplay) |
| `scripts/focus.sh` | Return 0 if terminal focused, 1 if not |
| `scripts/notify.sh` | Orchestrator: check config → focus → dispatch |
| `sounds/.gitkeep` | Placeholder; users drop custom .wav files here |
| `tests/run_tests.sh` | Run all tests |

---

## Task 1: Project Scaffold

**Files:**
- Create: `package.json`
- Create: `.claude-plugin/plugin.json`
- Create: `.claude-plugin/marketplace.json`
- Create: `config.json`
- Create: `sounds/.gitkeep`
- Create: `.gitignore`

- [ ] **Step 1: Init git repo and directories**

```bash
cd C:/Users/PC/Workspace/Project/claude-notify
git init
mkdir -p .claude-plugin hooks scripts sounds tests
```

- [ ] **Step 2: Create `package.json`**

```json
{
  "name": "claude-notify",
  "version": "1.0.0",
  "description": "Audio notifications for Claude Code — only when you're away from the terminal",
  "keywords": ["claude-code", "claude-code-plugin", "notifications", "audio", "hooks"],
  "license": "MIT",
  "repository": {
    "type": "git",
    "url": "https://github.com/OWNER/claude-notify.git"
  },
  "files": [
    ".claude-plugin/",
    "hooks/",
    "scripts/",
    "sounds/",
    "config.json",
    "README.md"
  ]
}
```

- [ ] **Step 3: Create `.claude-plugin/plugin.json`**

```json
{
  "name": "claude-notify",
  "version": "1.0.0",
  "description": "Audio notifications for Claude Code — only when you're away from the terminal",
  "author": {
    "name": "OWNER",
    "url": "https://github.com/OWNER"
  },
  "homepage": "https://github.com/OWNER/claude-notify",
  "repository": "https://github.com/OWNER/claude-notify",
  "license": "MIT"
}
```

- [ ] **Step 4: Create `.claude-plugin/marketplace.json`**

```json
{
  "name": "OWNER",
  "description": "Claude Code plugins by OWNER",
  "owner": {
    "name": "OWNER",
    "url": "https://github.com/OWNER"
  },
  "plugins": [
    {
      "name": "claude-notify",
      "description": "Audio notifications when Claude needs attention — only when you're away",
      "version": "1.0.0",
      "source": {
        "source": "url",
        "url": "https://github.com/OWNER/claude-notify.git"
      },
      "category": "productivity"
    }
  ]
}
```

- [ ] **Step 5: Create `config.json`**

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
    "stop": "Claude is waiting for your input",
    "permission": "Claude needs your approval",
    "notification": "Claude has a notification",
    "subagent": "Background task completed"
  },
  "terminal_apps": {
    "macos": ["Terminal", "iTerm2", "Warp", "Alacritty", "kitty", "Hyper", "WezTerm"],
    "windows": ["WindowsTerminal", "mintty", "conhost", "cmd", "powershell", "pwsh", "bash", "wezterm", "alacritty"]
  }
}
```

- [ ] **Step 6: Create `sounds/.gitkeep` and `.gitignore`**

```bash
touch sounds/.gitkeep
```

`.gitignore`:
```
sounds/*.wav
sounds/*.mp3
sounds/*.aiff
!sounds/.gitkeep
```

- [ ] **Step 7: Initial commit**

```bash
git add .
git commit -m "chore: scaffold claude-notify plugin structure"
```

---

## Task 2: Config Reader (`scripts/config.py`)

**Files:**
- Create: `scripts/config.py`
- Create: `tests/run_tests.sh`

- [ ] **Step 1: Create test file `tests/run_tests.sh`**

```bash
#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PASS=0; FAIL=0

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "PASS: $desc"
        PASS=$((PASS+1))
    else
        echo "FAIL: $desc — expected '$expected', got '$actual'"
        FAIL=$((FAIL+1))
    fi
}

echo "=== config.py tests ==="
CFG="$ROOT/config.json"
assert_eq "enabled is true"     "true"  "$(python3 "$ROOT/scripts/config.py" "$CFG" "enabled" "false")"
assert_eq "volume is 0.8"       "0.8"   "$(python3 "$ROOT/scripts/config.py" "$CFG" "volume" "0")"
assert_eq "sysbeep is true"     "true"  "$(python3 "$ROOT/scripts/config.py" "$CFG" "notify.sysbeep" "false")"
assert_eq "stop message"        "Claude is waiting for your input" \
          "$(python3 "$ROOT/scripts/config.py" "$CFG" "messages.stop" "")"
assert_eq "missing key default" "fallback" \
          "$(python3 "$ROOT/scripts/config.py" "$CFG" "nonexistent.key" "fallback")"
assert_eq "bad path default"    "fallback" \
          "$(python3 "$ROOT/scripts/config.py" "/nonexistent/path.json" "any.key" "fallback")"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ]
```

- [ ] **Step 2: Run tests — verify they fail**

```bash
bash tests/run_tests.sh
```

Expected: FAIL on all config.py tests (script doesn't exist yet)

- [ ] **Step 3: Create `scripts/config.py`**

```python
#!/usr/bin/env python3
"""Read a scalar value from config.json by dot-notation key.
Usage: config.py <config_path> <key> [default]
Example: config.py /path/config.json notify.sysbeep true
"""
import json, sys, os

def resolve_path(path):
    """Convert Unix-style /c/Users/... to C:/Users/... on Windows."""
    if os.path.exists(path):
        return path
    if path.startswith('/') and len(path) > 2 and path[2] == '/':
        drive = path[1].upper()
        rest = path[3:]
        win_path = drive + ':/' + rest
        if os.path.exists(win_path):
            return win_path
    return path

def main():
    if len(sys.argv) < 3:
        print("")
        return

    config_path = resolve_path(sys.argv[1])
    key = sys.argv[2]
    default = sys.argv[3] if len(sys.argv) > 3 else ""

    try:
        with open(config_path) as f:
            c = json.load(f)
        val = c
        for k in key.split('.'):
            val = val[k]
        print(str(val).lower() if isinstance(val, bool) else str(val))
    except Exception:
        print(default)

main()
```

- [ ] **Step 4: Run tests — verify they pass**

```bash
bash tests/run_tests.sh
```

Expected output:
```
=== config.py tests ===
PASS: enabled is true
PASS: volume is 0.8
PASS: sysbeep is true
PASS: stop message
PASS: missing key default
PASS: bad path default

Results: 6 passed, 0 failed
```

- [ ] **Step 5: Commit**

```bash
git add scripts/config.py tests/run_tests.sh
git commit -m "feat: add config reader with Windows path normalization"
```

---

## Task 3: System Beep (`scripts/sysbeep.sh`)

**Files:**
- Create: `scripts/sysbeep.sh`
- Modify: `tests/run_tests.sh`

- [ ] **Step 1: Add beep test to `tests/run_tests.sh`**

Append after the config tests block (before the final echo/exit):

```bash
echo ""
echo "=== sysbeep.sh tests ==="
bash "$ROOT/scripts/sysbeep.sh" 2>/dev/null
assert_eq "sysbeep exits 0" "0" "$?"
```

- [ ] **Step 2: Run — verify test fails**

```bash
bash tests/run_tests.sh
```

Expected: FAIL on sysbeep test (script doesn't exist)

- [ ] **Step 3: Create `scripts/sysbeep.sh`**

```bash
#!/bin/bash
# Play a native system beep. Exits 0 always.
OS="$(uname -s)"

case "$OS" in
    Darwin)
        osascript -e 'beep' 2>/dev/null || true
        ;;
    MINGW*|MSYS*|CYGWIN*)
        powershell.exe -NoProfile -Command '[console]::beep(800,300)' 2>/dev/null || true
        ;;
    *)
        # Fallback: terminal bell
        printf '\a' 2>/dev/null || true
        ;;
esac

exit 0
```

```bash
chmod +x scripts/sysbeep.sh
```

- [ ] **Step 4: Run tests — verify pass**

```bash
bash tests/run_tests.sh
```

Expected: all previous tests pass + `PASS: sysbeep exits 0`. You should also hear a beep.

- [ ] **Step 5: Commit**

```bash
git add scripts/sysbeep.sh tests/run_tests.sh
git commit -m "feat: add sysbeep script (Windows/macOS/fallback)"
```

---

## Task 4: Text-to-Speech (`scripts/tts.sh`)

**Files:**
- Create: `scripts/tts.sh`
- Modify: `tests/run_tests.sh`

- [ ] **Step 1: Add TTS test to `tests/run_tests.sh`**

Append before the final `echo Results` lines:

```bash
echo ""
echo "=== tts.sh tests ==="
bash "$ROOT/scripts/tts.sh" "Test notification" "0.5" 2>/dev/null
assert_eq "tts exits 0" "0" "$?"
bash "$ROOT/scripts/tts.sh" "" "0.5" 2>/dev/null
assert_eq "tts empty message exits 0" "0" "$?"
```

- [ ] **Step 2: Run — verify tests fail**

```bash
bash tests/run_tests.sh
```

Expected: FAIL on tts tests

- [ ] **Step 3: Create `scripts/tts.sh`**

```bash
#!/bin/bash
# Speak a message. Usage: tts.sh <message> <volume 0-1>
# Exits 0 always.
MESSAGE="${1:-}"
VOLUME="${2:-0.8}"
OS="$(uname -s)"

[ -z "$MESSAGE" ] && exit 0

case "$OS" in
    Darwin)
        # volume flag not available in say; use osascript for volume control
        VOL_PCT=$(python3 -c "print(int(float('$VOLUME') * 100))" 2>/dev/null || echo "80")
        osascript -e "set volume output volume $VOL_PCT" 2>/dev/null || true
        say "$MESSAGE" 2>/dev/null || true
        ;;
    MINGW*|MSYS*|CYGWIN*)
        VOL_INT=$(python3 -c "print(int(float('$VOLUME') * 100))" 2>/dev/null || echo "80")
        powershell.exe -NoProfile -Command "
            Add-Type -AssemblyName System.Speech
            \$s = New-Object System.Speech.Synthesis.SpeechSynthesizer
            \$s.Volume = $VOL_INT
            \$s.Speak('$MESSAGE')
        " 2>/dev/null || true
        ;;
    *)
        # Fallback: try espeak if available
        command -v espeak >/dev/null 2>&1 && espeak "$MESSAGE" 2>/dev/null || true
        ;;
esac

exit 0
```

```bash
chmod +x scripts/tts.sh
```

- [ ] **Step 4: Run tests — verify pass + hear voice**

```bash
bash tests/run_tests.sh
```

Expected: `PASS: tts exits 0`, `PASS: tts empty message exits 0`. You should hear "Test notification" spoken aloud.

- [ ] **Step 5: Commit**

```bash
git add scripts/tts.sh tests/run_tests.sh
git commit -m "feat: add TTS script (Windows SAPI / macOS say)"
```

---

## Task 5: Audio File Playback (`scripts/sound.sh`)

**Files:**
- Create: `scripts/sound.sh`
- Modify: `tests/run_tests.sh`

- [ ] **Step 1: Add sound tests to `tests/run_tests.sh`**

Append before final echo/exit:

```bash
echo ""
echo "=== sound.sh tests ==="
# Test with nonexistent file — must fall back silently
bash "$ROOT/scripts/sound.sh" "/nonexistent/file.wav" "0.5" 2>/dev/null
assert_eq "sound nonexistent file exits 0" "0" "$?"
# Test with OS system sound
bash "$ROOT/scripts/sound.sh" "" "0.5" 2>/dev/null
assert_eq "sound empty path uses fallback, exits 0" "0" "$?"
```

- [ ] **Step 2: Run — verify tests fail**

```bash
bash tests/run_tests.sh
```

- [ ] **Step 3: Create `scripts/sound.sh`**

```bash
#!/bin/bash
# Play an audio file. Falls back to OS system sound if file missing.
# Usage: sound.sh <file_path> <volume 0-1>
# Exits 0 always.
FILE="${1:-}"
VOLUME="${2:-0.8}"
OS="$(uname -s)"

play_windows() {
    local f="$1" vol="$2"
    # Normalize Unix path to Windows path
    if [[ "$f" == /[a-zA-Z]/* ]]; then
        f="$(echo "$f" | sed 's|^/\([a-zA-Z]\)/|\1:/|')"
    fi
    [ ! -f "$f" ] && f="C:/Windows/Media/Windows Notify System Generic.wav"
    [ ! -f "$f" ] && f="C:/Windows/Media/chimes.wav"
    [ ! -f "$f" ] && return 0
    powershell.exe -NoProfile -Command "
        Add-Type -AssemblyName PresentationCore
        \$p = New-Object System.Windows.Media.MediaPlayer
        \$p.Volume = $vol
        \$p.Open([Uri]::new('$f'))
        \$p.Play()
        Start-Sleep -Milliseconds 3000
    " 2>/dev/null &
}

play_macos() {
    local f="$1" vol="$2"
    [ ! -f "$f" ] && f="/System/Library/Sounds/Glass.aiff"
    [ ! -f "$f" ] && return 0
    afplay -v "$vol" "$f" 2>/dev/null &
}

case "$OS" in
    Darwin)      play_macos "$FILE" "$VOLUME" ;;
    MINGW*|MSYS*|CYGWIN*) play_windows "$FILE" "$VOLUME" ;;
    *) true ;;
esac

exit 0
```

```bash
chmod +x scripts/sound.sh
```

- [ ] **Step 4: Run tests — verify pass**

```bash
bash tests/run_tests.sh
```

Expected: `PASS: sound nonexistent file exits 0`, `PASS: sound empty path uses fallback, exits 0`. You should hear a Windows/macOS system sound.

- [ ] **Step 5: Commit**

```bash
git add scripts/sound.sh tests/run_tests.sh
git commit -m "feat: add audio playback script with system sound fallback"
```

---

## Task 6: Focus Detection (`scripts/focus.sh`)

**Files:**
- Create: `scripts/focus.sh`
- Modify: `tests/run_tests.sh`

- [ ] **Step 1: Add focus test to `tests/run_tests.sh`**

Append before final echo/exit:

```bash
echo ""
echo "=== focus.sh tests ==="
# When running tests from terminal, terminal SHOULD be focused → exit 0
bash "$ROOT/scripts/focus.sh"
assert_eq "terminal is focused when running tests" "0" "$?"
```

- [ ] **Step 2: Run — verify test fails**

```bash
bash tests/run_tests.sh
```

- [ ] **Step 3: Create `scripts/focus.sh`**

```bash
#!/bin/bash
# Detect if a terminal is the focused window.
# Returns: 0 = terminal focused (skip notify), 1 = not focused (notify!)
OS="$(uname -s)"

TERMINAL_APPS_WINDOWS="WindowsTerminal mintty conhost cmd powershell pwsh bash wezterm alacritty"
TERMINAL_APPS_MACOS="Terminal iTerm2 Warp Alacritty kitty Hyper WezTerm"

focus_windows() {
    # Build PowerShell array string
    local arr
    arr=$(echo "$TERMINAL_APPS_WINDOWS" | tr ' ' '\n' | \
          sed "s/\(.*\)/'\1'/" | paste -sd ',' -)

    powershell.exe -NoProfile -Command "
        Add-Type -TypeDefinition '
using System;
using System.Runtime.InteropServices;
public class WF {
    [DllImport(\"user32.dll\")] public static extern IntPtr GetForegroundWindow();
    [DllImport(\"user32.dll\")] public static extern int GetWindowThreadProcessId(IntPtr h, out int pid);
}
'
        \$hwnd = [WF]::GetForegroundWindow()
        \$fpid = 0
        [WF]::GetWindowThreadProcessId(\$hwnd, [ref]\$fpid) | Out-Null
        \$terms = @($arr)
        \$p = Get-Process -Id \$fpid -ErrorAction SilentlyContinue
        while (\$p) {
            if (\$terms -contains \$p.ProcessName) { exit 0 }
            try {
                \$ppid = (Get-CimInstance Win32_Process -Filter \"ProcessId=\$(\$p.Id)\" -EA Stop).ParentProcessId
            } catch { break }
            if (-not \$ppid -or \$ppid -eq \$p.Id) { break }
            \$p = Get-Process -Id \$ppid -ErrorAction SilentlyContinue
        }
        exit 1
    " 2>/dev/null
    return $?
}

focus_macos() {
    local frontmost
    frontmost=$(osascript -e \
        'tell application "System Events" to get name of first process whose frontmost is true' \
        2>/dev/null) || return 1  # osascript failed → assume not focused

    for app in $TERMINAL_APPS_MACOS; do
        [ "$frontmost" = "$app" ] && return 0
    done
    return 1
}

case "$OS" in
    Darwin)               focus_macos ;;
    MINGW*|MSYS*|CYGWIN*) focus_windows ;;
    *)                    exit 1 ;;  # unknown OS → assume not focused
esac
```

```bash
chmod +x scripts/focus.sh
```

- [ ] **Step 4: Run tests — verify pass**

```bash
bash tests/run_tests.sh
```

Expected: `PASS: terminal is focused when running tests` (since your terminal is focused).

- [ ] **Step 5: Commit**

```bash
git add scripts/focus.sh tests/run_tests.sh
git commit -m "feat: add focus detection (Windows Win32 / macOS osascript)"
```

---

## Task 7: Orchestrator (`scripts/notify.sh`)

**Files:**
- Create: `scripts/notify.sh`
- Modify: `tests/run_tests.sh`

- [ ] **Step 1: Add orchestrator tests to `tests/run_tests.sh`**

Append before final echo/exit:

```bash
echo ""
echo "=== notify.sh tests ==="
# notify.sh with valid event exits 0
bash "$ROOT/scripts/notify.sh" "stop" 2>/dev/null
assert_eq "notify stop exits 0" "0" "$?"
# notify.sh with unknown event exits 0 (no crash)
bash "$ROOT/scripts/notify.sh" "unknown_event" 2>/dev/null
assert_eq "notify unknown event exits 0" "0" "$?"
# notify.sh with no args exits 0
bash "$ROOT/scripts/notify.sh" 2>/dev/null
assert_eq "notify no args exits 0" "0" "$?"
```

- [ ] **Step 2: Run — verify tests fail**

```bash
bash tests/run_tests.sh
```

- [ ] **Step 3: Create `scripts/notify.sh`**

```bash
#!/bin/bash
# Main notification entry point called by Claude Code hooks.
# Usage: notify.sh <event>
# Events: stop | permission | notification | subagent
# Exits 0 always — must never block Claude.
EVENT="${1:-stop}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OS="$(uname -s)"

# Normalize ROOT to Windows path so Python can open config.json
if [[ "$OS" == MINGW* || "$OS" == MSYS* || "$OS" == CYGWIN* ]]; then
    ROOT="$(echo "$ROOT" | sed 's|^/\([a-zA-Z]\)/|\1:/|')"
fi
CONFIG="$ROOT/config.json"

# Read config
PY="$SCRIPT_DIR/config.py"
ENABLED=$(python3 "$PY" "$CONFIG" "enabled" "true")
[ "$ENABLED" = "false" ] && exit 0

# Check focus: exit 0 = terminal focused → skip
bash "$SCRIPT_DIR/focus.sh" && exit 0

# Read notification settings
VOLUME=$(python3    "$PY" "$CONFIG" "volume"           "0.8")
DO_BEEP=$(python3  "$PY" "$CONFIG" "notify.sysbeep"   "true")
DO_SOUND=$(python3 "$PY" "$CONFIG" "notify.sound"     "true")
DO_TTS=$(python3   "$PY" "$CONFIG" "notify.tts"       "true")
MSG=$(python3      "$PY" "$CONFIG" "messages.$EVENT"  "Claude needs your attention")

# Map event to sound file
SOUND_FILE="$ROOT/sounds/$EVENT.wav"
[ ! -f "$SOUND_FILE" ] && SOUND_FILE=""

# Fire notifications (each script exits 0 on any failure)
[ "$DO_BEEP"  = "true" ] && bash "$SCRIPT_DIR/sysbeep.sh"               2>/dev/null || true
[ "$DO_SOUND" = "true" ] && bash "$SCRIPT_DIR/sound.sh" "$SOUND_FILE" "$VOLUME" 2>/dev/null || true
[ "$DO_TTS"   = "true" ] && bash "$SCRIPT_DIR/tts.sh"  "$MSG"         "$VOLUME" 2>/dev/null || true

exit 0
```

```bash
chmod +x scripts/notify.sh
```

- [ ] **Step 4: Run tests — verify pass**

```bash
bash tests/run_tests.sh
```

Expected: all 3 notify tests pass. Because your terminal IS focused during testing, no sound plays (correct behavior).

- [ ] **Step 5: Verify unfocused behavior manually**

Switch to another app (browser, file explorer), then run:

```bash
bash scripts/notify.sh stop
```

Expected: hear beep + system sound + TTS "Claude is waiting for your input".

- [ ] **Step 6: Commit**

```bash
git add scripts/notify.sh tests/run_tests.sh
git commit -m "feat: add notify orchestrator with focus-gated notifications"
```

---

## Task 8: Hooks Definition

**Files:**
- Create: `hooks/hooks.json`

- [ ] **Step 1: Create `hooks/hooks.json`**

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${CLAUDE_PLUGIN_ROOT}/scripts/notify.sh\" stop",
            "async": true
          }
        ]
      }
    ],
    "PermissionRequest": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${CLAUDE_PLUGIN_ROOT}/scripts/notify.sh\" permission",
            "async": true
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${CLAUDE_PLUGIN_ROOT}/scripts/notify.sh\" notification",
            "async": true
          }
        ]
      }
    ],
    "SubagentStop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${CLAUDE_PLUGIN_ROOT}/scripts/notify.sh\" subagent",
            "async": true
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: Validate JSON**

```bash
python3 -c "import json; json.load(open('hooks/hooks.json')); print('OK')"
```

Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add hooks/hooks.json
git commit -m "feat: add hook definitions for Stop, PermissionRequest, Notification, SubagentStop"
```

---

## Task 9: README

**Files:**
- Create: `README.md`

- [ ] **Step 1: Create `README.md`**

````markdown
# claude-notify

Audio notifications for [Claude Code](https://claude.ai/code) — plays sound only when you're away from the terminal.

## What it does

Hooks into Claude Code events and plays 3 layers of notification when the agent needs your attention:

1. **System beep** — native OS beep
2. **Audio file** — plays `sounds/<event>.wav` or falls back to OS system sound
3. **TTS voice** — speaks the notification message

Notifications are **skipped when your terminal is in focus** — no annoying sounds while you're watching Claude work.

## Events

| Event | Default message |
|-------|----------------|
| Agent stopped (`Stop`) | "Claude is waiting for your input" |
| Permission needed (`PermissionRequest`) | "Claude needs your approval" |
| Notification push (`Notification`) | "Claude has a notification" |
| Background task done (`SubagentStop`) | "Background task completed" |

## Install

Add to `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "OWNER": {
      "source": { "source": "github", "repo": "OWNER/claude-notify" }
    }
  },
  "enabledPlugins": {
    "claude-notify@OWNER": true
  }
}
```

Then restart Claude Code. Or use the `/plugins` menu.

## Config

Edit `~/.claude/plugins/cache/OWNER/claude-notify/1.0.0/config.json`:

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
    "stop": "Claude is waiting for your input",
    "permission": "Claude needs your approval",
    "notification": "Claude has a notification",
    "subagent": "Background task completed"
  }
}
```

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
````

- [ ] **Step 2: Replace all `OWNER` placeholders**

Before publishing, replace every occurrence of `OWNER` in all files with your actual GitHub username:

```bash
grep -r "OWNER" . --include="*.json" --include="*.md" -l
```

Update each file found.

- [ ] **Step 3: Final commit**

```bash
git add README.md
git commit -m "docs: add README with install and config instructions"
```

---

## Task 10: Final Verification

- [ ] **Step 1: Run full test suite**

```bash
bash tests/run_tests.sh
```

Expected: all tests pass, `0 failed`.

- [ ] **Step 2: Verify hooks.json is valid and wired correctly**

```bash
python3 -c "
import json
h = json.load(open('hooks/hooks.json'))
events = list(h['hooks'].keys())
print('Hooks registered:', events)
for e, entries in h['hooks'].items():
    cmd = entries[0]['hooks'][0]['command']
    print(f'  {e}: {cmd}')
"
```

Expected:
```
Hooks registered: ['Stop', 'PermissionRequest', 'Notification', 'SubagentStop']
  Stop: bash "${CLAUDE_PLUGIN_ROOT}/scripts/notify.sh" stop
  ...
```

- [ ] **Step 3: Live test — unfocused scenario**

Open a different app (browser, file explorer). From another terminal or via Claude Code's `/run`:

```bash
bash /path/to/claude-notify/scripts/notify.sh stop
```

Expected: beep + system sound + TTS voice heard.

- [ ] **Step 4: Tag release**

```bash
git tag v1.0.0
```

- [ ] **Step 5: Push to GitHub**

Create repo at `github.com/OWNER/claude-notify`, then:

```bash
git remote add origin https://github.com/OWNER/claude-notify.git
git push -u origin main --tags
```
