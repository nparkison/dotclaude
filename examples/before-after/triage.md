# Triage: Search the PM Tool Before Touching the Codebase

> **Prompt:** "Users are reporting the search feature is slow"

## Without dotclaude

Claude goes straight to the code.

```
Claude: I'll investigate the search performance issue.

[Read] src/controllers/SearchController.ts
[Read] src/services/SearchService.ts
[Read] src/db/queries/search.ts

The main query is doing a full-text scan without leveraging the index on
`content_tsv`. Also, the controller awaits three sequential DB calls that
could be parallelized. Let me trace the full request lifecycle...

[Read] src/middleware/auth.ts
[Read] src/db/connection.ts
[Read] tests/search.test.ts
```

Twenty minutes later:

```
Claude: Root cause found. The search query in SearchService.ts joins four
tables without the composite index on (workspace_id, created_at). For
workspaces with >50k documents this causes a sequential scan. Estimated
fix: add the index and rewrite the join order.

Here's a migration and the updated query...
```

User: "Oh yeah, that's ENG-847. Jake's been working on it all week."

## With dotclaude

Claude searches the PM tool before opening a single file.

```
Claude: Before investigating, let me check if this is already tracked.

Task(Bash): "Search Linear for issues matching 'search', 'slow', 'performance',
  'query', 'latency'. Return title, status, owner, and URL for each match."
```

Thirty seconds later:

```
Search results:

ENG-847: "Optimize search query for large workspaces"
  Status: In Development
  Owner: Jake
  Priority: High
  Iteration: Current sprint
  Link: linear.app/your-org/issue/ENG-847

ENG-831: "Search returns stale results after bulk import"
  Status: Done
  Link: linear.app/your-org/issue/ENG-831

Claude: Looks like ENG-847 covers this exactly. Jake owns it and it's
already in the current sprint. Want me to pull up the details, or is
this enough context?
```

No codebase investigation. No duplicate root cause analysis. The useful
answer took 30 seconds instead of 20 minutes.

## What changed

- Default Claude treated the report as a signal to start an investigation.
  It read six files and produced a thorough analysis of a problem that was
  already known and already being fixed.
- With dotclaude, the Bug Triage Workflow fires first: search the PM tool
  before touching the codebase. The answer (ENG-847, Jake's on it) takes
  one tool call.
- The codebase investigation is not skipped permanently. If no ticket had
  matched, Claude would have proceeded to investigate. The rule is "search
  first," not "never investigate."
