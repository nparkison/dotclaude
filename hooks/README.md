# Hooks

## What Are Hooks?

Hooks are scripts that Claude Code runs automatically at defined points in a session. They can intercept tool calls before they execute, observe them after, react to user input, fire when a session starts or ends, or trigger on desktop notifications. This gives you programmatic control over Claude's behavior without modifying prompts or relying on Claude to remember rules.

Each hook is a shell command (typically a Python script) that receives a JSON payload on stdin describing the event. The hook reads that payload, makes a decision, and communicates back through its exit code and stdout/stderr. Claude Code reads the result and proceeds accordingly.

Hooks can take three actions: **allow** (exit code 0, let the tool call proceed), **block** (exit code 2, cancel the tool call and show an error message from stderr to the user), or **ask** (output a JSON object with `permissionDecision: "ask"`, pause and surface a permission prompt so the user can approve or deny).

Hook types map to lifecycle events: `PreToolUse` fires before a tool executes, `PostToolUse` fires after, `UserPromptSubmit` fires when the user submits a message, `Notification` fires when Claude needs user input, `Stop` fires when a session ends, and `SessionStart` fires when a session starts (with a `compact` matcher to target post-compaction restarts specifically). Hooks are registered in `~/.claude/settings.json` under the `hooks` key, scoped to an event type and optionally filtered by a `matcher` (a regex or tool name pattern).

Hooks run synchronously by default and block execution until they exit, so keep them fast. The `async: true` field in settings.json makes a hook fire-and-forget, useful for Stop hooks that write to disk or call external services.

---

## Hook Lifecycle

1. User or Claude triggers an action (submits a message, calls a tool, ends a session).
2. Claude Code invokes any registered hooks for that event, passing JSON on stdin.
3. The hook reads the event data, runs its logic, and exits.
4. Claude Code reads the result:
   - Exit 0: proceed normally.
   - Exit 2: block the action; show stderr to the user as an error.
   - JSON output with `permissionDecision: "ask"`: pause and prompt the user.
5. Claude continues or stops based on that result.

---

## Hook Reference

| Hook | Event | What it does |
|---|---|---|
| `audit-log.py` | PostToolUse | Logs every tool call to a local audit file |
| `block-attribution.py` | PreToolUse (Bash) | Blocks commits containing AI attribution strings |
| `push-guard.py` | PreToolUse (Bash) | Blocks `git push` and `gh pr merge` |
| `draft-before-create.py` | PreToolUse (MCP tools) | Forces a permission prompt before creating items in shared systems |
| `file-protector.py` | PreToolUse (Edit, Write) | Blocks edits to `.env` files, private keys, and credentials |
| `compact-reinject.py` | SessionStart (compact) | Re-injects critical rules after context compaction |
| `pr-template-reminder.py` | UserPromptSubmit | Reminds Claude to read and follow the repo's PR template |
| `notify.py` | Notification | Sends a desktop notification when Claude needs input |
| `session-to-obsidian.py` | Stop | Exports the session transcript to an Obsidian vault |

---

## Installation

Register hooks in `~/.claude/settings.json` under the `hooks` key. Each event type holds an array of matcher objects; each matcher can run multiple hooks in sequence.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/block-attribution.py",
            "statusMessage": "Checking commit attribution..."
          },
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/push-guard.py",
            "statusMessage": "Checking for push commands..."
          }
        ]
      },
      {
        "matcher": "mcp__your_tool__create_issue|mcp__your_tool__send_message",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/draft-before-create.py",
            "statusMessage": "Enforcing Draft-Before-Create..."
          }
        ]
      },
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/file-protector.py",
            "statusMessage": "Checking file protection..."
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/audit-log.py",
            "timeout": 5
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/pr-template-reminder.py",
            "statusMessage": "Checking for PR template..."
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/notify.py",
            "timeout": 10
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "compact",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/compact-reinject.py"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/session-to-obsidian.py",
            "timeout": 30,
            "statusMessage": "Exporting session to Obsidian...",
            "async": true
          }
        ]
      }
    ]
  }
}
```

**Notes:**
- `matcher` is a regex matched against the tool name. An empty string matches all tools.
- `statusMessage` is shown in the Claude Code UI while the hook runs.
- `timeout` (seconds) kills the hook if it runs too long. Defaults are generous; set tight timeouts on hooks that run on every call.
- `async: true` makes the hook non-blocking. Use this for Stop hooks that do slow I/O.

---

## Writing Your Own Hook

A hook is any executable that reads JSON from stdin and exits with the right code.

**Minimal allow hook:**
```python
#!/usr/bin/env python3
import sys, json

data = json.load(sys.stdin)
# inspect data["tool_name"], data["tool_input"], etc.
sys.exit(0)  # allow
```

**Block with a message:**
```python
print("BLOCKED: reason here", file=sys.stderr)
sys.exit(2)
```

**Ask for permission:**
```python
import json, sys
output = {
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "ask",
        "permissionDecisionReason": "Review this before it runs."
    }
}
print(json.dumps(output))
sys.exit(0)
```

**Inject context (UserPromptSubmit):**
```python
output = {
    "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "Remember: always do X before Y."
    }
}
print(json.dumps(output))
sys.exit(0)
```

**Rules of thumb:**
- Always wrap `json.load(sys.stdin)` in a try/except and exit 0 on parse failure. Don't let a malformed payload block work.
- Never exit 2 from a Stop hook. If the hook fails, log and exit 0 so the session can close.
- Keep PreToolUse hooks fast. They run on every matching tool call; a slow hook adds latency to everything.
- Test with `echo '{"tool_name":"Bash","tool_input":{"command":"echo hi"}}' | python3 your-hook.py`.

---

## Individual Hook Docs

### `audit-log.py`

**What it does:** Appends a timestamped line to `~/.claude/tool-audit.log` on every tool call: timestamp, session ID (first 8 chars), tool name, and working directory. Never blocks. Failures are silently ignored.

**Event:** PostToolUse, matcher: `""` (all tools)

**Customize:** Change `log_path` to write logs elsewhere. Add fields from the `data` dict (e.g. `tool_input`) to capture more detail per call.

---

### `block-attribution.py`

**What it does:** Inspects the command string of any `git commit` call. If the commit message contains AI attribution strings (`Co-Authored-By: Claude`, `Generated with Claude Code`, `noreply@anthropic.com`, and similar), it blocks the commit with exit code 2.

**Event:** PreToolUse, matcher: `Bash`

**Customize:** Edit `blocked_patterns` to add or remove strings. The comparison is case-insensitive. Update the error message to reference your own policy.

---

### `push-guard.py`

**What it does:** Scans any Bash command for `git push` or `gh pr merge` using regex. If found, blocks with exit code 2 and a message directing the user to push manually. Prevents Claude from autonomously publishing to shared repositories.

**Event:** PreToolUse, matcher: `Bash`

**Customize:** The `blocked` list is a list of `(regex_pattern, label)` tuples. Add entries to restrict additional commands (e.g. `gh release create`, `git push --force`), or remove entries if you want to allow certain operations.

---

### `draft-before-create.py`

**What it does:** Returns a `permissionDecision: "ask"` response, which pauses execution and surfaces a permission prompt before the tool call runs. Enforces a draft-before-create policy: Claude must show the user what it intends to create, get explicit approval, and only then proceed.

**Event:** PreToolUse, matcher: your MCP tool names (e.g. `mcp__linear__save_issue|mcp__slack__send_message`)

**Customize:** The hook itself has no tool-specific logic. It always returns "ask". The real customization is in `settings.json`: set the `matcher` to exactly the MCP tool names that interact with your shared systems. Update `permissionDecisionReason` to name those tools or link to your team's policy.

---

### `file-protector.py`

**What it does:** Checks the `file_path` argument of any Edit or Write tool call against three rules: blocks `.env` files (except `.env.example`, `.env.sample`, `.env.template`), blocks private key and certificate files (`.pem`, `.key`, `.p12`, `.pfx`), and blocks a list of named credential files (`id_rsa`, `credentials.json`, `service-account.json`, etc.). Also blocks writes into `.git/` internals.

**Event:** PreToolUse, matcher: `Edit|Write`

**Customize:** Add filenames to `blocked_names` to protect additional specific files. Add extensions to `blocked_suffixes` for other key or cert formats. Remove entries that don't apply to your environment.

---

### `compact-reinject.py`

**What it does:** Prints a block of critical rules to stdout when a session restarts after context compaction. Claude Code injects this text into the new session's context, so important rules from CLAUDE.md are not silently dropped mid-session.

**Event:** SessionStart, matcher: `compact`

**Customize:** Edit the `print()` block. Replace the example rules with your own most-violated instructions. Keep it to 4-6 rules: the ones you've actually had to correct Claude on. Format as a numbered list with a bold rule name and a plain-English description.

---

### `pr-template-reminder.py`

**What it does:** On every user message, checks whether the message is about creating a pull request (matched by regex patterns like "create a PR", "gh pr create", etc.) and whether the current repo has a template at `.github/pull_request_template.md`. If both are true, injects `additionalContext` instructing Claude to read and follow that template. No-ops silently otherwise.

**Event:** UserPromptSubmit, matcher: `""` (all prompts)

**Customize:** No configuration needed for standard GitHub repos. If your template is at a non-standard path, update `template_path`. Add patterns to `pr_patterns` to catch additional phrasings.

---

### `notify.py`

**What it does:** Fires when Claude Code needs user input (the Notification event). Sends a terminal bell character immediately as a fallback, then launches a PowerShell balloon notification via `powershell.exe`. Designed for WSL. The PowerShell call is wrapped in try/except so it fails silently on pure Linux.

**Event:** Notification, matcher: `""` (all notifications)

**Customize:** Replace or extend the notification method for your platform. On macOS, use `osascript -e 'display notification ...'`. On Linux with a desktop, use `notify-send`. The terminal bell works everywhere and requires no changes.

---

### `session-to-obsidian.py`

**What it does:** Exports the session transcript to an Obsidian vault when a session ends. Reads the session JSONL from `~/.claude/projects/`, parses it into turns, and writes a markdown note with YAML frontmatter, a conversation digest, tool usage summary, and a list of files touched. Also copies the raw JSONL to a `_raw/` archive directory. Runs async so it does not block session exit.

**Event:** Stop, matcher: `""` (all sessions)

**Customize:** Update `VAULT_ROOT` to your vault path. Update `SESSIONS_DIR` to the subdirectory where you want session notes to land. Update `PROJECT_MAP` to map your working directory keywords to vault project names for automatic wikilinks. The hook exits 0 on all errors, so failures are logged to `~/.claude/session-export.log` without affecting the session.
