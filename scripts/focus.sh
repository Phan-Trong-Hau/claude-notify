#!/bin/bash
# Detect if the user is actively watching this session.
# Returns: 0 = user is active (skip notify), 1 = user is away (notify!)
#
# Strategy: UserPromptSubmit hook writes a timestamp when the user sends a
# message. If that timestamp is recent (within focus_timeout seconds), the
# user is considered active. This works cross-platform without console access.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$(cd "$SCRIPT_DIR/.." && pwd)/config.json"

# Normalize to Windows path on MSYS/MINGW
OS="$(uname -s)"
if [[ "$OS" == MINGW* || "$OS" == MSYS* || "$OS" == CYGWIN* ]]; then
    CONFIG_FILE="$(echo "$CONFIG_FILE" | sed 's|^/\([a-zA-Z]\)/|\1:/|')"
fi

TIMEOUT=$(python3 "$SCRIPT_DIR/config.py" "$CONFIG_FILE" "focus_timeout" "30")
STAMP_FILE="${TMPDIR:-/tmp}/claude-notify-active-${CLAUDE_SESSION_ID:-default}"

[ -f "$STAMP_FILE" ] || exit 1  # no record → user is away

LAST=$(cat "$STAMP_FILE" 2>/dev/null) || exit 1
NOW=$(date +%s)
DIFF=$(( NOW - LAST ))

[ "$DIFF" -lt "$TIMEOUT" ]  # exit 0 if recent (active), exit 1 if old (away)
