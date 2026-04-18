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
