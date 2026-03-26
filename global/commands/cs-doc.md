---
name: cs-doc
description: Generate internal CS-facing feature documentation for significant shipped features
scope: all
version: 1.0.0
---

# CS Feature Doc

**Purpose:** When a significant feature ships, generate an internal CS-facing document explaining what it does, who it affects, and how to talk about it. Designed for the customer success team — no technical jargon, all customer language.

**When to use:** After a significant feature ships. Invoked manually or suggested by `/release-notes` when it flags notable features.

---

## Usage

- `/cs-doc SC-XXXX` — generate CS doc for a specific Shortcut story
- `/cs-doc epic:XXXX` — generate CS doc for an entire Shortcut epic (covers all stories in the epic)
- `/cs-doc` — prompted to provide a story or epic ID

---

## Workflow

### Step 1: Gather Context (Parallel)

Dispatch parallel sub-agents (all `model: "sonnet"`) to gather context from four sources simultaneously:

**Agent A — Shortcut Context:**

For a story:
```bash
curl -s -H "Content-Type: application/json" -H "Shortcut-Token: $SHORTCUT_API_TOKEN" \
  "https://api.app.shortcut.com/api/v3/stories/{id}"
```

For an epic:
```bash
curl -s -H "Content-Type: application/json" -H "Shortcut-Token: $SHORTCUT_API_TOKEN" \
  "https://api.app.shortcut.com/api/v3/epics/{id}"
curl -s -H "Content-Type: application/json" -H "Shortcut-Token: $SHORTCUT_API_TOKEN" \
  "https://api.app.shortcut.com/api/v3/epics/{id}/stories"
```

Extract: name, description, story type, labels, epic info, comments (for context notes), linked stories, workflow state.

**Error handling:** If `$SHORTCUT_API_TOKEN` is not set or the API returns a non-2xx status, abort and report the error to the user. Shortcut context is essential for this skill — it cannot proceed without it.

**Agent B — Related PRs:**

Search GitHub for merged PRs linked to the story/epic:
```bash
# Search by SC ID in PR titles and bodies
gh pr list --repo slabstack/gravel --state merged --search "SC-{id}" --json number,title,body,mergedAt --limit 20
```

Extract from PR bodies: technical context, screenshots, before/after descriptions, testing notes. These often contain the best feature descriptions.

**Agent C — Design Docs:**

Search the product planning repo for related design documents. Use the Grep tool (not bash grep) for reliability:

Search for `{feature keywords}` in path `~/work/clients/Slabstack/product/product-planning/` with glob `*.md`.

Also search the Obsidian vault for related notes:

Search for `SC-{id}` in path `/mnt/i/My Drive/NP-brain-backup/Projects/Slabstack/` with glob `*.md`.

Read any matched files for additional context about the feature's purpose, requirements, and design decisions.

**Agent D — Tenant Impact:**

Check feature flags to identify which tenants are affected. Use the Grep tool (not bash grep) for reliability:

Search for `{feature_name}` in path `cmd/gravel/featureflags/` with glob `*.{yml,go}`.

If a relevant feature flag is found, read the flag config file (likely `cmd/gravel/featureflags/flags_by_tenant.yml` or similar) to determine:
- Which tenants have the feature enabled
- Whether it's globally enabled or per-tenant
- Whether it's behind a flag at all (some features ship without flags)

---

### Step 2: Generate the CS Doc

Synthesize all gathered context into this structure:

```markdown
# [Feature Name] — CS Feature Doc

**Ship date:** YYYY-MM-DD
**Shortcut:** [SC-XXXX](https://app.shortcut.com/slabstack/story/XXXX) | [Epic: Name](https://app.shortcut.com/slabstack/epic/XXXX)
**Status:** Shipped to [staging / production]

---

## What Changed

[2-4 paragraphs in plain language. What does this feature do? What problem does it solve for customers? What's different from how things worked before?]

[If there are before/after screenshots from PR descriptions, reference or describe the visual changes.]

## Who It Affects

**Rollout:**

| Tenant | Status |
|--------|--------|
| [Tenant A] | Enabled |
| [Tenant B] | Enabled |
| All others | [Not yet / Behind feature flag / Available on request] |

[Or simply "All tenants — no feature flag, shipped globally" if applicable.]

## How to Talk About It

**Elevator pitch:**
> [1-2 sentence pitch suitable for a customer call or email]

**Key benefits:**
- [Benefit 1 — in customer language, focused on their workflow improvement]
- [Benefit 2]
- [Benefit 3]

**Suggested talking points for customer conversations:**
- [When the customer asks about X, highlight Y]
- [If they're on the old workflow, explain the migration path]
- [Good context for upsell or expansion conversations]

## Known Limitations

- [Limitation 1 — anything that doesn't work yet or has edge cases]
- [Limitation 2 — pulled from PR descriptions, story notes, or testing feedback]
- [What is NOT included in this release that customers might expect]

## FAQ

**Q: [Anticipated customer question — based on the feature's scope and limitations]**
A: [Clear, customer-friendly answer]

**Q: [Another likely question]**
A: [Answer]

**Q: [Edge case or "what about..." question]**
A: [Answer]

---

*Generated from [SC-XXXX](url) on YYYY-MM-DD.*
```

**Writing guidelines:**
- Write for people who talk to customers daily. They're smart but not engineers.
- Lead with impact: what improved for the customer, not what code changed.
- If you're unsure about a detail, flag it with `[VERIFY: ...]` rather than guessing.
- Known limitations section is critical — CS needs to know what to set expectations around.
- FAQ should anticipate real customer questions, not softballs. Think about edge cases and "what about..." scenarios.

---

### Step 3: Present for Review

Before creating outputs, present the full CS doc to the user for review.

Specifically ask:
- "Does the feature description accurately capture what shipped?"
- "Any tenants I should add or remove from the rollout list?"
- "Any known limitations or FAQ items to add?"
- "Ready to create the Google Doc and post to Slack?"

Wait for approval before proceeding to outputs.

---

### Step 4: Output to All Destinations

**4a. Google Doc (primary — shareable with CS team):**

```bash
gemini -m flash "Create a Google Doc titled '[Feature Name] — CS Feature Doc (YYYY-MM-DD)' with the following content:

[full CS doc text — the approved version from Step 3]

Format it professionally:
- Use Google Docs heading styles (H1 for title, H2 for sections)
- Use tables where specified
- Bullet points for lists
- Blockquote for the elevator pitch
- Clean, professional layout suitable for internal team documentation"
```

Present the Google Doc link to the user.

**If Gemini CLI is not available or fails:** Skip the Google Doc and note that the Obsidian copy is the primary artifact. Ask the user if they want to manually create the Google Doc from the Obsidian note.

**4b. Obsidian archive:**

Location: `/mnt/i/My Drive/NP-brain-backup/Projects/Slabstack/CS Feature Docs/`
Filename: `YYYY-MM-DD [Feature Name].md`

```yaml
---
created: YYYY-MM-DD
updated: YYYY-MM-DD
type: cs-doc
project: slabstack
tags:
  - slabstack
  - cs-doc
  - feature-doc
related:
  - "[[YYYY-MM-DD Release Notes|release notes]]"
  - "[[Any matched design docs from Agent C]]"
---
```

Include the full CS doc content. Every SC ID should be a clickable Shortcut link. Cross-link to the release notes that included this feature and any design docs found during context gathering.

**If the vault is not accessible:** Warn and skip.

**4c. Slack notification:**

Draft a short notification message linking to the Google Doc (or Obsidian note if Google Doc was not created):

```
New CS Feature Doc: [Feature Name]
Doc: [Google Doc link OR Obsidian path]
Shortcut: SC-XXXX
[One-line summary of what shipped and who it affects]
```

1. Draft via the Slack MCP `slack_send_message_draft` tool (full tool name: `mcp__plugin_slack_slack__slack_send_message_draft`) to the CS-relevant channel
2. Present for review
3. Send on approval via `slack_send_message` (full tool name: `mcp__plugin_slack_slack__slack_send_message`)

Default channel: #cs-team (change this in the skill file once you've identified the right channel).

**Note:** If Slack MCP tools are not available in the session, skip Slack output and present the notification in the conversation instead.

---

## Important Notes

- **Delegate aggressively.** Parallel sub-agents for all 4 context sources.
- **All sub-agents MUST use `model: "sonnet"`.** Never use haiku.
- **Read-only.** Never modify stories, PRs, feature flags, or any external state.
- **Customer language always.** The entire doc (except the header metadata) should be written for people who talk to customers. No SC IDs in the body text. No code references. No API mentions.
- **Present for review before creating outputs.** Unlike `/monitors` and `/release-notes` which surface raw data, CS docs require product judgment. Always get user approval on the content.
- **Flag uncertainty.** If context is insufficient to write a section confidently, use `[VERIFY: ...]` markers rather than guessing. A wrong CS doc is worse than an incomplete one.
- **Shortcut API auth:** `curl -s -H "Shortcut-Token: $SHORTCUT_API_TOKEN"` — there is NO Shortcut MCP.
- **Product repo:** `~/work/clients/Slabstack/product/` — separate from the dev repo at `~/work/clients/Slabstack/repo/`
- **Gemini CLI:** Required for Google Doc creation. Must be authenticated with Google Workspace extension active. If not available, Obsidian is the fallback primary output.
