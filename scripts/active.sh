#!/bin/bash
# Called by UserPromptSubmit hook — records that the user is currently active.
date +%s > "${TMPDIR:-/tmp}/claude-notify-active-${CLAUDE_SESSION_ID:-default}"
exit 0
