#!/bin/bash
# Called by UserPromptSubmit — records that the user is active.
SESSION="${CLAUDE_SESSION_ID:-default}"
date +%s > "${TMPDIR:-/tmp}/claude-notify-active-$SESSION"
exit 0
