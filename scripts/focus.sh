#!/bin/bash
# Check if a terminal app is currently in the foreground.
# Returns: 0 = terminal focused (skip notify), 1 = not focused (notify!)
# Runs at notification time (not hook time), so powershell can check freely.
OS="$(uname -s)"

focus_windows() {
    powershell.exe -NoProfile -WindowStyle Hidden -Command "
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
        \$terms = @('WindowsTerminal','mintty','conhost','wezterm','alacritty','pwsh','powershell')
        \$p = Get-Process -Id \$fpid -EA SilentlyContinue
        while (\$p) {
            if (\$terms -contains \$p.ProcessName) { exit 0 }
            try { \$ppid = (Get-CimInstance Win32_Process -Filter \"ProcessId=\$(\$p.Id)\" -EA Stop).ParentProcessId }
            catch { break }
            if (-not \$ppid -or \$ppid -eq \$p.Id) { break }
            \$p = Get-Process -Id \$ppid -EA SilentlyContinue
        }
        exit 1
    " 2>/dev/null
    return $?
}

focus_macos() {
    local frontmost
    frontmost=$(osascript -e \
        'tell application "System Events" to get name of first process whose frontmost is true' \
        2>/dev/null) || return 1
    local TERMINAL_APPS="Terminal iTerm2 Warp Alacritty kitty Hyper WezTerm"
    for app in $TERMINAL_APPS; do
        [ "$frontmost" = "$app" ] && return 0
    done
    return 1
}

focus_linux() {
    command -v xdotool >/dev/null 2>&1 || return 1
    local wid
    wid=$(xdotool getactivewindow 2>/dev/null) || return 1
    local class
    class=$(xprop -id "$wid" WM_CLASS 2>/dev/null | grep -oi '"[^"]*"' | tr -d '"' | tr '[:upper:]' '[:lower:]')
    local TERMS="gnome-terminal konsole xterm xfce4-terminal tilix alacritty kitty wezterm bash zsh"
    for t in $TERMS; do
        echo "$class" | grep -q "$t" && return 0
    done
    return 1
}

case "$OS" in
    Darwin)               focus_macos ;;
    MINGW*|MSYS*|CYGWIN*) focus_windows ;;
    Linux)                focus_linux ;;
    *)                    exit 1 ;;
esac
