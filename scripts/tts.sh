#!/bin/bash
# Speak a message. Usage: tts.sh <message> <volume 0-1>
# Exits 0 always.
MESSAGE="${1:-}"
VOLUME="${2:-0.8}"
OS="$(uname -s)"

[ -z "$MESSAGE" ] && exit 0

case "$OS" in
    Darwin)
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
        command -v espeak >/dev/null 2>&1 && espeak "$MESSAGE" 2>/dev/null || true
        ;;
esac

exit 0
