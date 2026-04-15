# Convention Docs: Teaching Claude How Your Codebase Works

## Problem

Every Claude session starts from zero. It has no memory of the last session, no awareness of the decisions your team made six months ago, and no idea which patterns in your codebase are canonical versus which ones are artifacts of a 2022 refactor that never fully landed.

Claude infers conventions from whatever code it reads first. If it reads an old controller that returns `{ success: true, result: ... }`, it'll write your new endpoint the same way. If it happens to read the one file your team uses as a reference implementation, you'll get great output. You can't control which files it reads, so you can't rely on inference.

Team knowledge is the harder problem. The senior engineer knows "never touch the billing migration files without a feature flag." That knowledge lives in their head. Claude doesn't have it, and it won't ask.

CLAUDE.md is the wrong place for this. CLAUDE.md is for behavioral instructions: how Claude should work, what tools to use, when to delegate. It's not a place to document your API response shape or your database naming conventions. Mixing the two makes CLAUDE.md hard to maintain and easy to ignore.

## Pattern

Maintain a set of convention documents in `.claude/docs/` that describe how your codebase works. These aren't README files for humans. They're reference material written for Claude to read before it touches a particular area of your code.

Reference these docs from CLAUDE.md so Claude knows they exist and when to consult them. Without the reference, Claude won't know to look.

Keep them current. An outdated convention doc is worse than no doc because Claude will confidently follow the wrong pattern. When your conventions change, update the docs in the same PR.

## Implementation

Start with the templates provided in this repo:

```
.claude/docs/
├── README.md
├── templates/
│   ├── backend-conventions.md
│   ├── frontend-conventions.md
│   ├── high-risk-files.md
│   ├── change-protocols.md
│   └── local-dev-setup.md
```

**`backend-conventions.md`**: API response format, error handling patterns, database naming conventions, ORM usage rules. If there's a pattern that should appear in every endpoint or service, it goes here.

**`frontend-conventions.md`**: Component structure, state management approach, styling patterns. Where do server state and client state live? What's the component file naming convention? What's the pattern for loading and error states?

**`high-risk-files.md`**: Files that need extra care before editing. Billing logic, authentication, database migrations, shared utilities with many dependents. For each one: what to check before modifying, what tests to run, who to notify. This is where you encode the institutional knowledge that usually lives in the senior engineer's head.

**`change-protocols.md`**: How to make specific types of changes safely. Database migrations (always reversible, always behind a feature flag). API versioning (how to add a new version without breaking old clients). Environment variable additions (what to update, what to document). These are the "how we do it here" instructions for high-consequence operations.

**`local-dev-setup.md`**: How to run the project locally, how to seed data, how to run tests, what environment variables are required. Claude uses this when it needs to verify something works rather than guessing.

### Wiring It Into CLAUDE.md

Add explicit references so Claude consults the docs before acting:

```markdown
## Codebase Conventions

Before modifying backend code, read `.claude/docs/backend-conventions.md`.
Before modifying frontend code, read `.claude/docs/frontend-conventions.md`.
Before editing any file in `src/billing/`, `src/auth/`, or `db/migrations/`,
read `.claude/docs/high-risk-files.md`.
```

The `update-docs` skill in this repo can help keep convention docs in sync after implementation work. Run it at the end of a session where conventions changed.

## Example

Your `backend-conventions.md` contains:

```markdown
## API Response Shape

All endpoints return:
{ "data": ..., "error": null, "meta": { "requestId": "..." } }

Errors return:
{ "data": null, "error": { "code": "VALIDATION_ERROR", "message": "...", "details": [...] } }

Never return raw exception messages in the error field.
Never use { success: true, result: ... }. That's a legacy pattern from pre-2023 code.
```

Claude reads this before writing a new endpoint. The new endpoint follows the convention. No explanation needed, no correction mid-session.

Without the convention doc: Claude reads `UserController.ts`, which was written before the standardization effort. It returns `{ success: true, user: ... }`. Claude replicates that shape in the new endpoint. Now you have another file perpetuating the old pattern, and the person reviewing the PR has to catch it.

The doc costs you 20 minutes to write. It saves you that correction on every future PR.
