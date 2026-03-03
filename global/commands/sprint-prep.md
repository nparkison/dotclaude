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

Query Shortcut for the active Engineering team iteration.

**Engineering team details:**
- Team mention name: `eng`
- Team ID: `65f0cf94-6246-490c-a18c-a4c32ea9e57b`

Use the Shortcut MCP to:
1. Get the active iteration for the Engineering team
2. Pull ALL stories in that iteration (not just a sample)
3. Note the sprint name, start date, and end date

---

### Step 2: Analyze Stories for Staleness Signals

For every story in the active iteration, evaluate against these detection criteria:

**Tier 1 — Action Required (ALWAYS flag these):**

| Signal | How to Detect | Threshold |
|--------|--------------|-----------|
| Chronic bouncer | `previous_iteration_ids` array length | >= 2 |
| Unowned in sprint | `owner_ids` is empty array | Any story in active iteration |
| Stale in sprint | `updated_at` > 7 days ago AND `started` is false | 7+ days without update, not started |

**Tier 2 — Worth Reviewing (flag if present):**

| Signal | How to Detect | Threshold |
|--------|--------------|-----------|
| Customer-linked & dark | Story is in a customer-named epic AND no activity | > 14 days since `updated_at` |
| Owner left/disabled | Story `owner_ids` references a disabled Shortcut user | Any |
| Once bounced | `previous_iteration_ids` array length == 1 | Trending toward chronic |

---

### Step 3: Scan Backlog for Orphans

Query Shortcut for stories that have fallen out of sprints entirely:

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

1. Search #product channel for story IDs (e.g., "SC-5318") or story keywords
2. Search #cs-product-feedback for related customer mentions
3. Note any customer names, urgency language, or timeline expectations
4. Add this context to the story's entry in the briefing

**This step enriches the briefing with real customer pressure signals — the exact thing that caught SC-5318.**

---

### Step 5: Build the Briefing

Use parallel agents where possible to speed up data gathering (Steps 1-4 can partially overlap).

Present the briefing in this format:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 SPRINT PREP — [Sprint Name] (ends [date])
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SPRINT HEALTH SNAPSHOT
  Stories: XX | Unowned: XX | Not started: XX
  Carried over: XX | Stale (7+ days): XX

──── PRIORITY TRIAGE (needs a decision before planning) ───

1. SC-XXXX — [Story Title]
   [Signal]: [details] | [Owner status] | [Estimate status]
   Context: [Customer mentions, related completed work, epic status]
   → Recommend: [Specific recommended action]

2. ...

──── REVIEW (trending toward stale) ────────────────────────

3. SC-XXXX — [Story Title]
   [Signal]: [details]
   → [Suggested check-in or action]

──── FULL INVENTORY ─────────────────────────────────────────

All flagged stories in a compact table:

| # | Story | Signal | Owner | Bounces | Last Update | Action |
|---|-------|--------|-------|---------|-------------|--------|
| 1 | SC-XXXX Title | Chronic bouncer | None | 9 | Dec 8 | Assign or defer |
| ... complete list, no cap ... |

──── BACKLOG ORPHANS ────────────────────────────────────────

Stories in "To Do" with no sprint, no owner, older than 30 days:

| Story | Age | Last Update | Epic |
|-------|-----|-------------|------|
| ... complete list ... |

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Formatting rules:**
- Priority Triage section: rich context + recommended action per story. No cap on items — show all Tier 1 flags.
- Review section: lighter context for Tier 2 items.
- Full Inventory: compact table with EVERY flagged story. Include Shortcut links.
- Backlog Orphans: complete list, sorted oldest first.
- Each recommended action should be specific and decisive: "Assign to [person]", "Move to backlog with customer comms", "Archive — superseded by SC-YYYY", "Needs grooming session", etc.

---

### Step 6: Create Obsidian Note

Create a note in the Obsidian vault for this sprint prep session.

**Location:** `/mnt/i/My Drive/NP-brain-backup/Projects/Slabstack/Sprint Prep/`

**Filename:** `YYYY-MM-DD Sprint Prep - [Sprint Name].md`

**Frontmatter:**
```yaml
---
created: YYYY-MM-DD
updated: YYYY-MM-DD
type: reference
project: slabstack
status: developing
tags:
  - slabstack
  - sprint-prep
  - backlog-health
related:
  - "[[Most recent prior sprint prep note]]"
---
```

**Content includes:**
- Full briefing content (same structure as conversation output)
- Every story ID is a clickable Shortcut link: `[SC-XXXX](https://app.shortcut.com/slabstack/story/XXXX)`
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

**If the Obsidian vault is not accessible** (I: drive not mounted), warn the user and skip the Obsidian note. Do NOT fail the entire command.

---

### Step 7: Summary

After presenting the briefing and creating the Obsidian note, provide:
- Total number of stories needing attention
- The single most urgent item to discuss first in planning
- The Obsidian note path (in Windows format for easy access)

---

## Important Notes

- **Delegate aggressively.** Use parallel sub-agents for Shortcut queries, Slack searches, and Obsidian note creation. The user is waiting for a briefing, not watching queries run.
- **All sub-agents MUST use `model: "sonnet"`.** Never use haiku.
- **Never update Shortcut** (no story edits, no comments, no status changes) unless explicitly instructed.
- **Context is king.** The value of this command over a dumb script is the cross-referencing: connecting a stale story to a Slack mention to a completed related epic. Invest time in making those connections.
- **Be opinionated in recommendations.** Don't just flag problems — suggest specific actions. "Assign to [person] based on their work on SC-YYYY" is better than "needs an owner."
- **Shortcut story links** format: `https://app.shortcut.com/slabstack/story/XXXX`
