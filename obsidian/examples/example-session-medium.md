---
date: 2025-03-18
type: session-log
tags:
  - claude-session
  - acme-app
  - bugfix
session_id: b7d42e91-0c3a-4f56-82b7-1e9f3a6d5c08
cwd: /home/user/projects/acme-app
git_branch: fix/auth-timeout
claude_version: 2.1.95
---

# The test for token expiry keeps failing intermittently

**Date:** 2025-03-18
**Duration:** 18m
**Turns:** 6
**Working Dir:** `/home/user/projects/acme-app`
**Branch:** `fix/auth-timeout`

**Related:** [[Acme App Architecture]], [[Testing Conventions]]

## Conversation

**User (1):** The test for token expiry keeps failing intermittently. Here is the error: `AssertionError: expected 200 but got 401`. It is in `src/middleware/__tests__/auth.test.ts`.

*Tools: Read*

> Looking at the test file, the failing test is `"should accept a valid token within its expiry window"`. The test creates a JWT with a 1-second expiry, waits 500ms, then fires the request and expects a 200.
>
> The intermittent failure pattern -- sometimes 200, sometimes 401 -- is a classic sign of a race condition against wall-clock time. If the test runner is under load, the 500ms wait can drift past the 1-second expiry before the request completes...

**User (2):** So the expiry window is just too tight?

*Tools: Read, Grep*

> Yes, that is the root cause. The test was written assuming near-instant execution, but in CI the gap between token creation and request arrival can exceed 1 second under load.
>
> I also found a secondary issue: `verifyJwt` uses `Date.now()` for expiry comparison, but the JWT is signed with `iat` in seconds (standard JWT), not milliseconds. The division by 1000 is there but happens after the comparison in one branch, which means expiry is evaluated as if it were 1000 seconds in the future on the first check...

**User (3):** Wait, that sounds like a real bug, not just a test problem. Can you show me exactly where in verifyJwt this happens?

*Tools: Read*

> Here is the relevant section from `src/lib/jwt.ts` around line 34:
>
> ```typescript
> const now = Date.now();
> if (payload.exp < now) {   // bug: payload.exp is in seconds, now is in ms
>   return null;
> }
> const nowSeconds = Math.floor(now / 1000);
> ```
>
> The `payload.exp < now` comparison is the bug. A token with `exp = 1710000060` (a Unix timestamp in seconds) gets compared against `now = 1710000060000` (milliseconds). The token will always appear expired by a factor of 1000. The fact that auth ever works at all is because the catch block is returning `null` and the middleware... [truncated]

**User (4):** OK fix both the bug in verifyJwt and update the test so it is not flaky.

*Tools: Read, Edit, Edit*

> Fixed both issues.
>
> In `src/lib/jwt.ts`, line 34 now reads:
> ```typescript
> const nowSeconds = Math.floor(Date.now() / 1000);
> if (payload.exp < nowSeconds) {
>   return null;
> }
> ```
>
> In `src/middleware/__tests__/auth.test.ts`, the expiry for the "valid token" test case is changed from `1` to `60` seconds. The 500ms artificial wait is removed entirely -- the test no longer needs to simulate time passing; it just checks that a freshly issued token is accepted.

**User (5):** Run the tests and make sure they pass.

*Tools: Bash*

> All tests pass:
>
> ```
> PASS src/middleware/__tests__/auth.test.ts
>   auth middleware
>     should accept a valid token (12ms)
>     should reject an expired token (8ms)
>     should reject a missing token (5ms)
>     should reject a malformed token (6ms)
>
> Test Suites: 1 passed, 1 total
> Tests:       4 passed, 4 total
> Time:        1.842s
> ```

**User (6):** Great. What is the best commit message for this?

> Here is a suggested message:
>
> ```
> fix: correct JWT expiry comparison from ms to seconds
>
> verifyJwt was comparing payload.exp (Unix seconds) against Date.now()
> (milliseconds), causing tokens to always appear expired. Fixed the
> comparison to use Math.floor(Date.now() / 1000).
>
> Also increased test token TTL from 1s to 60s to eliminate flakiness
> from timing variance in CI.
> ```

## Tools Used

- **Read**: 4x
- **Edit**: 2x
- **Grep**: 1x
- **Bash**: 1x

## Files Touched

- `/home/user/projects/acme-app/src/lib/jwt.ts`
- `/home/user/projects/acme-app/src/middleware/__tests__/auth.test.ts`

## Raw Transcript

[Raw JSONL](_raw/b7d42e91-0c3a-4f56-82b7-1e9f3a6d5c08.jsonl)
