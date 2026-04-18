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
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
        \$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        \$xml.LoadXml(@\"
<toast>
  <visual><binding template=\"ToastGeneric\">
    <text>\$title</text>
    <text>\$msg</text>
  </binding></visual>
  <audio silent=\"true\"/>
</toast>
\"@)
        \$toast = [Windows.UI.Notifications.ToastNotification]::new(\$xml)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show(\$toast)
    " 2>/dev/null
}

toast_macos() {
    osascript -e "display notification \"$MSG\" with title \"$TITLE\"" 2>/dev/null
}

case "$OS" in
    Darwin)               toast_macos ;;
    MINGW*|MSYS*|CYGWIN*) toast_windows ;;
esac
