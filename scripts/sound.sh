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
    SOUND_FILE="$f" powershell.exe -NoProfile -Command "
        Add-Type -TypeDefinition '
using System;
using System.Runtime.InteropServices;
public class WinMM {
    [DllImport(\"winmm.dll\")] public static extern bool PlaySound(string f, IntPtr h, uint flags);
    public const uint SND_FILENAME = 0x20000;
    public const uint SND_SYNC    = 0x0;
    public const uint SND_NODEFAULT = 0x2;
}
'
        Start-Sleep -Milliseconds 200
        [WinMM]::PlaySound(\$env:SOUND_FILE, [IntPtr]::Zero, [WinMM]::SND_FILENAME -bor [WinMM]::SND_SYNC -bor [WinMM]::SND_NODEFAULT) | Out-Null
    " 2>/dev/null
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
