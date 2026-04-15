<!-- TEMPLATE: Copy this file to .claude/docs/ and fill in your project's specifics.
     Lines marked with {{}} are placeholders. Example content shows the expected format. -->

# Backend Conventions: {{YOUR_REPO}}

Quick reference for anyone writing server-side code in this codebase. When in doubt, find an existing example and match it.

---

## API Response Format

All endpoints return a consistent envelope. Do not invent new top-level keys.

```json
// Success
{ "data": { ... }, "meta": { "page": 1, "total": 42 } }

// Error
{ "error": { "code": "RESOURCE_NOT_FOUND", "message": "User 123 does not exist" } }
```

HTTP status codes follow REST semantics: 200 OK, 201 Created, 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 422 Unprocessable Entity, 500 Internal Server Error.

---

## Error Handling

Errors are typed. Never throw raw strings or generic `Error` objects.

```ts
// {{YOUR_REPO}}/src/errors.ts
throw new AppError("PAYMENT_DECLINED", "Card ending in 4242 was declined", 422);
```

All unhandled errors bubble to the global error middleware at `{{PATH_TO_ERROR_MIDDLEWARE}}`. Do not swallow errors silently; log and rethrow if you can't handle locally.

Validation errors use `{{VALIDATION_LIBRARY}}` (e.g., Zod, Joi). Return 422 with field-level detail.

---

## Database Naming

- Tables: plural snake_case (`user_accounts`, `payment_intents`)
- Columns: snake_case (`created_at`, `stripe_customer_id`)
- Indexes: `idx_{{table}}_{{column}}` (e.g., `idx_users_email`)
- Foreign keys: `fk_{{child_table}}_{{parent_table}}`

ORM: `{{ORM_NAME}}` (e.g., Prisma, Drizzle, TypeORM). All queries go through the ORM. Raw SQL is allowed only for complex reporting queries and must be in `{{PATH_TO_RAW_QUERIES}}`.

---

## Service Layer Pattern

Business logic lives in services. Controllers handle HTTP concerns only (parsing, responding). Services are pure functions or classes with no direct HTTP dependencies.

```
src/
  controllers/   # parse request, call service, return response
  services/      # business logic, DB access
  repositories/  # optional: wraps DB calls if service gets complex
```

A controller method should not exceed ~20 lines. If it does, move logic to a service.

---

## Background Jobs

Jobs use `{{JOB_QUEUE}}` (e.g., BullMQ, Sidekiq). Job files live in `{{PATH_TO_JOBS}}`. Each job must be idempotent. Use exponential backoff with a max of 5 retries. Log job start, completion, and failure.

---

## What to Replace

| Placeholder | Fill In With |
|---|---|
| `{{YOUR_REPO}}` | Your repository name |
| `{{PATH_TO_ERROR_MIDDLEWARE}}` | e.g., `src/middleware/errorHandler.ts` |
| `{{VALIDATION_LIBRARY}}` | e.g., Zod, Joi, class-validator |
| `{{ORM_NAME}}` | e.g., Prisma, Drizzle, TypeORM |
| `{{PATH_TO_RAW_QUERIES}}` | e.g., `src/db/raw/` |
| `{{JOB_QUEUE}}` | e.g., BullMQ, Sidekiq, Celery |
| `{{PATH_TO_JOBS}}` | e.g., `src/jobs/` |
