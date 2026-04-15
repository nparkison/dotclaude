---
name: release-notes
description: Auto-generate internal + external release notes from promotion PR data
scope: all
version: 1.0.0
---

# Release Notes

**Purpose:** Generate human-readable release notes from the data that already exists on promotion PRs, so you never scramble to produce them.

**When to use:** When a promotion is about to happen or just happened. Invoke manually as part of the release process.

---

## Usage

- `/release-notes`: auto-detect the most recent promotion PR (checks open staging first, then recent merged prod)
- `/release-notes #7423`: specific PR number
- `/release-notes staging`: latest PR targeting `staging`
- `/release-notes prod`: latest merged PR targeting `main`

---

## Workflow

### Step 1: Identify the Promotion PR

Based on invocation:

**Auto-detect (no argument):**
```bash
# Check for open staging PR first (upcoming release)
gh pr list --repo {{YOUR_ORG}}/{{YOUR_REPO}} --base staging --state open --json number,title,body,headRefName,createdAt --limit 5

# If no staging PR, get most recent merged prod PR
gh pr list --repo {{YOUR_ORG}}/{{YOUR_REPO}} --base main --state merged --json number,title,body,mergedAt --limit 5
```

Filter for PRs matching your project's promotion PR naming convention (e.g., `[release:staging]` or `[release:prod]`; adapt these patterns to match your team's conventions). Ignore hotfix PRs unless they're the only option.

**Specific PR number:**
```bash
gh pr view {number} --repo {{YOUR_ORG}}/{{YOUR_REPO}} --json number,title,body,headRefName,baseRefName,state,mergedAt,createdAt
```

**By target branch:**
```bash
# staging: latest open
gh pr list --repo {{YOUR_ORG}}/{{YOUR_REPO}} --base staging --state open --json number,title,body --limit 5

# prod: latest merged
gh pr list --repo {{YOUR_ORG}}/{{YOUR_REPO}} --base main --state merged --json number,title,body,mergedAt --limit 5
```

Tell the user which PR was selected. If auto-detect was used and multiple candidates exist, confirm before proceeding. For explicit arguments (`#XXXX`, `staging`, `prod`), proceed directly.

---

### Step 2: Extract Changes from the PR Body

If your project uses an automated workflow to populate the PR body with a `## Changes` section, parse all story/ticket references from that section. Each line may follow a pattern like:

```
[PROJ-XXXX](https://your-pm-tool.com/story/XXXX) - Story Title
```

Extract: ticket ID, PM tool URL, story title.

**Fallback: if `## Changes` is missing, empty, or contains no ticket lines:**

This can happen for hotfix PRs, if the workflow hasn't run yet, or if the section contains only a placeholder. Fall back to git log:

```bash
git fetch origin
git log origin/{base}..origin/{head} --pretty=format:"%s" --no-merges
```

Extract ticket ID references from commit messages via regex, then fetch story titles from your PM tool's API:
```bash
# Replace with your PM tool's story fetch endpoint
curl -s -H "Content-Type: application/json" -H "{{PM_TOOL}}-Token: $PM_API_TOKEN" \
  "https://api.your-pm-tool.com/api/v3/stories/{id}"
```

**Error handling:** If the PM tool API returns a non-2xx status or `$PM_API_TOKEN` is not set, warn the user and proceed with story titles from the PR body only (without enrichment).

---

### Step 3: Enrich with PM Tool Data

For each story extracted, fetch additional context from your PM tool's API to enable grouping and categorization:

```bash
curl -s -H "Content-Type: application/json" -H "{{PM_TOOL}}-Token: $PM_API_TOKEN" \
  "https://api.your-pm-tool.com/api/v3/stories/{id}"
```

Extract:
- `story_type`: feature, bug, chore
- `epic_id` → fetch epic name for grouping
- `labels`: for categorization
- `description`: first paragraph, for richer context in notes

Group stories by epic. Stories without an epic go in an "Other Changes" group.

**Dispatch parallel sub-agents** (all `model: "sonnet"`) to fetch story details. Batch requests if >10 stories.

**Error handling:** If PM tool API auth failed in Step 2 (missing token or non-2xx), skip this enrichment step entirely. Proceed with story titles only: group all stories under a flat "Changes" section instead of by epic.

---

### Step 4: Generate Internal Release Summary

```markdown
# Release Notes: YYYY-MM-DD

**PR:** [#XXXX](https://github.com/{{YOUR_ORG}}/{{YOUR_REPO}}/pull/XXXX) ([release:staging] YYYY-MM-DD)
**Stories:** XX total (XX features, XX bugs, XX chores)

---

## [Epic Name]

- **[PROJ-XXXX](https://your-pm-tool.com/story/XXXX)** - Story Title *(feature)*
  [One-line summary: what changed and why, from story description or PR context]

- **[PROJ-XXXX](https://your-pm-tool.com/story/XXXX)** - Story Title *(bug fix)*
  [What was broken, and what was fixed]

## [Another Epic]

...

## Other Changes

- **[PROJ-XXXX](https://your-pm-tool.com/story/XXXX)** - Story Title *(chore)*
  [Brief description]
```

**Tone:** Technical enough for engineers, readable enough for leadership. Every ticket ID is a clickable PM tool link.

---

### Step 5: Generate External Release Notes Draft

Rewrite the internal summary in customer-facing language:

```markdown
# What's New: YYYY-MM-DD

## [Feature Area Name]

[2-3 sentences describing the improvement in customer-facing language. Focus on the benefit to users, not the technical implementation. No internal references.]

## [Another Feature Area]

...

## Improvements & Fixes

- [Plain-language description of a bug fix and its user impact]
- [Another fix]
```

**Rules for external notes:**
- No ticket IDs, PR numbers, or internal references
- No technical jargon unless the customer would use that term
- Group by feature area (user-facing categories), not by epic name
- Skip chores entirely. Customers don't care about refactors
- Only include bugs that were customer-visible
- Lead with value: what improved for the user, not what code changed

---

### Step 6: Output to All Destinations

**6a. Slack: Post the internal summary:**

1. Draft via the Slack MCP tool to the designated channel (`{{SLACK_CHANNEL}}`)
2. Present the draft for review
3. Send on approval

Default channel: DM to self for initial testing. Once validated, edit the skill file to hardcode the preferred channel.

**Note:** If Slack MCP tools are not available in the session, skip Slack output and present the report in the conversation instead.

**6b. Obsidian: Archive both versions:**

Location: `{{OBSIDIAN_VAULT}}/Releases/`
Filename: `YYYY-MM-DD Release Notes.md`

```yaml
---
created: YYYY-MM-DD
updated: YYYY-MM-DD
type: release-notes
tags:
  - release-notes
related:
  - "[[Most recent prior release note]]"
---
```

Include BOTH the internal summary and external draft in the same note, with clear `## Internal Summary` and `## External Draft` section headers.

Search the vault for the most recent prior release note in `Releases/` and add it to the `related` frontmatter using alias syntax: `"[[YYYY-MM-DD Release Notes|previous release (YYYY-MM-DD)]]"`.

**If the vault is not accessible:** Warn and skip.

**6c. External Document: External draft only (optional):**

If the user wants an external document (e.g., Google Doc) for the external version, use your preferred document creation tool. Ask the user before creating it, as not every release needs an external doc.

If no external document tool is available: Fall back to Obsidian-only output and note that the external draft is in the Obsidian note for manual copy.

---

### Step 7: Flag Significant Features for `/cs-doc`

After generating release notes, scan the stories for significance signals:
- An epic where ALL stories are now complete (epic completion)
- Stories with labels indicating customer impact (e.g., `customer-facing`, `high-impact`)
- Features that affect specific tenant configurations or feature flags
- Anything that changes user-visible behavior substantially

If significant features are found, suggest:
"PROJ-XXXX ([Story Title]) looks like a significant feature. Run `/cs-doc PROJ-XXXX` to generate a CS feature doc?"

This is informational only. The user decides whether to invoke `/cs-doc`.

---

## Important Notes

- **Delegate aggressively.** Parallel sub-agents for PM tool API enrichment.
- **All sub-agents MUST use `model: "sonnet"`.** Never use haiku.
- **Read-only.** Never modify PRs, stories, or any external state.
- **The promotion PR body is the primary data source.** If your CI/CD pipeline auto-populates the PR body with ticket data, parse what's already there rather than duplicating that work.
- **Two artifacts, two audiences.** Internal = engineers + leadership. External = customers. Keep them clearly separated.
- **PM tool API auth:** `curl -s -H "{{PM_TOOL}}-Token: $PM_API_TOKEN"`. Adapt the auth header to match your PM tool's API documentation.
- **GitHub repo:** `{{YOUR_ORG}}/{{YOUR_REPO}}`
