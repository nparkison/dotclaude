#!/usr/bin/env python3
"""Remind Claude to read and follow the repo's PR template when creating PRs.

Fires on UserPromptSubmit. If the user's message mentions creating or opening
a PR and the repo has a PR template at .github/pull_request_template.md,
injects additionalContext instructing Claude to read and match that template.

No configuration needed. The hook detects the template automatically based
on the current working directory. Works with any repository that follows the
standard GitHub PR template location.

SETUP (.claude/settings.json):
  {
    "hooks": {
      "UserPromptSubmit": [
        { "matcher": "", "hooks": [{ "type": "command", "command": "python3 /path/to/pr-template-reminder.py" }] }
      ]
    }
  }
"""
import sys
import json
import os
import re

try:
    raw = sys.stdin.read()
    data = json.loads(raw) if raw.strip() else {}
except (json.JSONDecodeError, ValueError):
    data = {}

haystack = raw.lower() if raw else json.dumps(data).lower()

pr_patterns = [
    r"\b(create|open|draft|prepare|make|set\s*up)\b.*\b(pr|pull\s*request)\b",
    r"\b(pr|pull\s*request)\b.*\b(create|open|draft|prepare|make)\b",
    r"gh\s+pr\s+create",
]

if not any(re.search(p, haystack) for p in pr_patterns):
    sys.exit(0)

template_path = os.path.join(os.getcwd(), ".github", "pull_request_template.md")
if not os.path.isfile(template_path):
    sys.exit(0)

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": (
            "MANDATORY: This repo has a PR template at .github/pull_request_template.md. "
            "You MUST read it with the Read tool and structure the PR body to match "
            "that template exactly. Do NOT use a custom format."
        ),
    }
}))
