---
name: monitors
description: Daily proactive checks — stale PRs, sprint health, unowned stories. Surfaces problems before standup.
scope: all
version: 1.0.0
---

# Monitors

**Purpose:** Run daily proactive health checks across GitHub and Shortcut to surface engineering problems before standup. Quick pulse check — not a full sprint analysis (use `/sprint-prep` for that).

**When to use:** Daily before standup (~8:50am ET), or anytime you want a quick health check on PRs and sprint work.

---

## Workflow

### Step 1: Gather Data (Parallel)

Dispatch parallel sub-agents (all `model: "sonnet"`) to gather data simultaneously:

**Agent A — Open PRs:**

```bash
gh pr list --repo slabstack/gravel --state open --json number,title,author,createdAt,updatedAt,reviewDecision,reviewRequests,url,headRefName,isDraft
```

**Agent B — Active Sprint Stories:**

Query Shortcut API for the active Engineering iteration and its stories. There is NO Shortcut MCP — use bash `curl` with `$SHORTCUT_API_TOKEN`.

```bash
# List iterations, find the active one for the Engineering team
curl -s -H "Content-Type: application/json" -H "Shortcut-Token: $SHORTCUT_API_TOKEN" \
  "https://api.app.shortcut.com/api/v3/iterations"
```

Filter for the iteration where `status == "started"` and `group_ids` contains `65f0cf94-6246-490c-a18c-a4c32ea9e57b` (Engineering team ID).

Then fetch all stories in that iteration:
```bash
curl -s -H "Content-Type: application/json" -H "Shortcut-Token: $SHORTCUT_API_TOKEN" \
  "https://api.app.shortcut.com/api/v3/iterations/{iteration_id}/stories"
```

Also pre-fetch the members list for owner name resolution in Checks 2 and 3:
```bash
curl -s -H "Content-Type: application/json" -H "Shortcut-Token: $SHORTCUT_API_TOKEN" \
  "https://api.app.shortcut.com/api/v3/members"
```

**Note on iterations API:** The list endpoint may return many iterations. Filter client-side for `status == "started"`. If the response is paginated, handle pagination. There should be exactly one active Engineering iteration at any time.

**Error handling:**
- If `$SHORTCUT_API_TOKEN` is not set or the API returns a non-2xx status, abort the Shortcut checks and report the error to the user. Still run Check 1 (GitHub PRs) independently.
- If no active Engineering iteration is found (zero matches after filtering), report "No active Engineering sprint found — skipping sprint health and unowned work checks" and skip Checks 2 and 3.

---

### Step 2: Run the Three Checks

**Check 1 — Stale PRs (open >48h, no approved review):**

From Agent A data, flag PRs where:
- `isDraft` is false
- Opened more than 48 hours ago (`createdAt`)
- `reviewDecision` is NOT `"APPROVED"`
- Has pending review requests with no activity, OR has zero reviews

For each flagged PR, note: PR number, title, author login, age in days, review status, URL.

**Check 2 — Sprint Health (stories stuck in development):**

From Agent B data, flag stories where:
- Workflow state type is `"started"` (actively in development — not unstarted, not done)
- `updated_at` is more than 5 days ago
- Cross-reference with open PRs from Agent A: does any open PR branch name contain `sc-{story_id}` (case-insensitive)? If there's a linked PR, note its status.

For each flagged story: story ID, title, owner name (resolve from `owner_ids` using the members list pre-fetched in Agent B), days since last update, linked PR status.

**Check 3 — Unowned Work:**

From Agent B data, flag stories where:
- `owner_ids` is an empty array
- Story is in the active sprint

For each flagged story: story ID, title, story type, estimate.

---

### Step 3: Format the Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 DAILY MONITORS — YYYY-MM-DD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

──── STALE PRs (open >48h, no approved review) ────

[count] PRs need attention:

• #1234 — PR Title (@author, Xd old)
  Review: [waiting on @reviewer / no reviewers assigned / changes requested]
  https://github.com/slabstack/gravel/pull/1234

...or "✓ No stale PRs" if clean.

──── SPRINT HEALTH — [Sprint Name] (ends [date]) ────

[count] stories stuck in development >5d:

• SC-XXXX — Story Title (@owner, Xd since update)
  PR: [#1234 — stalled / no PR found]
  https://app.shortcut.com/slabstack/story/XXXX

...or "✓ All in-progress stories have recent activity" if clean.

──── UNOWNED WORK ────

[count] sprint stories with no owner:

• SC-XXXX — Story Title (type: feature, est: 3pt)
  https://app.shortcut.com/slabstack/story/XXXX

...or "✓ All sprint stories have owners" if clean.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**All-clear shortcut:** If ALL three checks pass with zero flags, output just:
```
✓ DAILY MONITORS — YYYY-MM-DD — All clear. No stale PRs, no stuck stories, no unowned work.
```

---

### Step 4: Post to Slack (Draft-First)

1. Draft the report using the Slack MCP `slack_send_message_draft` tool (full tool name: `mcp__plugin_slack_slack__slack_send_message_draft`) to the user's preferred channel
2. Present the draft for review
3. On approval, send via `slack_send_message` (full tool name: `mcp__plugin_slack_slack__slack_send_message`)

**Default channel:** DM to self for initial testing. Once the format is validated, edit the skill file to hardcode the preferred team channel.

**Note:** Slack MCP tool names use the `mcp__plugin_slack_slack__` prefix. If tools are not available in the session, skip Slack output and present the report in the conversation instead.

---

### Step 5: Log to Obsidian

Insert each day's report at the top of a monthly rolling log in the Obsidian vault (newest first).

**Location:** `/mnt/i/My Drive/NP-brain-backup/Projects/Slabstack/Monitors/`

**Filename:** `YYYY-MM Monitors Log.md` (one file per month)

**If the file doesn't exist yet**, create it with:
```yaml
---
created: YYYY-MM-DD
updated: YYYY-MM-DD
type: log
project: slabstack
tags:
  - slabstack
  - monitors
  - daily-health
related:
  - "[[Sprint Prep|Sprint Prep briefings]]"
---

# Monitors Log — YYYY-MM
```

**Each day's entry:** Insert below the frontmatter and heading (newest first):

```markdown
## YYYY-MM-DD

[Full report text — same as Slack output]

---
```

Update the `updated` field in the frontmatter to today's date.

**If the vault is not accessible:** Warn and skip. Do NOT fail the whole skill.

---

### Step 6: Summary

After posting and logging:
- Total issues found (X stale PRs, Y stuck stories, Z unowned)
- The single most urgent item (if any)
- Obsidian log path in Windows format: `I:\My Drive\NP-brain-backup\Projects\Slabstack\Monitors\YYYY-MM Monitors Log.md`

---

## Configuration

| Setting | Default | Notes |
|---------|---------|-------|
| Stale PR threshold | 48 hours | Adjust after running for a week |
| Stuck story threshold | 5 days | Stories in dev with no update for >5d |
| Slack channel | DM to self | Switch to team channel when format is stable |
| Engineering team ID | `65f0cf94-6246-490c-a18c-a4c32ea9e57b` | Shortcut team |

---

## Important Notes

- **Delegate aggressively.** Use parallel sub-agents for GitHub + Shortcut queries.
- **All sub-agents MUST use `model: "sonnet"`.** Never use haiku.
- **Read-only.** Never modify PRs, stories, or sprint data. Only observe and report.
- **Surfaces problems, does NOT take action.** No auto-pinging engineers, no auto-assigning stories.
- **Shortcut API auth:** `curl -s -H "Shortcut-Token: $SHORTCUT_API_TOKEN"` — there is NO Shortcut MCP.
- **Shortcut story links:** `https://app.shortcut.com/slabstack/story/XXXX`
- **GitHub repo:** `slabstack/gravel`
- **This is NOT `/sprint-prep`.** Monitors is a quick daily pulse check. Sprint prep is a comprehensive pre-planning briefing. Don't overload this with analysis — keep it fast and focused.
