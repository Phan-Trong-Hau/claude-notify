#!/usr/bin/env python3
"""Read a scalar value from merged config by dot-notation key.

Merge order (later overrides earlier):
  1. Plugin's config.json  (defaults)
  2. ~/.claude/settings.json  →  "claude-notify" key  (user overrides)

Usage: config.py <plugin_config_path> <key> [default]
"""
import json, sys, os

def resolve_path(path):
    """Convert Unix-style /c/Users/... to C:/Users/... on Windows."""
    if os.path.exists(path):
        return path
    if path.startswith('/') and len(path) > 2 and path[2] == '/':
        drive = path[1].upper()
        rest = path[3:]
        win_path = drive + ':/' + rest
        if os.path.exists(win_path):
            return win_path
    return path

def deep_merge(base, override):
    """Merge override dict into base dict (shallow for non-dict values)."""
    result = dict(base)
    for k, v in override.items():
        if k in result and isinstance(result[k], dict) and isinstance(v, dict):
            result[k] = deep_merge(result[k], v)
        else:
            result[k] = v
    return result

def load_claude_settings():
    """Load ~/.claude/settings.json and return the 'claude-notify' section."""
    candidates = [
        os.path.expanduser("~/.claude/settings.json"),
        os.path.expanduser("~\\.claude\\settings.json"),
    ]
    for path in candidates:
        try:
            with open(path) as f:
                s = json.load(f)
            return s.get("claude-notify", {})
        except Exception:
            continue
    return {}

def main():
    if len(sys.argv) < 3:
        print("")
        return

    config_path = resolve_path(sys.argv[1])
    key = sys.argv[2]
    default = sys.argv[3] if len(sys.argv) > 3 else ""

    try:
        with open(config_path) as f:
            plugin_cfg = json.load(f)
    except Exception:
        plugin_cfg = {}

    user_cfg = load_claude_settings()
    c = deep_merge(plugin_cfg, user_cfg) if user_cfg else plugin_cfg

    try:
        val = c
        for k in key.split('.'):
            val = val[k]
        if isinstance(val, (dict, list)):
            print(default)
        else:
            print(str(val).lower() if isinstance(val, bool) else str(val))
    except Exception:
        print(default)

main()
