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
