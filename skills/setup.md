---
name: setup
description: Interactive setup wizard. Fills all placeholders, configures hooks, removes irrelevant sections, and personalizes your dotclaude installation. Run this after install.sh.
---

## Step 0: Prerequisites Check

Check if `~/.claude/CLAUDE.md` exists. If it does not, tell the user:
"Run `./install.sh all` from the dotclaude repo first, then run `/setup` again."
Stop immediately.

If the file exists, scan for remaining `{{` tokens across `~/.claude/CLAUDE.md` and every file matching `~/.claude/skills/**/*.md`. Count the total.

If zero `{{` tokens are found, say: "Looks like everything is already configured. Want to re-run setup anyway? (yes / no)" and wait. If they say no, stop.

---

## Step 1: Gather Identity Info

Send this message exactly (do not split into multiple messages):

```
Let's personalize your dotclaude setup. I need a few details:

1. GitHub username:
2. Organization or team name (e.g., "Acme Corp"):
3. Main repo name (e.g., "my-app" or "acme-corp/my-app"):
4. Your team name within the org (e.g., "Platform", "Mobile"):
```

Wait for all four answers before continuing.

---

## Step 2: Gather Tool Preferences

Send this message exactly (do not split):

```
Now let's configure your tools:

5. Project management tool?
   a) Linear
   b) Shortcut
   c) Jira
   d) GitHub Issues
   e) None / skip

6. Do you use Obsidian for notes?
   a) Yes (provide vault path, e.g., ~/Documents/MyVault)
   b) No

7. Do you use Slack for team communication?
   a) Yes (default channel, e.g., #engineering)
   b) No

8. Your role?
   a) Developer
   b) Product Manager
   c) Both
```

Wait for answers. If they chose a PM tool (a-d), follow up:
```
Two more for your PM tool:
- API base URL (e.g., https://api.linear.app or https://api.app.shortcut.com/api/v3): (or "skip")
- Engineering team ID (numeric or slug, used to scope queries): (or "skip")
```

---

## Step 3: Confirm Plan

Before making any changes, present a summary like this (fill in actual values from their answers):

```
Here is what I will do. Please confirm before I proceed.

Placeholders to fill:
  {{YOUR_ORG}}             → [their answer]
  {{YOUR_REPO}}            → [their answer]
  {{YOUR_GITHUB_USERNAME}} → [their answer]
  {{YOUR_TEAM}}            → [their answer]
  {{PM_TOOL}}              → [their answer, or "(skipped)"]
  {{PM_TOOL_API_BASE}}     → [their answer, or "(skipped)"]
  {{PM_TOOL_AUTH_HEADER}}  → [derived value, or "(skipped)"]
  {{ENGINEERING_TEAM_ID}}  → [their answer, or "(skipped)"]
  {{NOTE_SYSTEM}}          → [Obsidian / their answer / "(skipped)"]
  {{OBSIDIAN_VAULT}}       → [their path, or "(skipped)"]
  {{SLACK_CHANNEL}}        → [their answer, or "(skipped)"]
  {{SLACK_TOOL}}           → [derived, or "(skipped)"]

Sections to remove:
  [List each section being removed and the reason, e.g.:]
  - "Bug/Issue Triage Workflow" in CLAUDE.md (no PM tool configured)
  - skills/developer/triage.md deleted (no PM tool configured)
  - Obsidian steps in finish.md (Obsidian not configured)
  - Slack steps in monitors.md, cs-doc.md, etc. (Slack not configured)
  - skills/product-manager/ deleted (role is Developer only)

Hooks to register in ~/.claude/settings.json:
  - block-attribution.py (always)
  - push-guard.py (always)
  - file-protector.py (always)
  - audit-log.py (always)
  - notify.py (always)
  - compact-reinject.py (always)
  - draft-before-create.py (if PM tool configured)
  - session-to-obsidian.py (if Obsidian configured)
  - pr-template-reminder.py (always, optional — include? yes/no)

Reply "go ahead" to proceed, or tell me what to change.
```

Wait for explicit approval ("yes", "go ahead", "approved", "ok"). Do not proceed without it.

---

## Step 4: Fill Placeholders

Use the Edit tool with `replace_all=true` for each placeholder. Process every file in `~/.claude/` that contains the token. Skip files silently if they do not exist.

**Auth header derivation:**
- Linear: `Authorization: $LINEAR_API_KEY`
- Shortcut: `Shortcut-Token: $SHORTCUT_API_TOKEN`
- Jira: `Authorization: Basic $JIRA_API_TOKEN`
- GitHub Issues: `Authorization: token $GITHUB_TOKEN`

**Slack tool derivation:**
- If user says yes to Slack: `Slack MCP`

**Placeholder-to-file mapping:**

| Placeholder | Files to update |
|---|---|
| `{{YOUR_ORG}}` | `~/.claude/CLAUDE.md`, all `~/.claude/skills/**/*.md` |
| `{{YOUR_REPO}}` | `~/.claude/CLAUDE.md`, all `~/.claude/skills/**/*.md` |
| `{{YOUR_GITHUB_USERNAME}}` | `~/.claude/CLAUDE.md` |
| `{{YOUR_TEAM}}` | `~/.claude/CLAUDE.md`, all `~/.claude/skills/**/*.md` |
| `{{PM_TOOL}}` | `~/.claude/CLAUDE.md`, `skills/developer/triage.md`, `skills/developer/monitors.md`, `skills/developer/release-notes.md`, `skills/product-manager/sprint-prep.md`, `skills/product-manager/story.md`, `skills/product-manager/cs-doc.md`, `skills/product-manager/plan-feature.md` |
| `{{PM_TOOL_API_BASE}}` | `skills/developer/monitors.md`, `skills/product-manager/sprint-prep.md`, `skills/product-manager/cs-doc.md`, `skills/developer/release-notes.md` |
| `{{PM_TOOL_AUTH_HEADER}}` | same as `{{PM_TOOL_API_BASE}}` |
| `{{ENGINEERING_TEAM_ID}}` | `skills/developer/monitors.md`, `skills/product-manager/sprint-prep.md` |
| `{{NOTE_SYSTEM}}` | `~/.claude/CLAUDE.md` |
| `{{OBSIDIAN_VAULT}}` | `~/.claude/hooks/session-to-obsidian.py` |
| `{{SLACK_CHANNEL}}` | `skills/developer/monitors.md`, `skills/product-manager/cs-doc.md`, `skills/developer/release-notes.md`, `skills/product-manager/sprint-prep.md` |
| `{{SLACK_TOOL}}` | same as `{{SLACK_CHANNEL}}` |

For each placeholder:
1. If the user's value is "skip" or blank, leave `{{PLACEHOLDER}}` as-is and continue.
2. Otherwise use `Edit` with `replace_all=true` to replace every occurrence in each listed file.
3. Read the file first, then edit it. Skip silently if the file does not exist.

---

## Step 5: Remove Conditional Sections

Apply these removals based on the user's answers. Use the Edit tool: read the file, identify the exact section boundaries, replace the block with nothing (or with a one-line comment: `<!-- Removed by /setup: [reason] -->`).

**If PM tool = none (answer was "e" or "None"):**
- `~/.claude/CLAUDE.md`: Remove the `## Bug/Issue Triage Workflow` section through the next `---` separator.
- `~/.claude/CLAUDE.md`: Remove the `## Project Management Rules` section through the next `---` separator.
- Delete `~/.claude/skills/developer/triage.md` (use Bash `rm -f`).

**If Obsidian = no:**
- `~/.claude/skills/developer/finish.md`: Find all numbered steps or bullet points containing the word "Obsidian" and remove those steps and their sub-bullets.
- Remove any lines in skill files that contain `{{OBSIDIAN_VAULT}}` (if not already handled by step 4 skip).
- `~/.claude/CLAUDE.md`: Remove the `## Documentation Habits` section through the next `---` separator.

**If Slack = no:**
- In each of these files, find numbered steps or bullet points containing the word "Slack" and remove those steps: `skills/developer/monitors.md`, `skills/product-manager/cs-doc.md`, `skills/developer/release-notes.md`, `skills/product-manager/sprint-prep.md`.

**If role = Developer only (answer was "a"):**
- Delete `~/.claude/skills/product-manager/` directory entirely (use Bash `rm -rf`).

**If role = PM only (answer was "b"):**
- Keep all developer skills. PMs who use Claude Code benefit from them.

---

## Step 6: Register Hooks in settings.json

Read `~/.claude/settings.json`. If the file does not exist, start with `{}`.

Parse the JSON. If a `hooks` key is missing, add it. Merge each block below into the existing structure.

Before inserting any hook entry, check whether the same `command` value already exists anywhere in the hooks array for that event type. If it does, skip that entry.

**Always register (all users):**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "python3 ~/.claude/hooks/block-attribution.py" },
          { "type": "command", "command": "python3 ~/.claude/hooks/push-guard.py" }
        ]
      },
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "python3 ~/.claude/hooks/file-protector.py" }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "python3 ~/.claude/hooks/audit-log.py", "async": true }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "python3 ~/.claude/hooks/notify.py" }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "python3 ~/.claude/hooks/compact-reinject.py" }
        ]
      }
    ]
  }
}
```

**If PM tool was configured, also add to PreToolUse.** Ask the user:
"What prefix do your MCP tool names use? (e.g., `mcp__linear` or `mcp__shortcut`) Type 'skip' to configure this manually later."

If they provide a prefix, add:
```json
{
  "matcher": "[prefix]__.*create.*|[prefix]__.*update.*",
  "hooks": [
    { "type": "command", "command": "python3 ~/.claude/hooks/draft-before-create.py" }
  ]
}
```

**If Obsidian was configured, add a Stop hook:**
```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "python3 ~/.claude/hooks/session-to-obsidian.py", "async": true }
        ]
      }
    ]
  }
}
```

**If user approved pr-template-reminder in Step 3, add to PreToolUse Bash matchers:**
```json
{ "type": "command", "command": "python3 ~/.claude/hooks/pr-template-reminder.py" }
```

Write the merged JSON back to `~/.claude/settings.json` with 2-space indentation.

---

## Step 7: Summary

Print this message (fill in actual counts):

```
Setup complete.

Configured:
  - [N] placeholder values filled across [M] files
  - [X] sections removed (features not configured)
  - [Y] hooks registered in ~/.claude/settings.json

Not configured (skipped values left as {{PLACEHOLDER}}):
  [List any placeholders that were skipped, if any]

Next steps:
  - Restart Claude Code to pick up the new hook settings.
  - For project-specific conventions, copy ~/.claude/skills/ templates into
    .claude/skills/ inside your repo and fill in the remaining details.
  - Run /setup again from inside a project directory to layer in project context.
```

---

## Step 8: Edge Cases

Follow these rules throughout the skill execution:

- If a placeholder value is "skip" or the user left it blank, do not replace the `{{PLACEHOLDER}}` token. Leave it as-is for manual configuration later.
- If `settings.json` already has hooks for the same event type, merge the new entries into the existing array. Do not overwrite the whole array. Check for duplicate `command` values before inserting.
- If the user says "I already filled some of these", scan for remaining `{{` tokens first. Only ask about the ones that remain unfilled.
- If a file listed in Step 4 does not exist (e.g., the user ran `install.sh developer` and skipped product-manager skills), skip it silently without error.
- Accept free-text answers for PM tool. "My Company's Jira" or "our internal tracker" are valid. Use the raw text as the `{{PM_TOOL}}` replacement value.
- If the user gives partial answers in Step 1 or Step 2 (e.g., only answers 3 of 4 questions), ask for the missing items specifically before continuing.
- Never proceed past Step 3 without explicit approval.
