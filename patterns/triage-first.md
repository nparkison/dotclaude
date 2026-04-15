# Triage-First: Search Before You Investigate

## Problem

When a bug comes in, the default behavior is to start investigating. Claude opens files, traces execution paths, reads through the relevant module, and writes up a root cause analysis. Twenty minutes later, you find out there's already a PR open for the fix. Jake's handling it this sprint.

That's not a hypothetical. It happens constantly.

The underlying issue is that *investigating feels productive*. You're moving, you're learning, you're building toward an answer. Searching a PM tool first feels passive by comparison. So both humans and AI agents skip it.

The cost: duplicate stories erode trust in the backlog. When the same bug shows up as three different tickets across three sprints, nobody knows which one is canonical, who owns it, or whether it's actually been fixed. The backlog becomes noise.

The cheapest possible check (a 30-second PM tool search) gets skipped because investigation has better psychological momentum.

## Pattern

When a bug or issue is reported, follow this order: **Search, then Report, then (maybe) Investigate.**

**Step 1: Search the PM tool immediately.** Run multiple queries in parallel. Don't just search by the exact symptom description. Search by feature area, by related component names, by error keywords. Cast a wide net before narrowing.

**Step 2: Report what you found.** If related stories exist, surface them with status, owner, link, and sprint context. Give the user enough to know whether this is already being handled. Present this *before* touching the codebase.

**Step 3: Investigate only if needed.** Only go into the codebase if:
- No existing story covers the issue, or
- The user explicitly asks for deeper analysis.

That third step is gated. It's not automatic.

The core insight: the most valuable question ("is this already known?") is also the cheapest to answer. Reversing the order means you answer the expensive question first and skip the cheap one entirely.

## Implementation

Wire the triage-first behavior into your CLAUDE.md so Claude follows it by default:

```markdown
## Bug/Issue Triage Workflow

When a bug or issue is reported, **always follow this order** before doing any
codebase investigation:

### Step 1: Search {{PM_TOOL}} First
Immediately search for existing stories matching the issue. Use multiple search
queries in parallel: by feature area, by symptom description, by related component.

### Step 2: Report Matches
If related stories exist, surface them immediately with: status, owner, link,
and sprint context.

### Step 3: Investigate Only If Needed
Only investigate the codebase if:
- No existing story covers the issue, OR
- The user explicitly asks for deeper analysis

When investigating, delegate to Explore agents. Do not investigate directly.
```

Replace `{{PM_TOOL}}` with your actual tool (Shortcut, Linear, Jira, GitHub Issues).

To make this automatic, pair it with the `triage` skill in `skills/developer/triage.md`. The skill automates the search-first behavior so you don't have to remember to ask. Invoking `/triage <report>` triggers the full workflow: parallel PM searches, structured results presentation, and a hard stop before any codebase investigation.

The parallel search step matters. Searching only for "export button broken" misses the ticket titled "Fix download timeout for large reports." Run 3-5 queries simultaneously: feature name, symptom description, affected data model, error keywords. The extra queries cost nothing and catch duplicates that a single-shot search would miss.

## Example

**User:** "The export button is broken for large datasets."

**Without triage-first:** Claude opens the export module, reads through the file download handler, traces the request lifecycle, identifies a timeout issue, writes up a root cause analysis. 20 minutes. User responds: "Yeah, we know. Jake's fixing it this sprint."

**With triage-first:**

```
Searching Linear for:
1. "export"
2. "large dataset"
3. "download timeout"
```

Results:

```
Found: ENG-847 "Fix export timeout for large reports"
Status: In Development
Owner: Jake Morrison
Priority: High
Sprint: Current

Matches the reported symptom. Should I investigate further or is this the issue?
```

User responds. No codebase investigation needed. Total time: under 2 minutes.

The win isn't just time saved on this one report. It's that the backlog stays clean. No duplicate ENG-903 "Export broken for big files" sitting next to ENG-847 with different owners and conflicting status.
