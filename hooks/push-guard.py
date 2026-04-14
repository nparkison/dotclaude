#!/usr/bin/env python3
"""Block git push and destructive GitHub CLI operations.

Prevents Claude from pushing to remote repositories or merging PRs
automatically. These actions affect shared state and should always
be performed manually by the developer.

Customize:
  - Add entries to `blocked` to restrict additional commands
    (e.g. "gh release create", "git push --force").
  - Remove entries from `blocked` if you want to allow certain operations
    (e.g. you may want to allow non-force pushes to feature branches).
  - Adjust the error message to reference your team's push policy.
"""
import sys
import json
import re

try:
    data = json.load(sys.stdin)
except (json.JSONDecodeError, ValueError):
    sys.exit(0)

command = (data.get("tool_input") or {}).get("command", "")

# Each entry is (regex_pattern, human_readable_label).
# Add or remove entries here to control what is blocked.
blocked = [
    (r"git\s+push", "git push"),
    (r"gh\s+pr\s+merge", "gh pr merge"),
]

for pattern, label in blocked:
    if re.search(pattern, command):
        print(
            f"BLOCKED: '{label}' is not allowed. "
            "Push and merge operations must be performed manually. "
            "Stage your changes and push from your terminal.",
            file=sys.stderr,
        )
        sys.exit(2)

sys.exit(0)
