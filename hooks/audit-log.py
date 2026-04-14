#!/usr/bin/env python3
"""Log all tool usage to an audit file.

Appends tool name + timestamp to ~/.claude/tool-audit.log on every tool call.
Designed to be fast — just a file append, never blocks execution.

Customize:
  - Change `log_path` to write logs elsewhere.
  - Extend the log format to include additional fields from `data`
    (e.g., tool_input, hook event name).
"""
import os
import sys
import json
from datetime import datetime

try:
    data = json.load(sys.stdin)
except (json.JSONDecodeError, ValueError):
    sys.exit(0)

tool_name = data.get("tool_name", "unknown")
session_id = data.get("session_id", "unknown")[:8]
cwd = data.get("cwd", "unknown")
timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

log_path = os.path.expanduser("~/.claude/tool-audit.log")

try:
    with open(log_path, "a") as f:
        f.write(f"{timestamp} | {session_id} | {tool_name} | {cwd}\n")
except Exception:
    pass  # Never block on audit failure

sys.exit(0)
