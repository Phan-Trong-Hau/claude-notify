#!/bin/bash
# Detect if a terminal is the focused window.
# Returns: 0 = terminal focused (skip notify), 1 = not focused (notify!)
OS="$(uname -s)"

TERMINAL_APPS_MACOS="Terminal iTerm2 Warp Alacritty kitty Hyper WezTerm"

focus_windows() {
    # Write a unique marker to our tab's title, then read the foreground window's
    # title to check if it matches. This correctly handles multi-tab terminals
    # (e.g. Windows Terminal) where all tabs share the same process but each tab
    # has its own title reflected in the taskbar window title when active.
    printf '\033]0;__claude_active__\007'
    sleep 0.05  # let the terminal process the escape sequence

    powershell.exe -NoProfile -Command "
        Add-Type -TypeDefinition '
using System;
using System.Runtime.InteropServices;
using System.Text;
public class WF {
    [DllImport(\"user32.dll\")] public static extern IntPtr GetForegroundWindow();
    [DllImport(\"user32.dll\")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
}
'
        \$hwnd = [WF]::GetForegroundWindow()
        \$sb   = New-Object System.Text.StringBuilder 512
        [WF]::GetWindowText(\$hwnd, \$sb, 512) | Out-Null
        if (\$sb.ToString() -like '*__claude_active__*') { exit 0 } else { exit 1 }
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
