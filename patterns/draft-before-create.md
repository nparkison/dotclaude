# Draft-Before-Create

## Problem

AI creating items in shared team systems without review is the fastest way to destroy trust. A PM tool story with wrong labels, a GitHub PR with a half-baked description, a Slack message sent before you were ready. These are visible to your team immediately and can be awkward to undo.

Claude is eager to help. If you say "create a Linear story for the broken export button," it will create it. Right now. The priority might be wrong. The labels might be off. The description might be missing key context you haven't shared yet. And now it's in the backlog for everyone to see.

Local file edits are low-stakes. If Claude writes something wrong to a file on your machine, you fix it before it ships. Shared systems don't give you that buffer.

## Pattern

Never create items in any shared external system without presenting a draft to the user and getting explicit approval first.

The flow is always: **Draft. Present. Approve. Create.**

This applies to:
- PM tool stories and epics (Linear, Shortcut, Jira, GitHub Issues)
- GitHub PRs and PR comments
- Slack messages and replies
- Comments on existing issues or tickets

The key distinction: when a user says "create a story for X," that instruction tells Claude *what* to create, not to skip the review step. The written form of a ticket has details the user hasn't specified. Those details need review before they go live.

Even if the content was discussed in the conversation. The discussion is not the same as the written artifact. Drafting it makes the implicit explicit and gives the user a chance to correct anything before it's shared.

## Implementation

### CLAUDE.md instruction

Add this to your CLAUDE.md to establish the policy as a soft constraint:

```markdown
## Hard Rule: Draft-Before-Create

Never create items in [your PM tool], GitHub (PRs/issues), Slack, or any shared external system
without explicit user approval.

Mandatory process, no exceptions:
1. Draft the full content (title, description, labels, assignee, etc.) in the conversation.
2. Present the draft to the user for review.
3. Wait for explicit approval ("looks good", "create it", "approved").
4. Only then create the item via API or CLI.

This applies even if the user says "create a story for X." Draft it first, then create after approval.
This applies to comments on existing tickets, PRs, and Slack threads too.
```

The CLAUDE.md instruction handles most cases. Claude follows it the majority of the time when it's clearly stated. But "most of the time" isn't good enough for shared systems.

### Hook: hard enforcement

The `hooks/draft-before-create.py` hook catches the cases where Claude forgets. It intercepts MCP tool calls that would create or modify shared items and returns a `permissionDecision: "ask"` response. This pauses execution and surfaces a permission prompt so you can review before anything is created.

The hook itself is simple by design:

```python
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
```

It always returns "ask." No logic, no conditions. The real work is in the `matcher` in `settings.json`.

### settings.json registration

Register the hook under `PreToolUse` with a matcher that targets your specific shared-system MCP tools:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__linear__save_issue|mcp__slack__send_message|mcp__github__create_pull_request",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/draft-before-create.py",
            "statusMessage": "Enforcing Draft-Before-Create..."
          }
        ]
      }
    ]
  }
}
```

Update the `matcher` regex to match the MCP tool names in your setup. The tool names follow the pattern `mcp__<server>__<tool>`. You can find the exact names by checking your MCP server configuration or watching what tool names appear in the permission prompt when you run them manually.

Be specific. An overly broad matcher (or no matcher at all) fires on every tool call, which adds friction to everything. Target only the tools that write to shared systems.

### Two-layer enforcement

CLAUDE.md handles the normal case: Claude sees the instruction, understands the policy, drafts first. The hook handles the edge cases: Claude forgets, misreads intent, or gets overconfident after a long context window. Together they're more reliable than either alone.

## Example

**Without this pattern:**

```
User: "Create a bug ticket for the broken export button"

Claude: [immediately creates Linear issue]
Title: "Export button broken"
Description: "The export button is broken."
Priority: Medium
Label: bug
```

The ticket goes live with a useless description, wrong priority (it's blocking a customer), and no reproduction steps. The team sees it in the backlog and has no idea what to do with it.

**With this pattern:**

```
User: "Create a bug ticket for the broken export button"

Claude: Here's a draft before I create it:

---
Title: Export button fails for datasets over 10k rows
Description:
  Steps to reproduce:
  1. Navigate to Reports > Export
  2. Select a date range that returns > 10,000 rows
  3. Click "Export to CSV"

  Expected: File downloads
  Actual: Spinner runs indefinitely, no download, no error message

Priority: High
Labels: bug, export, data
---

Does this look right? Anything to adjust before I create it?

User: Change priority to Urgent and add "customer-reported" to the labels.

Claude: [creates issue with corrected priority and labels]
```

The ticket that goes into the backlog is accurate, actionable, and correctly prioritized. The team sees something they can act on.
