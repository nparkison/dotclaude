# Memory System

Claude Code has a built-in file-based memory system. This directory documents how to structure
and use it effectively across sessions.

## How It Works

Memory files live at `~/.claude/projects/<project-hash>/memory/`. Claude reads them at the start
of each session to restore context about the user, project state, and working preferences.

A `MEMORY.md` index file controls what gets loaded. Each line is a pointer to a memory file.
Claude reads the index every conversation, so keep it short.

## Memory Types

There are four types. Use the right one or the memory becomes noise.

**user** - Who the person is. Role, expertise, communication style, goals. Helps Claude calibrate
tone and depth. Does not decay.

```
Example: "user is a data scientist, comfortable with Python, new to React"
```

**feedback** - How to work with this person. Corrections and confirmations, both directions.
What to avoid and what worked well. Does not decay.

```
Example: "don't mock the database in integration tests; user wants real DB behavior"
```

**project** - Active work: goals, decisions, deadlines, open questions. Decays quickly.
Always include why, not just what, so Claude can judge whether it still applies.

```
Example: "merge freeze begins 2026-03-05 for mobile release; no new deps after 2026-03-01"
```

**reference** - Pointers to external systems. Where to find information that lives outside the
repo. Stable, rarely changes.

```
Example: "pipeline bugs tracked in Linear project INGEST, not GitHub issues"
```

## What NOT to Save

Memory is not a knowledge base. If the information already exists somewhere Claude can read,
don't duplicate it in memory. Specifically, do not save:

- Code patterns or architecture (read the actual code)
- Git history (use `git log`)
- Debugging solutions (the fix is in the diff)
- Anything already covered in `CLAUDE.md`
- Ephemeral task details (use todos/tasks instead)

Over-filled memory is worse than sparse memory. Claude has to parse everything it loads.

## File Format

Each memory file uses YAML frontmatter for metadata:

```markdown
---
name: descriptive name
description: one-line description used for relevance matching
type: user|feedback|project|reference
---

Content here.
```

The `description` field matters. Claude uses it to decide whether a memory is relevant to the
current task. Write it like a search query you'd use to find this file later.

## The MEMORY.md Index

`MEMORY.md` is an index, not a memory file itself. It is loaded into every conversation, so
every byte counts. Each entry is a single line under 150 characters pointing to a memory file.

```markdown
# Memory Index

- [user-context](./user-context.md): data scientist, new to React, prefers concise answers
- [test-preferences](./test-preferences.md): no DB mocks in integration tests
- [q1-goals](./q1-goals.md): migrate auth to Clerk by 2026-03-15
```

Do not add prose or explanations to `MEMORY.md`. The files themselves hold the detail.

## Rules for Good Memory Hygiene

**Check before writing.** Search existing memories before creating a new file. Duplicates cause
contradictions and waste context.

**Keep memories current.** A stale memory is actively harmful. When a project wraps up or a
preference changes, update or delete the file. Remove its entry from `MEMORY.md`.

**Verify before acting.** A memory saying "X exists" or "Y is configured" is a claim from a
past session. Verify it before relying on it. State changes; memory does not update itself.

**Use absolute dates.** Write `2026-03-05`, not "next Tuesday" or "in two weeks". Relative dates
become wrong the moment the session ends.
