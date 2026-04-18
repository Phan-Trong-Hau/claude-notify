#!/bin/bash
# Play an audio file. Falls back to OS system sound if file missing.
# Usage: sound.sh <file_path> <volume 0-1>
# Exits 0 always.
FILE="${1:-}"
VOLUME="${2:-0.8}"
OS="$(uname -s)"

play_windows() {
    local f="$1" vol="$2"
    if [[ "$f" == /[a-zA-Z]/* ]]; then
        f="$(echo "$f" | sed 's|^/\([a-zA-Z]\)/|\1:/|')"
    fi
    [ ! -f "$f" ] && f="C:/Windows/Media/Windows Notify System Generic.wav"
    [ ! -f "$f" ] && f="C:/Windows/Media/chimes.wav"
    [ ! -f "$f" ] && return 0
    SOUND_FILE="$f" SOUND_VOL="$vol" powershell.exe -NoProfile -Command "
        Add-Type -AssemblyName PresentationCore
        \$p = New-Object System.Windows.Media.MediaPlayer
        \$p.Volume = [double]\$env:SOUND_VOL
        \$p.Open([Uri]::new(\$env:SOUND_FILE))
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
    Darwin)               play_macos "$FILE" "$VOLUME" ;;
    MINGW*|MSYS*|CYGWIN*) play_windows "$FILE" "$VOLUME" ;;
    *) true ;;
esac

exit 0
