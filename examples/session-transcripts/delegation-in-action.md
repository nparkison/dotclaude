# Delegation in Action: Investigating a Flaky Test Suite

> This is a scrubbed excerpt from a real Claude Code session demonstrating
> the delegation-first pattern. Names, paths, and project details have been
> genericized.

---

**You:** the integration tests for the payments module keep failing intermittently in CI. can you figure out whats going on

**Claude:** On it. I'll investigate in parallel across the three likely problem areas at once: the test file itself, the payments module, and the CI config. No point reading them serially.

`[Spawning Explore agent 1: "Examine src/payments/__tests__/integration.test.ts in acme-app. Look for timing dependencies, shared state between tests, missing teardown, or anything that would cause non-deterministic failures."]`

`[Spawning Explore agent 2: "Examine src/payments/ in acme-app. Focus on: singleton instances, module-level state, database connection handling, and any async patterns that might leave open handles between tests."]`

`[Spawning Explore agent 3: "Examine .github/workflows/ci.yml and any Jest config files in acme-app. Look for parallelism settings, test isolation flags, retry logic, and environment variable handling in CI vs local."]`

Waiting on all three agents now.

---

`[Explore agent 1 returned]`
`[Explore agent 2 returned]`
`[Explore agent 3 returned]`

Here is what the three agents found:

**Test file (agent 1):** The tests share a single `paymentClient` instance initialized in `beforeAll`. There is no reset between tests. Two tests mutate `paymentClient.config.retryCount` directly and never restore it, which means test order affects outcomes.

**Payments module (agent 2):** `src/payments/client.ts` holds a module-level `activeRequests` Set. Tests that trigger errors leave entries in this Set if the error path does not call `cleanup()`. The Set is never cleared between tests.

**CI config (agent 3):** The workflow runs Jest with `--runInBand` locally but with `--maxWorkers=4` in CI. This means tests that pass locally in a fixed order can interleave differently in CI. Also, the `PAYMENT_MOCK_URL` env var is set in `.env.test` but not in the CI workflow file, so some tests may be hitting a real endpoint.

**Root causes, ranked by likelihood:**

1. Missing `PAYMENT_MOCK_URL` in CI workflow (would explain total failures, not just flakiness)
2. Shared `activeRequests` Set with no cleanup (explains intermittent state corruption)
3. Mutated `retryCount` with no teardown (explains order-dependent failures under parallel workers)

Want me to fix all three? I can spawn an implementation agent with a concrete patch, or walk through the changes first if you want to review the approach.

---

**You:** fix all three, just do it

**Claude:** Spawning an implementation agent with full context from the investigation.

`[Spawning general-purpose agent: "Fix three issues in acme-app's payments integration tests. (1) Add PAYMENT_MOCK_URL to .github/workflows/ci.yml env block. (2) Add afterEach in src/payments/__tests__/integration.test.ts to clear the activeRequests Set via paymentClient.cleanup(). (3) Save and restore retryCount in the two tests that mutate it. Full findings from investigation attached."]`

`[Implementation agent returned]`

Done. Changes made:

- `.github/workflows/ci.yml`: `PAYMENT_MOCK_URL` added to the `env` block under the test step
- `integration.test.ts`: `afterEach(() => paymentClient.cleanup())` added after `beforeAll`
- `integration.test.ts`: `retryCount` saved to a local variable before each mutating test and restored in `afterEach`

Run `npm test -- --testPathPattern=payments` locally to verify before pushing.
