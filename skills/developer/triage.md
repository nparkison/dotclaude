---
name: triage
description: Bug/issue triage workflow - searches {{PM_TOOL}} FIRST before investigating codebase
scope: all
version: 1.0.0
---

# Triage Workflow

**Purpose:** Quickly determine if a reported bug/issue is already tracked in {{PM_TOOL}} before spending time on codebase investigation. This prevents duplicate work and provides fast "is this already known?" answers.

**When to use:** Whenever a bug or issue is reported via Slack, conversation, or any other channel.

---

## Workflow Steps

### Step 1: Understand the Issue

If the user's bug report is vague or lacks key details, ask clarifying questions BEFORE searching:

- **What's broken?** (Specific behavior, feature area, error message)
- **Who's affected?** (All users? Specific role? Specific customer?)
- **When did it start?** (Recent? Long-standing? After a specific deployment?)
- **How critical?** (Blocking work? Cosmetic? Data integrity concern?)
- **Steps to reproduce?** (If known)

**Example clarifying prompts:**
- "Can you describe what the user expected to happen vs what actually happened?"
- "Is this affecting all users or just specific accounts?"
- "Do you have the exact error message or a screenshot?"

Once you have enough context, proceed to Step 2.

---

### Step 2: Search {{PM_TOOL}} with Multiple Strategies

Search {{PM_TOOL}} using **multiple parallel queries** to cast a wide net. Use your PM tool's search API with different combinations of:

**Search Strategy A: Feature/Area Keywords**
- Search by the feature name or area (e.g., "pricing", "project dashboard", "quote approval")
- Include related technical terms (e.g., "aggregation", "calculation", "export")

**Search Strategy B: Symptom/Error Keywords**
- Search by the symptom or error message (e.g., "incorrect total", "missing data", "500 error")
- Include user-facing descriptions (e.g., "shows wrong number", "doesn't update", "blank screen")

**Search Strategy C: Affected Entity**
- Search by the data model or component affected (e.g., "projects", "materials", "labor costs")
- Include related entities that might be involved

**Example search approach:**
```
// Parallel searches for "project totals showing incorrect values"
1. Search: "project totals"
2. Search: "incorrect calculation"
3. Search: "aggregation"
```

**Important:**
- Exclude old completed/archived issues when possible
- Don't filter by status initially (may be In Progress, Backlog, etc.)
- Cast a wide net with 3-5 different search queries
- Fetch enough results to find matches without overwhelming

---

### Step 3: Present Findings

Review all search results and present **relevant matches** to the user with:

**For each matching issue:**
- **Issue ID** (e.g., "PROJ-1234")
- **Title** (full title from {{PM_TOOL}})
- **Status** (e.g., "In Progress", "Backlog", "Done")
- **Owner** (assignee name, or "Unassigned")
- **Priority** (if set)
- **Link** ({{PM_TOOL}} URL)
- **Relevance** (brief note on why this matches)

**Example presentation:**
```
Found 2 potentially related issues:

1. PROJ-1234: "Fix project total aggregation for multi-phase projects"
   Status: In Progress | Owner: Alice Johnson | Priority: High
   Link: [{{PM_TOOL}} issue URL]
   Relevance: Matches reported symptom of incorrect totals

2. PROJ-5678: "Material costs not updating in project summary"
   Status: Backlog | Owner: Unassigned | Priority: Medium
   Link: [{{PM_TOOL}} issue URL]
   Relevance: Same feature area (project calculations)
```

**If no matches found:**
```
No existing {{PM_TOOL}} issues found matching:
- "project totals"
- "incorrect calculation"
- "aggregation"

This appears to be a new/unreported issue.
```

---

### Step 4: Stop or Investigate (User Decision)

**If matches found:**
- Present findings and STOP
- Ask: "Does one of these issues cover the reported problem, or should I investigate further?"
- Let the user respond before proceeding

**If no matches found:**
- Present "no matches found" message
- Ask: "Should I investigate the codebase to understand the issue?"
- Wait for explicit approval before investigating

**If user requests investigation:**
- Spawn an **Explore** agent to investigate the codebase
- Focus on: relevant files, recent changes, potential causes, related functionality
- Summarize findings and suggest next steps (create new issue, confirm duplicate, provide workaround)

---

## Triage Decision Tree

```
Bug/Issue Reported
    ↓
Is report clear? → NO → Ask clarifying questions
    ↓ YES
Search {{PM_TOOL}} (3-5 parallel queries)
    ↓
Matches found? → YES → Present findings + STOP (ask user if investigation needed)
    ↓ NO
Present "no matches found"
    ↓
Ask: "Should I investigate codebase?"
    ↓
User approves? → YES → Delegate to Explore agent
    ↓ NO
DONE (user will handle or provide more context)
```

---

## Example Usage

### Invoke the skill:
```
/triage There's a report that project totals are showing wrong numbers
```

### What happens:
1. **Clarification** (if needed): "Can you provide more details? Which projects? What kind of wrong numbers (too high, too low, zero)? Any error messages?"
2. **Search {{PM_TOOL}}** (parallel):
   - Search: "project totals"
   - Search: "wrong numbers calculation"
   - Search: "aggregation bug"
3. **Present findings**: "Found PROJ-1234 'Fix project aggregation' (In Progress, owned by Alice)"
4. **Stop and ask**: "Does this issue cover the problem, or should I investigate further?"

---

## Success Metrics

- **Average triage time:** < 5 minutes (vs 15-30 min with codebase-first approach)
- **Duplicate discovery rate:** 60%+ of reported issues already tracked
- **Time savings:** 10-25 min per bug report (by finding existing issues immediately)

---

## Notes

- **Always search BEFORE investigating codebase** - this is the core principle
- **Multiple search strategies** increase likelihood of finding matches
- **Present findings immediately** - don't make the user wait for codebase investigation
- **Respect user's decision** - only investigate if no matches or user explicitly requests
- **Fast feedback loop** - user gets "is this known?" answer in minutes, not hours
