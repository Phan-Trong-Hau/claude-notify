#!/bin/bash
# Main notification entry point called by Claude Code hooks.
# Usage: notify.sh <event>
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

DELAY=$(python3   "$PY" "$CONFIG" "delay"             "60")
VOLUME=$(python3  "$PY" "$CONFIG" "volume"            "0.8")
MODE=$(python3    "$PY" "$CONFIG" "mode"              "sound")
MSG=$(python3     "$PY" "$CONFIG" "messages.$EVENT"   "Claude needs your attention")

# Resolve which layers to fire
case "$MODE" in
  beep)  DO_BEEP=true;  DO_SOUND=false; DO_TTS=false ;;
  sound) DO_BEEP=false; DO_SOUND=true;  DO_TTS=false ;;
  tts)   DO_BEEP=false; DO_SOUND=false; DO_TTS=true  ;;
  *)     DO_BEEP=true;  DO_SOUND=true;  DO_TTS=true  ;;
esac

# Resolve sound file
SOUND_FILE_CFG=$(python3 "$PY" "$CONFIG" "sound_file" "")
if [ -n "$SOUND_FILE_CFG" ]; then
    SOUND_FILE="$ROOT/$SOUND_FILE_CFG"
else
    SOUND_FILE="$ROOT/sounds/$EVENT.wav"
fi
[ ! -f "$SOUND_FILE" ] && SOUND_FILE=""

# Record stop time, then wait DELAY seconds before notifying.
# If user submits a prompt before delay expires, active.sh updates the
# active timestamp and we skip the notification.
STAMP_DIR="${TMPDIR:-/tmp}"
SESSION="${CLAUDE_SESSION_ID:-default}"
STOP_STAMP="$STAMP_DIR/claude-notify-stop-$SESSION"
ACTIVE_STAMP="$STAMP_DIR/claude-notify-active-$SESSION"

date +%s > "$STOP_STAMP"

# Export vars so the detached subshell can access them
export DELAY STOP_STAMP ACTIVE_STAMP DO_BEEP DO_SOUND DO_TTS SOUND_FILE VOLUME MSG SCRIPT_DIR

# nohup detaches the process from Claude Code's process group so the
# sleep timer doesn't show up in Claude's "running hook" status.
nohup bash -c '
  sleep "$DELAY"
  STOP_TIME=$(cat "$STOP_STAMP" 2>/dev/null || echo 0)
  ACTIVE_TIME=$(cat "$ACTIVE_STAMP" 2>/dev/null || echo 0)
  [ "$ACTIVE_TIME" -gt "$STOP_TIME" ] && exit 0
  [ "$DO_BEEP"  = "true" ] && bash "$SCRIPT_DIR/sysbeep.sh"                        2>/dev/null || true
  [ "$DO_SOUND" = "true" ] && bash "$SCRIPT_DIR/sound.sh" "$SOUND_FILE" "$VOLUME"  2>/dev/null || true
  [ "$DO_TTS"   = "true" ] && bash "$SCRIPT_DIR/tts.sh"   "$MSG"        "$VOLUME"  2>/dev/null || true
' > /dev/null 2>&1 &

exit 0
