---
name: update-docs
description: Update .claude/docs/ reference documentation after implementation changes to prevent documentation drift
scope: all
version: 1.0.0
---

# Update Documentation Skill

**Purpose:** Maintain accuracy of `.claude/docs/` reference documentation after implementation changes. Prevents documentation drift by identifying affected docs, verifying accuracy, making surgical updates, and tracking changes with timestamps.

**When to use:** After implementing schema changes, API changes, business logic changes, or any change that affects project reference documentation.

---

## Instructions for Claude

When this skill is invoked, follow this workflow to update reference documentation:

### Step 1: Identify Affected Documentation

Based on the type of change implemented, determine which documentation files need updating:

**Change Type → Affected Docs Mapping:**

- **Database Schema Changes** (tables, columns, constraints, indexes)
  - `.claude/docs/blast-radius-guide.md` - Entity dependency maps
  - `.claude/docs/change-protocols.md` - Schema change procedures

- **High-Risk File Creation/Modification** (critical business logic, financial queries)
  - `.claude/docs/high-risk-files.md` - High-risk file registry
  - `.claude/docs/blast-radius-guide.md` - Critical query documentation

- **API Changes** (endpoints, request/response shapes)
  - `.claude/docs/blast-radius-guide.md` - API dependency maps
  - `.claude/docs/api-patterns.md` - API documentation (if exists)

- **Business Logic Changes** (pricing, margins, calculations)
  - `.claude/docs/blast-radius-guide.md` - Critical business logic paths
  - `.claude/docs/high-risk-files.md` - If involving critical financial files

- **Data Flow Changes** (new aggregations, reporting queries, integrations)
  - `.claude/docs/blast-radius-guide.md` - Critical data flow paths
  - `.claude/docs/change-protocols.md` - Data change verification procedures

- **New Shared Components** (UI components, hooks, utilities)
  - `.claude/docs/component-patterns.md` - Component documentation (if exists)
  - `.claude/docs/blast-radius-guide.md` - Shared component dependencies

**If unsure which docs are affected:**
- Ask the user: "What was implemented? I need to determine which reference docs to update."
- List potential docs based on change description
- Ask user to confirm which docs need updating

---

### Step 2: Read Current Documentation

For each identified doc file that exists:

1. **Read the entire file** to understand:
   - Overall structure and sections
   - Formatting conventions
   - Level of detail expected
   - Existing examples and patterns

2. **Identify the specific section(s)** to update:
   - Entity dependency maps (for schema changes)
   - High-risk file listings (for critical files)
   - Critical query documentation (for aggregations)
   - API endpoint lists (for API changes)
   - Critical data flow paths (for business logic)

**If a doc file doesn't exist:**
- Inform the user: "`.claude/docs/[filename]` doesn't exist in this project. Should I create it or skip this update?"
- Only create if user explicitly approves
- Use similar docs from other projects as templates

---

### Step 3: Verify Accuracy Using Grep

Before making any updates, verify the current state of the codebase to ensure accuracy:

**For file path references:**
```bash
# Verify file exists
ls -la [file_path]
```

**For line number references:**
```bash
# Show specific line to verify it contains expected content
sed -n '[line_number]p' [file_path]
```

**For dependency relationships:**
```bash
# Find all files that reference the entity
grep -r "[entity_name]" --include="*.go" --include="*.ts" --include="*.tsx" --include="*.sql"
```

**For new consumers (what's calling this?):**
```bash
# For database table: Find all queries
grep -r "FROM [table_name]\|JOIN [table_name]" --include="*.sql" --include="*.go"

# For API endpoint: Find all API calls
grep -r "[endpoint_path]" --include="*.ts" --include="*.tsx"

# For function: Find all imports/calls
grep -r "import.*[function_name]\|[function_name](" --include="*.ts" --include="*.tsx" --include="*.go"

# For component: Find all JSX usage
grep -r "<[ComponentName]" --include="*.tsx" --include="*.jsx"
```

**For aggregation queries (critical):**
```bash
# Find aggregations involving the entity
grep -r "SUM\|COUNT\|AVG\|GROUP BY" --include="*.sql" --include="*.go" | grep [entity_name]
```

**Document your verification:**
- Note which grep commands you ran
- Note which files/relationships you verified
- Note any NEW consumers discovered that aren't in the current docs

---

### Step 4: Make Surgical Updates

**Principles:**
- **Narrow scope:** Only update the specific section(s) affected by the change
- **Preserve structure:** Don't reorganize or reformat existing content
- **Maintain style:** Match existing formatting, tone, and level of detail
- **Be precise:** Use exact file paths, line numbers, and entity names

**Common update patterns:**

**A) Adding a new entity to dependency map:**
```markdown
### Entity: [entity_name]

**Consumers:**
- `[file_path]:[line_number]` - [description of usage]
- `[file_path]:[line_number]` - [description of usage]

**Critical Queries:**
- `[file_path]:[line_number]` - [query description, especially if aggregation]

**Downstream Impact:**
- [affected system/report/feature]

<!-- Updated: YYYY-MM-DD - Added new consumers after [change description] -->
```

**B) Adding a new high-risk file:**
```markdown
## [filename]

**Location:** `[full_file_path]`

**Risk Level:** [CRITICAL/HIGH/MEDIUM]

**Why High-Risk:**
- [specific reason, e.g., "Contains financial aggregation query"]
- [specific reason, e.g., "Drives all project cost calculations"]

**Testing Mandate:**
- [specific tests required before modifying]
- [verification steps required]

**Related Entities:**
- [entities/tables/components this file interacts with]

<!-- Updated: YYYY-MM-DD - Added to registry after [change description] -->
```

**C) Updating existing entity with new consumers:**
Find the existing entity section and add to the Consumers list:
```markdown
**Consumers:**
- `[existing_file]:[line]` - [existing description]
- `[existing_file]:[line]` - [existing description]
- `[new_file]:[line]` - [new description]  <-- ADD THIS

<!-- Updated: YYYY-MM-DD - Added [new_file] consumer after [change description] -->
```

**D) Updating line numbers after refactor:**
If files were refactored and line numbers changed:
```markdown
<!-- OLD: -->
- `projects.go:245` - product_agg_cte query

<!-- NEW: -->
- `projects.go:267` - product_agg_cte query

<!-- Updated: YYYY-MM-DD - Updated line numbers after [refactor description] -->
```

---

### Step 5: Add Update Comments with Timestamps

**At the bottom of each changed section**, add a timestamp comment:

```markdown
<!-- Updated: YYYY-MM-DD - [brief description of what changed] -->
```

**Examples:**
- `<!-- Updated: 2026-02-04 - Added materials table consumers after bulk import feature -->`
- `<!-- Updated: 2026-02-04 - Updated projects.go line numbers after refactor -->`
- `<!-- Updated: 2026-02-04 - Added quote_policy.go to high-risk files registry -->`

**Timestamp format:** Use `YYYY-MM-DD` (not full timestamp, just date)

**Description guidelines:**
- Brief (under 80 characters)
- Describes WHAT changed in the doc, not why it changed in code
- Helps future readers understand doc evolution
- Links to implementation if relevant ("after [feature name]")

---

### Step 6: Show Diff and Ask for Approval

**Before writing any files:**

1. **Show the diff** in a clear format:
```
File: .claude/docs/blast-radius-guide.md

CHANGES:
+ ### Entity: labor_items
+
+ **Consumers:**
+ - `projects.go:267` - product_agg_cte (aggregates labor costs)
+ - `reports/actuals.sql:45` - Actuals report labor section
+
+ **Critical Queries:**
+ - `projects.go:267` - SUM(labor_items.total_cost) - drives project cost totals
+
+ **Downstream Impact:**
+ - Project cost calculations (all projects)
+ - Financial reporting (actuals report)
+ - Client invoices (cost breakdowns)
+
+ <!-- Updated: 2026-02-04 - Added labor_items entity after labor tracking feature -->
```

2. **Summarize the changes:**
   - Which docs updated
   - Which sections modified
   - What information added/changed
   - What grep commands were run to verify accuracy

3. **Ask for approval:**
   "I've identified the necessary documentation updates shown above. The changes are accurate based on grep verification of the codebase. Should I apply these updates?"

4. **Wait for user response:**
   - User approves → Apply changes using Edit or Write tool
   - User rejects → Ask what needs to change
   - User requests revisions → Make adjustments and show new diff

**After applying changes:**
- Confirm which files were updated
- Show file paths for user reference
- Remind user that docs are now accurate

---

## Verification Checklist

Before showing the diff to the user, verify:

- [ ] File paths exist (ran `ls` to check)
- [ ] Line numbers are correct (ran `sed` to verify content)
- [ ] All consumers are listed (ran grep to find usages)
- [ ] New relationships are accurate (grep confirmed connections)
- [ ] Timestamps are in YYYY-MM-DD format
- [ ] Update comments describe what changed in the doc
- [ ] Changes preserve existing structure and style
- [ ] No formatting changes to unrelated sections
- [ ] Critical queries are flagged (especially aggregations)

---

## Example Workflow

### User invokes skill:
```
/update-docs I just implemented the labor_items table and need to update the blast radius guide
```

### Step 1: Identify affected docs
"Based on adding the `labor_items` table, I'll update:
- `.claude/docs/blast-radius-guide.md` (entity dependency map)

Should I also check `.claude/docs/change-protocols.md` for schema change procedures?"

### Step 2: Read current doc
Read `.claude/docs/blast-radius-guide.md` to understand structure and find entity dependency section.

### Step 3: Verify accuracy
```bash
# Find all consumers of labor_items
grep -r "labor_items" --include="*.sql" --include="*.go"
# Result: projects.go:267, reports/actuals.sql:45

# Find aggregations
grep -r "SUM\|COUNT\|AVG" --include="*.sql" --include="*.go" | grep labor_items
# Result: projects.go:267 has SUM(labor_items.total_cost)

# Verify line number
sed -n '267p' projects.go
# Result: confirms product_agg_cte query with labor_items
```

### Step 4: Make surgical update
Add new entity section with consumers, critical queries, downstream impact.

### Step 5: Add timestamp
`<!-- Updated: 2026-02-04 - Added labor_items entity after labor tracking feature -->`

### Step 6: Show diff and ask approval
Show proposed changes, summarize verification steps, ask for approval.

---

## Success Metrics

- **100% of reference docs updated** after relevant implementation changes
- **Zero stale file paths** in documentation (grep verification catches errors)
- **Zero stale line numbers** in documentation (sed verification ensures accuracy)
- **Discovery tax gradient maintained** (docs stay useful as codebase evolves)
- **Time savings:** 10-15 min per update (vs manual grep/edit/verify loop)

---

## Common Scenarios

### Scenario A: Schema Change (Adding Table)
**Docs to update:**
- `blast-radius-guide.md` - Add entity with consumers, queries, downstream impact
- `change-protocols.md` - Verify schema change procedures are current

**Key verifications:**
- Find all queries referencing new table
- Find all aggregations involving table
- Document critical financial implications

### Scenario B: High-Risk File Creation
**Docs to update:**
- `high-risk-files.md` - Add file to registry with risk level and testing mandate
- `blast-radius-guide.md` - Add critical query if file contains financial logic

**Key verifications:**
- Confirm file contains critical business logic
- Identify which calculations/reports depend on it
- Document required tests

### Scenario C: API Change (New Endpoint)
**Docs to update:**
- `blast-radius-guide.md` - Add API endpoint with consumers
- `api-patterns.md` - Document endpoint pattern (if doc exists)

**Key verifications:**
- Find all frontend code calling endpoint
- Find all external integrations using endpoint
- Document request/response shape

### Scenario D: Refactor (Files Moved/Lines Changed)
**Docs to update:**
- ALL docs referencing moved files or changed line numbers

**Key verifications:**
- Find all doc references to old paths
- Update with new paths
- Verify line numbers still point to correct code

---

## Notes

- **Part of Definition of Done:** For schema/API/business logic changes, updating docs is required before marking work complete
- **Prevents "stale rules are worse than no rules":** Inaccurate docs are more harmful than no docs
- **Grep-first approach:** Always verify with grep before updating
- **Surgical updates only:** Don't reorganize or reformat existing content
- **Timestamps track evolution:** Future readers can see when/why docs changed
- **User approval required:** Never update docs without showing diff first
- **Works across all projects:** Adapts to whatever `.claude/docs/` structure exists in current project
