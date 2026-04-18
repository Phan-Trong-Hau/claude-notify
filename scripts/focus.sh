#!/bin/bash
# Detect if a terminal is the focused window.
# Returns: 0 = terminal focused (skip notify), 1 = not focused (notify!)
OS="$(uname -s)"

TERMINAL_APPS_MACOS="Terminal iTerm2 Warp Alacritty kitty Hyper WezTerm"

focus_windows() {
    # Compare our tab's console window handle to the foreground window.
    # This correctly handles multi-tab terminals (e.g. Windows Terminal)
    # where all tabs share the same process but each has its own console window.
    powershell.exe -NoProfile -Command "
        Add-Type -TypeDefinition '
using System;
using System.Runtime.InteropServices;
public class WF {
    [DllImport(\"user32.dll\")] public static extern IntPtr GetForegroundWindow();
    [DllImport(\"kernel32.dll\")] public static extern IntPtr GetConsoleWindow();
}
'
        \$fg  = [WF]::GetForegroundWindow()
        \$con = [WF]::GetConsoleWindow()
        if (\$con -ne [IntPtr]::Zero -and \$con -eq \$fg) { exit 0 } else { exit 1 }
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
