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

- `/release-notes` — auto-detect the most recent promotion PR (checks open staging first, then recent merged prod)
- `/release-notes #7423` — specific PR number
- `/release-notes staging` — latest PR targeting `staging`
- `/release-notes prod` — latest merged PR targeting `main`

---

## Workflow

### Step 1: Identify the Promotion PR

Based on invocation:

**Auto-detect (no argument):**
```bash
# Check for open staging PR first (upcoming release)
gh pr list --repo slabstack/gravel --base staging --state open --json number,title,body,headRefName,createdAt --limit 5

# If no staging PR, get most recent merged prod PR
gh pr list --repo slabstack/gravel --base main --state merged --json number,title,body,mergedAt --limit 5
```

Filter for PRs matching the naming convention `[release:staging]` or `[release:prod]`. Ignore hotfix PRs (`[hotfix:*]`) unless they're the only option.

**Specific PR number:**
```bash
gh pr view {number} --repo slabstack/gravel --json number,title,body,headRefName,baseRefName,state,mergedAt,createdAt
```

**By target branch:**
```bash
# staging — latest open
gh pr list --repo slabstack/gravel --base staging --state open --json number,title,body --limit 5

# prod — latest merged
gh pr list --repo slabstack/gravel --base main --state merged --json number,title,body,mergedAt --limit 5
```

Tell the user which PR was selected. If auto-detect was used and multiple candidates exist, confirm before proceeding. For explicit arguments (`#XXXX`, `staging`, `prod`), proceed directly.

---

### Step 2: Extract Changes from the PR Body

The promotion PR body contains a `## Changes` section auto-populated by the `update-release-pr-description` GitHub Actions workflow. Each line follows:

```
[SC-XXXX](https://app.shortcut.com/slabstack/story/XXXX) - Story Title
```

Parse all lines from the `## Changes` section matching the `[SC-` pattern. Extract: story ID, Shortcut URL, story title.

**Fallback — if `## Changes` is missing, empty, or contains no SC ticket lines:**

This can happen for hotfix PRs, if the workflow hasn't run yet, or if the section contains only the placeholder `_No shortcut tickets found in PR comments_`. In any of these cases, fall back to git log:

```bash
git fetch origin
git log origin/{base}..origin/{head} --pretty=format:"%s" --no-merges
```

Extract `[SC-XXXX]` references from commit messages via regex, then fetch story titles from Shortcut API:
```bash
curl -s -H "Content-Type: application/json" -H "Shortcut-Token: $SHORTCUT_API_TOKEN" \
  "https://api.app.shortcut.com/api/v3/stories/{id}"
```

**Error handling:** If the Shortcut API returns a non-2xx status or `$SHORTCUT_API_TOKEN` is not set, warn the user and proceed with story titles from the PR body only (without enrichment).

---

### Step 3: Enrich with Shortcut Data

For each SC story extracted, fetch additional context from Shortcut API to enable grouping and categorization:

```bash
curl -s -H "Content-Type: application/json" -H "Shortcut-Token: $SHORTCUT_API_TOKEN" \
  "https://api.app.shortcut.com/api/v3/stories/{id}"
```

Extract:
- `story_type` — feature, bug, chore
- `epic_id` → fetch epic name for grouping
- `labels` — for categorization
- `description` — first paragraph, for richer context in notes

Group stories by epic. Stories without an epic go in an "Other Changes" group.

**Dispatch parallel sub-agents** (all `model: "sonnet"`) to fetch story details. Batch requests if >10 stories.

**Error handling:** If Shortcut API auth failed in Step 2 (missing token or non-2xx), skip this enrichment step entirely. Proceed with story titles only — group all stories under a flat "Changes" section instead of by epic.

---

### Step 4: Generate Internal Release Summary

```markdown
# Release Notes — YYYY-MM-DD

**PR:** [#XXXX](https://github.com/slabstack/gravel/pull/XXXX) ([release:staging] YYYY-MM-DD)
**Stories:** XX total (XX features, XX bugs, XX chores)

---

## [Epic Name]

- **[SC-XXXX](https://app.shortcut.com/slabstack/story/XXXX)** — Story Title *(feature)*
  [One-line summary: what changed and why, from story description or PR context]

- **[SC-XXXX](https://app.shortcut.com/slabstack/story/XXXX)** — Story Title *(bug fix)*
  [What was broken → what was fixed]

## [Another Epic]

...

## Other Changes

- **[SC-XXXX](https://app.shortcut.com/slabstack/story/XXXX)** — Story Title *(chore)*
  [Brief description]
```

**Tone:** Technical enough for engineers, readable enough for leadership. Every SC ID is a clickable Shortcut link.

---

### Step 5: Generate External Release Notes Draft

Rewrite the internal summary in customer-facing language:

```markdown
# What's New — YYYY-MM-DD

## [Feature Area Name]

[2-3 sentences describing the improvement in customer-facing language. Focus on the benefit to users, not the technical implementation. No internal references.]

## [Another Feature Area]

...

## Improvements & Fixes

- [Plain-language description of a bug fix and its user impact]
- [Another fix]
```

**Rules for external notes:**
- No Shortcut IDs, PR numbers, or internal references
- No technical jargon unless the customer would use that term
- Group by feature area (user-facing categories), not by epic name
- Skip chores entirely — customers don't care about refactors
- Only include bugs that were customer-visible
- Lead with value: what improved for the user, not what code changed

---

### Step 6: Output to All Destinations

**6a. Slack — Post the internal summary:**

1. Draft via the Slack MCP `slack_send_message_draft` tool (full tool name: `mcp__plugin_slack_slack__slack_send_message_draft`) to the designated channel
2. Present the draft for review
3. Send on approval via `slack_send_message` (full tool name: `mcp__plugin_slack_slack__slack_send_message`)

Default channel: DM to self for initial testing. Once validated, edit the skill file to hardcode #engineering or the preferred channel.

**Note:** If Slack MCP tools are not available in the session, skip Slack output and present the report in the conversation instead.

**6b. Obsidian — Archive both versions:**

Location: `/mnt/i/My Drive/NP-brain-backup/Projects/Slabstack/Releases/`
Filename: `YYYY-MM-DD Release Notes.md`

```yaml
---
created: YYYY-MM-DD
updated: YYYY-MM-DD
type: release-notes
project: slabstack
tags:
  - slabstack
  - release-notes
related:
  - "[[Most recent prior release note]]"
---
```

Include BOTH the internal summary and external draft in the same note, with clear `## Internal Summary` and `## External Draft` section headers.

Search the vault for the most recent prior release note in `Releases/` and add it to the `related` frontmatter using alias syntax: `"[[YYYY-MM-DD Release Notes|previous release (YYYY-MM-DD)]]"`.

**If the vault is not accessible:** Warn and skip.

**6c. Google Doc — External draft only (optional):**

If the user wants a Google Doc for the external version:

```bash
gemini -m flash "Create a Google Doc titled 'Slabstack Release Notes — YYYY-MM-DD' with the following content:

[external release notes text]

Format it with:
- A clear title header
- Section headers for each feature area
- Bullet points for fixes
- Professional, clean layout suitable for customer communication"
```

Ask the user before creating the Google Doc. Not every release needs an external doc.

**If Gemini CLI is not available:** Fall back to Obsidian-only output and note that the external draft is in the Obsidian note for manual copy.

---

### Step 7: Flag Significant Features for `/cs-doc`

After generating release notes, scan the stories for significance signals:
- An epic where ALL stories are now complete (epic completion)
- Stories with labels indicating customer impact (e.g., `customer-facing`, `high-impact`)
- Features that affect specific tenant configurations or feature flags
- Anything that changes user-visible behavior substantially

If significant features are found, suggest:
"SC-XXXX ([Story Title]) looks like a significant feature — run `/cs-doc SC-XXXX` to generate a CS feature doc?"

This is informational only — the user decides whether to invoke `/cs-doc`.

---

## Important Notes

- **Delegate aggressively.** Parallel sub-agents for Shortcut API enrichment.
- **All sub-agents MUST use `model: "sonnet"`.** Never use haiku.
- **Read-only.** Never modify PRs, stories, or any external state.
- **The promotion PR body is the primary data source.** The `update-release-pr-description` GitHub Actions workflow already enriches it with SC ticket data. Don't duplicate that work — parse what's already there.
- **Release cadence:** ~1-2 regular promotions/week. This skill targets regular promotions. CS auto-commits and hotfixes are not the primary target but can be processed if the user asks.
- **Two artifacts, two audiences.** Internal = engineers + leadership. External = customers. Keep them clearly separated.
- **Shortcut API auth:** `curl -s -H "Shortcut-Token: $SHORTCUT_API_TOKEN"` — there is NO Shortcut MCP.
- **Shortcut story links:** `https://app.shortcut.com/slabstack/story/XXXX`
- **GitHub repo:** `slabstack/gravel`
