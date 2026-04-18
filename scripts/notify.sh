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

# Read notification settings
VOLUME=$(python3 "$PY" "$CONFIG" "volume"          "0.8")
MODE=$(python3   "$PY" "$CONFIG" "mode"            "all")
MSG=$(python3    "$PY" "$CONFIG" "messages.$EVENT" "Claude needs your attention")

# Resolve which layers to fire based on mode: all | beep | sound | tts
case "$MODE" in
  beep)  DO_BEEP=true;  DO_SOUND=false; DO_TTS=false ;;
  sound) DO_BEEP=false; DO_SOUND=true;  DO_TTS=false ;;
  tts)   DO_BEEP=false; DO_SOUND=false; DO_TTS=true  ;;
  *)     DO_BEEP=true;  DO_SOUND=true;  DO_TTS=true  ;;  # all (default)
esac

# Resolve sound file: use sound_file override if set, else event-based lookup
SOUND_FILE_CFG=$(python3 "$PY" "$CONFIG" "sound_file" "")
if [ -n "$SOUND_FILE_CFG" ]; then
    SOUND_FILE="$ROOT/$SOUND_FILE_CFG"
else
    SOUND_FILE="$ROOT/sounds/$EVENT.wav"
fi
[ ! -f "$SOUND_FILE" ] && SOUND_FILE=""

# Fire notifications in background so the hook returns immediately
(
  [ "$DO_BEEP"  = "true" ] && bash "$SCRIPT_DIR/sysbeep.sh"                        2>/dev/null || true
  [ "$DO_SOUND" = "true" ] && bash "$SCRIPT_DIR/sound.sh" "$SOUND_FILE" "$VOLUME"  2>/dev/null || true
  [ "$DO_TTS"   = "true" ] && bash "$SCRIPT_DIR/tts.sh"   "$MSG"        "$VOLUME"  2>/dev/null || true
) &

exit 0
