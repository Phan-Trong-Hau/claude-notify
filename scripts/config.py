#!/usr/bin/env python3
"""Read a scalar value from config.json by dot-notation key.
Usage: config.py <config_path> <key> [default]
Example: config.py /path/config.json notify.sysbeep true
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

def main():
    if len(sys.argv) < 3:
        print("")
        return

    config_path = resolve_path(sys.argv[1])
    key = sys.argv[2]
    default = sys.argv[3] if len(sys.argv) > 3 else ""

    try:
        with open(config_path) as f:
            c = json.load(f)
        val = c
        for k in key.split('.'):
            val = val[k]
        print(str(val).lower() if isinstance(val, bool) else str(val))
    except Exception:
        print(default)

main()
