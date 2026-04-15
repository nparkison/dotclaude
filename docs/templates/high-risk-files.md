<!-- TEMPLATE: Copy this file to .claude/docs/ and fill in your project's specifics.
     Lines marked with {{}} are placeholders. Example content shows the expected format. -->

# High-Risk Files: {{YOUR_REPO}}

These files need extra care before editing. Mistakes here cause customer-facing incidents, data loss, or security gaps. Read the checklist for each category before touching anything.

---

## Billing and Payments

**Files:** `{{BILLING_FILES}}` (e.g., `src/services/billing.ts`, `src/webhooks/stripe.ts`)

Before editing:
- Read the Stripe/{{PAYMENT_PROVIDER}} docs for any endpoint you are modifying.
- Check `{{BILLING_TEST_PATH}}` for existing test coverage. Add tests before changing logic.
- Never delete or reorder webhook event handlers. Stripe replays events; idempotency is critical.
- Test against the {{PAYMENT_PROVIDER}} sandbox before any production change.
- Notify `{{BILLING_OWNER}}` (e.g., #eng-billing Slack, or specific engineer) before merging.

Common pitfalls: off-by-one in proration calculations, webhook signature verification being skipped in test environments but not restored, currency rounding.

---

## Authentication and Authorization

**Files:** `{{AUTH_FILES}}` (e.g., `src/middleware/auth.ts`, `src/services/session.ts`, `src/lib/permissions.ts`)

Before editing:
- Run the full auth test suite: `{{AUTH_TEST_COMMAND}}` (e.g., `npm test -- --grep auth`).
- Any change to token signing, session expiry, or permission checks requires a second review.
- Do not log tokens, passwords, or session IDs. Check that new log statements do not include sensitive fields.
- If adding a new permission or role, update `{{PERMISSIONS_DOC}}` as well.
- Notify `{{SECURITY_OWNER}}` for any change that touches token validation or session management.

---

## Database Migrations

**Files:** `{{MIGRATIONS_PATH}}` (e.g., `db/migrations/`, `prisma/migrations/`)

Before editing:
- Migrations are permanent. They run in production and cannot be auto-rolled-back.
- Write a corresponding down migration unless your ORM does not support it.
- Column renames require a two-phase approach: add new column, deploy code that writes both, backfill, drop old column. Never rename in a single migration on a live table.
- Test the migration against a copy of production schema, not just the dev seed.
- Check for long-running lock risks on large tables. Use `{{LOCK_FREE_MIGRATION_GUIDE}}` if the table exceeds ~1M rows.

---

## Shared Utilities

**Files:** `{{SHARED_UTIL_FILES}}` (e.g., `src/lib/`, `src/utils/`, `packages/shared/`)

Before editing:
- These files are imported in many places. A behavior change here may be invisible in local tests but break unrelated features in production.
- Run the full test suite before committing: `{{FULL_TEST_COMMAND}}`.
- Search for all call sites before changing a function signature: `grep -r "functionName" src/`.
- Deprecate rather than remove. Add a `@deprecated` comment and a migration path before deleting.

---

## Environment and Configuration

**Files:** `{{CONFIG_FILES}}` (e.g., `.env.example`, `src/config/index.ts`, `infrastructure/`)

Before editing:
- `.env` files must never be committed. `.env.example` is the only committed reference.
- Adding a new required variable: update `.env.example`, `{{CONFIG_VALIDATION_FILE}}`, and the deployment runbook at `{{DEPLOY_RUNBOOK}}`.
- Infrastructure files (Terraform, Kubernetes, Docker Compose) go through `{{INFRA_REVIEW_PROCESS}}` before apply.

---

## What to Replace

| Placeholder | Fill In With |
|---|---|
| `{{YOUR_REPO}}` | Your repository name |
| `{{BILLING_FILES}}` | Actual file paths for billing code |
| `{{PAYMENT_PROVIDER}}` | e.g., Stripe, Braintree, Paddle |
| `{{BILLING_TEST_PATH}}` | Path to billing tests |
| `{{BILLING_OWNER}}` | Slack channel or engineer name |
| `{{AUTH_FILES}}` | Actual file paths for auth code |
| `{{AUTH_TEST_COMMAND}}` | Command to run auth tests |
| `{{PERMISSIONS_DOC}}` | Path to permissions reference doc |
| `{{SECURITY_OWNER}}` | Person or channel to notify |
| `{{MIGRATIONS_PATH}}` | Path to migration files |
| `{{LOCK_FREE_MIGRATION_GUIDE}}` | Internal doc or external link |
| `{{SHARED_UTIL_FILES}}` | Path to shared utilities |
| `{{FULL_TEST_COMMAND}}` | e.g., `npm test` or `pytest` |
| `{{CONFIG_FILES}}` | Config file paths |
| `{{CONFIG_VALIDATION_FILE}}` | Where env vars are validated at startup |
| `{{DEPLOY_RUNBOOK}}` | Link to deployment documentation |
| `{{INFRA_REVIEW_PROCESS}}` | e.g., "PR + approval from DevOps team" |
