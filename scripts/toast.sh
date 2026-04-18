#!/bin/bash
# Send a native OS toast notification.
# Usage: toast.sh <title> <message>
TITLE="${1:-Claude}"
MSG="${2:-Claude needs your attention}"
OS="$(uname -s)"

toast_windows() {
    powershell.exe -NoProfile -WindowStyle Hidden -Command "
        \$title = '$TITLE'
        \$msg   = '$MSG'
        Add-Type -AssemblyName System.Windows.Forms
        \$n = New-Object System.Windows.Forms.NotifyIcon
        \$n.Icon = [System.Drawing.SystemIcons]::Information
        \$n.Visible = \$true
        \$n.ShowBalloonTip(5000, \$title, \$msg, [System.Windows.Forms.ToolTipIcon]::Info)
        Start-Sleep -Milliseconds 5500
        \$n.Dispose()
    " 2>/dev/null
}

toast_macos() {
    osascript -e "display notification \"$MSG\" with title \"$TITLE\"" 2>/dev/null
}

case "$OS" in
    Darwin)               toast_macos ;;
    MINGW*|MSYS*|CYGWIN*) toast_windows ;;
esac
