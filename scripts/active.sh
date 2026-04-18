#!/bin/bash
# Called by UserPromptSubmit — records that the user is active.
STAMP_FILE="$HOME/.claude/claude-notify-active"
date +%s > "$STAMP_FILE"
exit 0
