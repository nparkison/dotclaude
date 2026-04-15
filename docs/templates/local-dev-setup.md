<!-- TEMPLATE: Copy this file to .claude/docs/ and fill in your project's specifics.
     Lines marked with {{}} are placeholders. Example content shows the expected format. -->

# Local Dev Setup: {{YOUR_REPO}}

Everything needed to run this project locally. Written for a new team member (or Claude) starting from a clean machine.

---

## Prerequisites

- Node.js `{{NODE_VERSION}}` (use `nvm use` if you have nvm)
- `{{DATABASE}}` running locally or via Docker (e.g., PostgreSQL 15, MySQL 8)
- `{{OTHER_SERVICES}}` if needed (e.g., Redis, Elasticsearch)

Install dependencies:

```bash
{{INSTALL_COMMAND}}
# e.g., npm install / pnpm install / yarn
```

---

## Environment Variables

Copy the example file and fill in your values:

```bash
cp .env.example .env
```

Required variables and where to get them:

| Variable | Description | Where to Get It |
|---|---|---|
| `DATABASE_URL` | Local DB connection string | Set to your local DB |
| `{{API_KEY_VAR}}` | {{THIRD_PARTY_SERVICE}} API key | `{{WHERE_TO_FIND}}` (e.g., team 1Password vault) |
| `{{SECRET_VAR}}` | Session signing secret | Any random string for local dev |

Ask `{{SECRETS_OWNER}}` for access to the team vault if you don't have it.

---

## Starting the App

```bash
# Start all services (app + any workers)
{{START_COMMAND}}
# e.g., npm run dev / docker-compose up / foreman start

# App runs at: {{LOCAL_URL}}
# e.g., http://localhost:3000
```

If you need to run services separately:

```bash
{{START_API_COMMAND}}    # API server
{{START_WORKER_COMMAND}} # Background job worker (if applicable)
{{START_WEB_COMMAND}}    # Frontend dev server (if monorepo)
```

---

## Database Setup

On first run, create and migrate the database:

```bash
{{DB_CREATE_COMMAND}}    # e.g., npx prisma db push / rails db:create db:migrate
{{DB_MIGRATE_COMMAND}}
```

To seed with test data:

```bash
{{DB_SEED_COMMAND}}
# e.g., npm run db:seed / rails db:seed
```

The seed script creates: `{{WHAT_SEED_CREATES}}` (e.g., an admin user at admin@example.com with password `password`, sample organizations, etc.)

---

## Running Tests

```bash
{{TEST_COMMAND}}              # full suite
{{TEST_WATCH_COMMAND}}        # watch mode during development
{{TEST_SINGLE_FILE_COMMAND}}  # e.g., npm test -- path/to/file.test.ts
```

Tests use `{{TEST_DATABASE}}` (e.g., a separate `_test` database, in-memory SQLite). The test database is reset before each run.

---

## Common Troubleshooting

**App won't start:** Check that all required `.env` variables are set. The app validates them at startup and logs which ones are missing.

**Database connection errors:** Confirm `{{DATABASE}}` is running: `{{DB_STATUS_COMMAND}}` (e.g., `pg_isready` or `redis-cli ping`).

**Port already in use:** `lsof -i :{{PORT}}` to find what's using the port. Kill the process or change `PORT` in your `.env`.

**Stale migrations:** Run `{{DB_MIGRATE_COMMAND}}` to apply any migrations added since you last pulled.

**Tests failing locally but passing in CI:** Check that your local `{{DATABASE}}` version matches `{{CI_DATABASE_VERSION}}`. Version mismatches cause subtle behavior differences.

---

## What to Replace

| Placeholder | Fill In With |
|---|---|
| `{{YOUR_REPO}}` | Your repository name |
| `{{NODE_VERSION}}` | e.g., `20.x` |
| `{{DATABASE}}` | e.g., PostgreSQL 15, MySQL 8 |
| `{{OTHER_SERVICES}}` | Redis, Elasticsearch, etc. or remove |
| `{{INSTALL_COMMAND}}` | e.g., `npm install` |
| `{{API_KEY_VAR}}` | Real env variable name |
| `{{THIRD_PARTY_SERVICE}}` | e.g., Stripe, Sendgrid, AWS |
| `{{WHERE_TO_FIND}}` | Where team members get the value |
| `{{SECRETS_OWNER}}` | Engineer or channel to ask |
| `{{START_COMMAND}}` | e.g., `npm run dev` |
| `{{LOCAL_URL}}` | e.g., `http://localhost:3000` |
| `{{DB_CREATE_COMMAND}}` | e.g., `npx prisma migrate dev` |
| `{{DB_SEED_COMMAND}}` | e.g., `npm run db:seed` |
| `{{WHAT_SEED_CREATES}}` | Describe seed data so devs know what to expect |
| `{{TEST_COMMAND}}` | e.g., `npm test` |
| `{{TEST_WATCH_COMMAND}}` | e.g., `npm test -- --watch` |
| `{{PORT}}` | Default port number |
| `{{CI_DATABASE_VERSION}}` | Version used in CI config |
