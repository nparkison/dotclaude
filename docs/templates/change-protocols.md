<!-- TEMPLATE: Copy this file to .claude/docs/ and fill in your project's specifics.
     Lines marked with {{}} are placeholders. Example content shows the expected format. -->

# Change Protocols: {{YOUR_REPO}}

Step-by-step checklists for specific types of changes. Follow these exactly. They exist because the same mistakes keep happening without them.

---

## Database Migrations

1. Create the migration: `{{MIGRATION_CREATE_COMMAND}}` (e.g., `npx prisma migrate dev --name add_user_preferences`)
2. Review the generated SQL before committing. Never commit a migration you did not read.
3. Write a corresponding rollback if your ORM supports it.
4. For tables with >1M rows, review `{{LARGE_TABLE_GUIDE}}` before adding indexes or altering columns.
5. Run the migration locally against a seed database, not just unit tests.
6. Add a brief comment in the migration file explaining the business reason.
7. Deploy migrations separately from application code when possible. Application code should tolerate both the old and new schema during the rollout window.

---

## API Versioning

When a change breaks existing API consumers (field removed, type changed, behavior altered):

1. Introduce the new behavior under a version prefix: `/api/v2/{{ENDPOINT}}`.
2. Keep the old endpoint alive for `{{DEPRECATION_WINDOW}}` (e.g., 90 days).
3. Add a `Deprecation` response header to the old endpoint pointing to the new one.
4. Update `{{API_CHANGELOG}}` with the change, the old behavior, the new behavior, and the migration path.
5. Notify `{{API_CONSUMER_CHANNEL}}` (e.g., external developer Slack, partner email list) before the old endpoint is removed.

Additive changes (new optional fields, new endpoints) do not require versioning.

---

## Feature Flags

New features that need gradual rollout go behind a flag. Do not ship unfinished behavior to production without one.

1. Add the flag to `{{FEATURE_FLAG_SYSTEM}}` (e.g., LaunchDarkly, Unleash, your own config table).
2. Default to `false` (off) in all environments unless the feature is safe to enable everywhere.
3. Gate the behavior in one place, not scattered across components.
4. Name flags clearly: `billing_v2_enabled`, not `new_thing` or `flag_123`.
5. Add the flag name and expected cleanup date to `{{FEATURE_FLAG_REGISTRY}}`.
6. Remove the flag and the old code path once the rollout is complete. Flags are not permanent config.

---

## Environment Variable Additions

Adding a new `process.env.SOMETHING`:

1. Add it to `.env.example` with a comment explaining what it is and where to get the value.
2. Add validation in `{{CONFIG_VALIDATION_FILE}}` so the app fails loudly at startup if the variable is missing. Silent `undefined` values cause confusing bugs.
3. Set the variable in all environments: local dev (`.env`), CI (`{{CI_SECRETS_LOCATION}}`), staging, production.
4. Update `{{DEPLOY_RUNBOOK}}` if the variable needs to be provisioned externally (API key, secret, etc.).
5. Never commit real secret values. Use a secrets manager reference or dummy value in committed files.

---

## Dependency Upgrades

Major version upgrades:

1. Read the migration guide for the package. Do not skip this.
2. Upgrade in a separate PR from feature work so the diff is reviewable.
3. Run the full test suite and fix failures before merging.
4. Check the bundle size impact for frontend dependencies: `{{BUNDLE_SIZE_COMMAND}}`.
5. Test in staging before production, especially for packages that touch auth, payments, or DB.

Patch and minor upgrades can be batched. Major upgrades are one package at a time.

---

## What to Replace

| Placeholder | Fill In With |
|---|---|
| `{{YOUR_REPO}}` | Your repository name |
| `{{MIGRATION_CREATE_COMMAND}}` | Your ORM's migration command |
| `{{LARGE_TABLE_GUIDE}}` | Internal doc or pt-online-schema-change docs |
| `{{DEPRECATION_WINDOW}}` | Your actual deprecation window |
| `{{API_CHANGELOG}}` | Path to changelog file or external doc |
| `{{API_CONSUMER_CHANNEL}}` | How you notify external API consumers |
| `{{FEATURE_FLAG_SYSTEM}}` | e.g., LaunchDarkly, Unleash, custom |
| `{{FEATURE_FLAG_REGISTRY}}` | Where flags and cleanup dates are tracked |
| `{{CONFIG_VALIDATION_FILE}}` | e.g., `src/config/index.ts` |
| `{{CI_SECRETS_LOCATION}}` | e.g., GitHub Actions Secrets, CircleCI env vars |
| `{{DEPLOY_RUNBOOK}}` | Link to deployment documentation |
| `{{BUNDLE_SIZE_COMMAND}}` | e.g., `npm run analyze` |
