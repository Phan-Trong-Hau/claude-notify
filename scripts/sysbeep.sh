#!/bin/bash
# Play a native system beep. Exits 0 always.
OS="$(uname -s)"

case "$OS" in
    Darwin)
        osascript -e 'beep' 2>/dev/null || true
        ;;
    MINGW*|MSYS*|CYGWIN*)
        powershell.exe -NoProfile -Command '[System.Media.SystemSounds]::Beep.Play(); Start-Sleep -Milliseconds 500' 2>/dev/null || true
        ;;
    *)
        printf '\a' 2>/dev/null || true
        ;;
esac

exit 0
