#!/usr/bin/env python3
"""Force a permission prompt before creating items in shared external systems.

Intercepts tool calls that would create or modify items in shared systems
(your PM tool, GitHub, Slack, or any other collaborative platform) and
returns a "ask" permission decision so the user can review and approve
before anything is created.

This enforces a draft-before-create policy: Claude must show the user
exactly what will be created, get explicit approval, and only then proceed.

Customize:
  - In settings.json, configure this hook's `matcher` to target only the
    specific tools that interact with your shared systems (e.g. mcp__github,
    mcp__slack, mcp__linear). Without a matcher, it fires on every tool call.
  - Update the `permissionDecisionReason` message to name your specific tools
    or link to your team's policy doc.
"""
import sys
import json

output = {
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "ask",
        "permissionDecisionReason": (
            "DRAFT-BEFORE-CREATE POLICY: This action will create or modify an item "
            "in a shared system. You must review and explicitly approve the exact "
            "content before it goes live. If you haven't shown a draft to the user "
            "yet, cancel this action and present the draft first."
        ),
    }
}
print(json.dumps(output))
sys.exit(0)
