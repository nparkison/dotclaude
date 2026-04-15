---
name: sprint-prep
description: Pre-sprint planning briefing - analyzes active sprint for stale stories, unowned work, and backlog orphans
scope: all
version: 1.0.0
---

# Sprint Prep

**Purpose:** Deliver a triage-ready briefing before sprint planning by analyzing the active Engineering sprint for stale stories, unowned work, chronic bouncers, and backlog orphans. Creates an Obsidian note for each session.

**When to use:** Before sprint planning, or anytime you want a health check on the current sprint and backlog.

---

## Workflow

### Step 1: Get Active Sprint Context

Query {{PM_TOOL}} for the active Engineering team iteration.

**Engineering team details:**
- Team mention name: `eng`
- Team ID: `{{ENGINEERING_TEAM_ID}}`

Use the {{PM_TOOL}} API to:
1. Get the active iteration for the Engineering team
2. Pull ALL stories in that iteration (not just a sample)
3. Note the sprint name, start date, and end date

---

### Step 2: Analyze Stories for Staleness Signals

For every story in the active iteration, evaluate against these detection criteria:

**Tier 1: Action Required (ALWAYS flag these):**

| Signal | How to Detect | Threshold |
|--------|--------------|-----------|
| Chronic bouncer | `previous_iteration_ids` array length | >= 2 |
| Unowned in sprint | `owner_ids` is empty array | Any story in active iteration |
| Stale in sprint | `updated_at` > 7 days ago AND `started` is false | 7+ days without update, not started |

**Tier 2: Worth Reviewing (flag if present):**

| Signal | How to Detect | Threshold |
|--------|--------------|-----------|
| Customer-linked & dark | Story is in a customer-named epic AND no activity | > 14 days since `updated_at` |
| Owner left/disabled | Story `owner_ids` references a disabled user | Any |
| Once bounced | `previous_iteration_ids` array length == 1 | Trending toward chronic |

---

### Step 3: Scan Backlog for Orphans

Query {{PM_TOOL}} for stories that have fallen out of sprints entirely:

- Workflow state: "To Do" (unstarted states)
- `iteration_id`: null (not in any sprint)
- `owner_ids`: empty (no owner)
- `created_at`: older than 30 days

Also flag stories that:
- Have an estimate but `started_at` is null and are older than 60 days (groomed but abandoned)
- Were in previous iterations but are no longer in any iteration

---

### Step 4: Cross-Reference Customer Pressure (Slack)

For stories flagged in Tier 1 and Tier 2, search Slack for recent mentions:

1. Search {{SLACK_CHANNEL}} for story IDs or story keywords
2. Search relevant customer feedback channels for related mentions
3. Note any customer names, urgency language, or timeline expectations
4. Add this context to the story's entry in the briefing

**This step enriches the briefing with real customer pressure signals: the kind of context that turns a list of stale tickets into actionable triage.**

---

### Step 5: Build the Briefing

Use parallel agents where possible to speed up data gathering (Steps 1-4 can partially overlap).

Present the briefing in this format:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 SPRINT PREP: [Sprint Name] (ends [date])
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SPRINT HEALTH SNAPSHOT
  Stories: XX | Unowned: XX | Not started: XX
  Carried over: XX | Stale (7+ days): XX

──── PRIORITY TRIAGE (needs a decision before planning) ───

1. [STORY-ID]: [Story Title]
   [Signal]: [details] | [Owner status] | [Estimate status]
   Context: [Customer mentions, related completed work, epic status]
   → Recommend: [Specific recommended action]

2. ...

──── REVIEW (trending toward stale) ────────────────────────

3. [STORY-ID]: [Story Title]
   [Signal]: [details]
   → [Suggested check-in or action]

──── FULL INVENTORY ─────────────────────────────────────────

All flagged stories in a compact table:

| # | Story | Signal | Owner | Bounces | Last Update | Action |
|---|-------|--------|-------|---------|-------------|--------|
| 1 | [ID] Title | Chronic bouncer | None | 9 | Dec 8 | Assign or defer |
| ... complete list, no cap ... |

──── BACKLOG ORPHANS ────────────────────────────────────────

Stories in "To Do" with no sprint, no owner, older than 30 days:

| Story | Age | Last Update | Epic |
|-------|-----|-------------|------|
| ... complete list ... |

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Formatting rules:**
- Priority Triage section: rich context + recommended action per story. No cap on items; show all Tier 1 flags.
- Review section: lighter context for Tier 2 items.
- Full Inventory: compact table with EVERY flagged story. Include {{PM_TOOL}} links.
- Backlog Orphans: complete list, sorted oldest first.
- Each recommended action should be specific and decisive: "Assign to [person]", "Move to backlog with customer comms", "Archive (superseded by [other story])", "Needs grooming session", etc.

---

### Step 6: Create Obsidian Note

Create a note in the Obsidian vault for this sprint prep session.

**Location:** `{{OBSIDIAN_VAULT}}/Sprint Prep/`

**Filename:** `YYYY-MM-DD Sprint Prep - [Sprint Name].md`

**Frontmatter:**
```yaml
---
created: YYYY-MM-DD
updated: YYYY-MM-DD
type: reference
status: developing
tags:
  - sprint-prep
  - backlog-health
related:
  - "[[Most recent prior sprint prep note]]"
---
```

**Content includes:**
- Full briefing content (same structure as conversation output)
- Every story ID is a clickable {{PM_TOOL}} link
- Links to related Obsidian notes (feature epic docs, past sprint preps, investigation notes)
- A blank "Decisions Made" section at the bottom:

```markdown
## Decisions Made

_Fill in during/after sprint planning:_

| Story | Decision | Owner | Notes |
|-------|----------|-------|-------|
| | | | |
```

**Linking rules (per vault conventions):**
- Link to the most recent prior sprint prep note
- Link to any feature/epic docs referenced in the triage
- Use alias syntax: `[[Note Title|natural display text]]`
- Search for existing related notes in the vault before finalizing

**If the `Sprint Prep/` directory doesn't exist yet, create it.**

**If the Obsidian vault is not accessible**, warn the user and skip the Obsidian note. Do NOT fail the entire command.

---

### Step 7: Summary

After presenting the briefing and creating the Obsidian note, provide:
- Total number of stories needing attention
- The single most urgent item to discuss first in planning
- The Obsidian note path

---

## Important Notes

- **Delegate aggressively.** Use parallel sub-agents for {{PM_TOOL}} queries, Slack searches, and Obsidian note creation. The user is waiting for a briefing, not watching queries run.
- **All sub-agents MUST use `model: "sonnet"`.** Never use haiku.
- **Never update {{PM_TOOL}}** (no story edits, no comments, no status changes) unless explicitly instructed.
- **Context is king.** The value of this command over a dumb script is the cross-referencing: connecting a stale story to a Slack mention to a completed related epic. Invest time in making those connections.
- **Be opinionated in recommendations.** Don't just flag problems. Suggest specific actions. "Assign to [person] based on their work on [related story]" is better than "needs an owner."
- **{{PM_TOOL}} story links** format: configure for your instance URL.
