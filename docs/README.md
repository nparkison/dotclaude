# Convention Docs

Convention docs are reference files that live in `.claude/docs/`. They are not README files for humans. They are written for Claude to read before it touches code.

## Why they exist

Claude infers conventions from whatever code it reads first. Read an old file, and it replicates old patterns. Read a migration helper that predates the current ORM, and it writes queries that way from then on. Convention docs break that dependency. Instead of letting Claude guess, you give it the canonical answer upfront.

They also capture institutional knowledge: the stuff that lives in a senior engineer's head. Why this table has that column name. Which files need a second set of eyes before any change. How API versioning actually works here. That knowledge exists whether you write it down or not. The question is whether Claude has access to it.

## Templates

Five templates are in `templates/`:

**`backend-conventions.md`**: API shapes, error handling patterns, database naming rules, ORM usage. Which response envelope your endpoints use. Whether you throw or return errors. How models are named relative to tables.

**`frontend-conventions.md`**: Component structure, state management approach, styling conventions. Where components live, how they are named, whether you colocate styles or separate them.

**`high-risk-files.md`**: Files that need extra care before any modification. What to check, what tests to run, who to notify. Auth middleware, billing logic, migration files, shared utilities with many callers.

**`change-protocols.md`**: Safe procedures for high-stakes operations. Database migrations, API versioning, feature flag lifecycles. Step-by-step so Claude doesn't improvise.

**`local-dev-setup.md`**: How to run the project locally. Seeding test data, running the test suite, environment variables that actually need to be set. This stops Claude from inventing setup steps.

## How to use them

Copy the templates to `.claude/docs/`, then fill in the specifics for your project. Delete any section that doesn't apply. An empty section is worse than no section because Claude will try to follow it.

Wire the docs into your CLAUDE.md with explicit read instructions:

```markdown
## Before touching code

Read these files at the start of every session:
- `.claude/docs/backend-conventions.md`
- `.claude/docs/high-risk-files.md`

For database or API changes, also read:
- `.claude/docs/change-protocols.md`
```

The explicit instruction matters. Claude does not automatically discover files in `.claude/docs/`. You have to tell it when to read them.

## Keeping them current

A convention doc that is out of date is worse than no doc. Claude will follow stale instructions with confidence.

Update convention docs in the same PR as the convention change. If you migrate from one ORM to another, the backend conventions doc changes in that PR. If you add a new high-risk file, it goes in `high-risk-files.md` before the PR merges.

The `update-docs` skill in this repo automates the reminder. It scans recent changes and flags any convention docs that may need updating based on what was modified.
