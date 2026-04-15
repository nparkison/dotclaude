# Pre-Commit Safety Check

Runs comprehensive safety checks before committing code. This is the final safety gate before changes enter the repository.

## Purpose

Ensures schema, API, business logic, and UI changes have been properly analyzed and tested before commit. Prevents "forgot to check X" mistakes.

## When to Use

- Before committing schema changes (migrations, model updates)
- Before committing API changes (endpoints, contracts, integrations)
- Before committing business logic changes (pricing, approvals, calculations)
- Before committing high-risk file modifications
- Any time you want a final safety review before git commit

## Instructions

You are a **Safety Review Specialist** performing the final check before code enters the repository.

### Step 1: Identify Changed Files

Run git commands to understand what's being committed:

```bash
# Show current git status
git status

# Show names of all changed files (staged and unstaged)
git diff --name-only HEAD

# Show staged files only
git diff --cached --name-only
```

If nothing is staged, inform the user and ask if they want to stage files first.

### Step 2: Categorize Changes

Analyze the changed files and categorize them:

**Schema Changes:**
- Database migration files (`.sql`, `migrations/`, `schema.sql`)
- Model definitions that map to database tables
- Data model changes

**Business Logic Changes:**
- Pricing calculations
- Approval workflows
- Financial calculations
- Quote policies
- Revenue calculations
- Aggregation logic

**API Changes:**
- API endpoint handlers
- API contracts/schemas
- Request/response models
- External integration points
- GraphQL schemas

**UI Changes:**
- Frontend components
- Forms and validation schemas
- Styling changes
- User-facing interactions

**High-Risk Files:**
- Check if any changed files are listed in `.claude/docs/high-risk-files.md` (if present)
- Files containing critical financial queries
- Auto-generated files

### Step 3: Run Safety Checks by Category

For each category of change, run appropriate checks:

#### Schema Changes Checklist

If schema changes detected:

1. **Blast Radius Analysis:**
   - Ask: "Has blast radius analysis been performed for this schema change?"
   - Check if `.claude/docs/blast-radius-guide.md` was consulted this session
   - Verify: Have aggregation queries been identified? (SUM, COUNT, AVG, GROUP BY)
   - Verify: Have downstream consumers been identified?
   - Verify: Have views been updated if needed?

2. **Cross-System Checklist:**
   - Does this change affect: API responses, mobile app, external integrations, reporting?
   - Have TypeScript types been updated if schema changes?

3. **Migration Safety:**
   - Is the migration reversible (has DOWN migration)?
   - Does it handle existing data correctly?
   - Have you considered data volume and migration performance?

#### Business Logic Changes Checklist

If business logic changes detected:

1. **Downstream Impact:**
   - Have you identified all code that calls this function/method?
   - Have you checked for aggregation queries that depend on this logic?
   - Have you checked approval policies if relevant?

2. **Financial Safety:**
   - If pricing/revenue/financial: Is there a test covering the specific case?
   - Have you verified calculations with examples?
   - Have you checked reporting implications?

3. **Testing:**
   - Are there tests covering the changed logic?
   - Have you run the project test suite?

#### API Changes Checklist

If API changes detected:

1. **Compatibility:**
   - Is this change backward compatible?
   - Will mobile app still work?
   - Will external integrations break?
   - Have TypeScript types been updated?

2. **Versioning:**
   - Should this be a new API version?
   - Is deprecation needed for old endpoints?

3. **Documentation:**
   - Have API docs been updated (if applicable)?
   - Are request/response examples still accurate?

#### UI Changes Checklist

If UI changes detected:

1. **Shared Components:**
   - Have you identified components used in multiple places?
   - Have you tested all usage sites?

2. **Forms:**
   - Have form/validation schemas been updated?
   - Are error states handled?
   - Are empty states handled?

3. **UX Review:**
   - Has UX review been performed for user-facing features?
   - Does this match existing patterns users expect?

4. **Testing:**
   - Has this been tested in development environment?
   - Has mobile responsiveness been checked (if applicable)?

#### High-Risk Files Checklist

If high-risk files changed:

1. **Read Testing Mandate:**
   - Check `.claude/docs/high-risk-files.md` for specific testing requirements
   - Follow the testing protocol for this file

2. **Review Diffs Carefully:**
   - Show the actual diff for critical files
   - Highlight what changed and why
   - Verify changes are intentional

### Step 4: Run Tests

Run the project's test suite. Check `package.json`, `Makefile`, or project README for the correct test command. Common patterns:

```bash
# Node/TypeScript projects: check package.json scripts
npm test
# or
yarn test
# or
pnpm test

# Go projects
go test ./...

# Python projects
pytest

# For other projects: check README or CI configuration for the correct command
```

If tests fail, **STOP** and report failures. Do not proceed to commit.

If tests don't exist or can't be run, note this in the safety report.

### Step 5: Run Linters

Run appropriate linters for the changed files:

```bash
# For JavaScript/TypeScript
npx eslint [changed-files]
npx prettier --check [changed-files]

# For Go
gofmt -l [changed-files]
go vet ./...

# For Python
flake8 [changed-files]
black --check [changed-files]
```

If linting fails, **STOP** and report issues. Do not proceed to commit.

### Step 6: Review Diffs for Critical Files

If any of these critical files are changed (or equivalent in the current project), show the actual diff and review carefully:

- Files with financial calculations
- Files with aggregation queries
- Files with approval logic
- Files listed in `.claude/docs/high-risk-files.md`

Use:
```bash
git diff [file-path]
```

Highlight:
- What changed
- Why it changed
- Whether it aligns with the stated intention

### Step 7: Present Safety Checklist Summary

Create a comprehensive summary with checkboxes:

```markdown
## Pre-Commit Safety Report

### Changed Files
- [List all changed files with categorization]

### Schema Changes
- [ ] Blast radius analysis completed
- [ ] Aggregation queries identified
- [ ] Downstream consumers identified
- [ ] Views updated if needed
- [ ] Cross-system checklist completed
- [ ] Migration is reversible

### Business Logic Changes
- [ ] Downstream consumers identified
- [ ] Financial calculations verified
- [ ] Tests cover changed logic
- [ ] Approval policies checked

### API Changes
- [ ] Backward compatibility verified
- [ ] Mobile compatibility verified
- [ ] TypeScript types updated
- [ ] Versioning considered

### UI Changes
- [ ] Shared components identified
- [ ] Form/validation schemas updated
- [ ] UX review completed
- [ ] Mobile tested

### High-Risk Files
- [ ] Testing mandate followed
- [ ] Diffs reviewed carefully

### Tests & Linting
- [ ] Tests passed (or not applicable)
- [ ] Linting passed

### Overall Risk Assessment
**Risk Level:** [LOW / MEDIUM / HIGH / CRITICAL]

**Risk Factors:**
- [List any risk factors identified]

**Mitigation:**
- [List how risks are mitigated]

**Recommendation:**
- [PROCEED / REVIEW FURTHER / DO NOT COMMIT]
```

### Step 8: Ask for Approval

Based on the risk assessment:

- **LOW risk:** "Safety checks complete. Ready to commit?"
- **MEDIUM risk:** "Safety checks complete with medium risk factors. Please review the summary above. Proceed with commit?"
- **HIGH risk:** "⚠️ HIGH RISK CHANGES DETECTED. Review the summary carefully. Are you sure you want to commit?"
- **CRITICAL risk:** "🚨 CRITICAL RISK CHANGES DETECTED. It is strongly recommended to have additional review before committing. Proceed?"

Wait for explicit user approval before committing.

If user approves, proceed with commit using standard git workflow (do not run commit yourself - let the user or commit skill handle it).

If user declines, explain what should be addressed before the next attempt.

## Important Notes

- This is a comprehensive checklist, not all items apply to every commit
- Mark items as "N/A" if they don't apply to the current changes
- The goal is thoughtful review, not bureaucracy
- If something seems wrong or risky, raise it - better to catch issues now than after commit
- This skill should be used AFTER implementation and testing, but BEFORE git commit
- Do not automatically commit - always ask for approval first

## Risk Level Definitions

- **LOW:** Minor changes, well-tested, no schema/API/financial impact
- **MEDIUM:** Moderate changes, some downstream impact, tests present
- **HIGH:** Schema/API/financial changes, significant downstream impact, requires careful review
- **CRITICAL:** Changes to critical financial queries, schema changes affecting aggregations, breaking API changes

## Example Usage

```
User: "Run pre-commit safety check"

Claude:
1. Identifies changed files (git status, git diff)
2. Categorizes: "Found schema changes (2 files), business logic (1 file), UI (3 files)"
3. Runs safety checks:
   - Schema: Verifies blast radius was done, checks for aggregations
   - Business logic: Checks for tests, downstream consumers
   - UI: Verifies components, forms, UX review
4. Runs tests: "Tests passed ✓"
5. Runs linters: "Linting passed ✓"
6. Reviews critical file diffs: Shows diff for relevant critical file
7. Presents comprehensive safety report with risk assessment
8. Asks: "Overall risk: MEDIUM. Proceed with commit?"
```

## Success Metrics

- Zero commits without appropriate safety analysis
- 100% of risky changes reviewed before commit
- Zero "didn't run tests" commits
- Catch issues before they enter the repository

## Integration

This skill is the final gate in the workflow:

1. Planning: `/story`, `/plan-feature`, `/blast-radius`
2. Implementation: Code the changes
3. **Safety Check: `/pre-commit-safety`** ← You are here
4. Commit: `git commit` or `/commit`
5. Push: `git push`

---

**Remember:** It's much cheaper to catch issues before commit than after deployment. Be thorough.
