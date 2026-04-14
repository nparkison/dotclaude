#!/usr/bin/env python3
"""Block git commits that contain AI attribution strings.

Prevents commit messages from including attribution lines that some AI
coding tools append automatically (e.g. "Generated with ...", "Co-Authored-By: ...").
Exit code 2 blocks the tool call and surfaces the error message to the user.

Customize:
  - Add or remove patterns in `blocked_patterns` to match your conventions.
  - Change the error message to reference your own policy doc or rule.
"""
import sys
import json

try:
    data = json.load(sys.stdin)
except (json.JSONDecodeError, ValueError):
    sys.exit(0)

command = (data.get("tool_input") or {}).get("command", "")

if "git commit" not in command:
    sys.exit(0)

blocked_patterns = [
    "co-authored-by: claude",
    "co-authored-by: anthropic",
    "generated with claude code",
    "generated with claude",
    "noreply@anthropic.com",
]

command_lower = command.lower()
for pattern in blocked_patterns:
    if pattern in command_lower:
        print(
            f"BLOCKED: Commit contains '{pattern}'. "
            "AI attribution must not appear in commit messages. "
            "Remove the attribution line and retry.",
            file=sys.stderr,
        )
        sys.exit(2)

sys.exit(0)
