# Blast Radius Analysis Skill

**Purpose:** Perform standalone blast radius analysis for any code change. Works universally across all projects by reading the project's blast radius guide and adapting to project-specific mappings when available.

---

## Instructions for Claude

When this skill is invoked, follow this workflow to perform comprehensive blast radius analysis:

### Step 1: Understand the Change

Ask the user to describe the proposed change if not already provided. You need:
- **What is being changed?** (database schema, API endpoint, business logic, UI component, etc.)
- **Why is it being changed?** (bug fix, new feature, refactor, optimization)
- **Specific details:** (table/column names, endpoint paths, component names, function names)

### Step 2: Read Framework and Project Context

Read the following files to understand how to perform the analysis:

1. **Project Blast Radius Guide (read if exists):**
   - Read your project's blast radius guide at `.claude/docs/blast-radius-guide.md` if it exists
   - This provides the universal questions, search patterns, risk assessment framework, and presentation template

2. **Project-Specific Mappings (read if exists):**
   - `.claude/docs/blast-radius-guide.md` (in current project directory)
   - If this file exists, use documented entity dependency maps, critical financial queries, critical data flow paths, and external integrations
   - If this file does NOT exist, proceed with codebase search (Step 3)

### Step 3: Identify Change Type and Apply Universal Questions

Based on the change description, categorize the change type:
- **Database Schema Change** (add/remove/modify tables, columns, constraints, indexes)
- **Data Cardinality Change** (1:1 → 1:N, new rows for existing entities)
- **Business Logic Change** (pricing, margins, costs, volumes, calculations)
- **API Change** (endpoints, response shape, request shape)
- **Shared Component Change** (UI components, hooks, utility functions)
- **Enum/Type/Constant Change** (adding/removing/renaming values)
- **Permission/Access Control Change** (who can see/edit what)
- **Aggregation Query Change** (SUM, COUNT, AVG, GROUP BY)

Apply the relevant **Universal Questions** from the framework guide for the change type.

### Step 4: Trace Dependencies

#### If project-specific mappings exist (`.claude/docs/blast-radius-guide.md`):
- Use documented entity dependency maps as starting point
- Use documented critical financial queries
- Use documented critical data flow paths
- Use documented external integrations
- Still perform grep searches to discover any NEW consumers not yet documented

#### If NO project-specific mappings exist:
- Use grep patterns to discover dependencies:
  - **Database changes:** Search for SELECT, INSERT, UPDATE, JOIN, aggregations (SUM, COUNT, AVG)
  - **API changes:** Search for fetch, axios, API client usage
  - **Component changes:** Search for imports, JSX usage
  - **Business logic changes:** Search for function calls, value references
  - **Integration changes:** Search for webhooks, batch jobs, scheduled tasks

### Step 5: Identify Downstream Consumers

Organize findings into these categories:

1. **Data Layer / Database**
   - Tables affected
   - Queries affected (with file paths)
   - Aggregations affected (with file paths)
   - Views/CTEs affected

2. **API / Integration Layer**
   - Endpoints affected
   - Consumers (mobile apps, webhooks, internal services)
   - Response shape changes (old → new)

3. **Business Logic**
   - Calculations affected (with file paths)
   - Workflows affected (user journeys)
   - Reports/Dashboards affected

4. **UI / Component Layer**
   - Components affected (with usage count)
   - Screens affected (user-facing pages)
   - State management changes

5. **External Systems**
   - Integrations affected (external systems)
   - Webhooks affected
   - Batch jobs affected (scheduled tasks)

### Step 6: Search for Aggregation Queries

**CRITICAL SAFETY CHECK:** Always search for aggregation queries that might be affected:

```bash
# Search for aggregations involving the changed entity
grep -r "SUM\|COUNT\|AVG\|GROUP BY" --include="*.sql" --include="*.go" --include="*.ts" | grep [entity_name]
```

**Cardinality change special attention:**
If the change involves cardinality (1:1 → 1:N), look for:
- Code assuming single value (`.First()`, array index `[0]`)
- Aggregations that might double-count (SUM over newly repeated data)
- UI components displaying single value vs. list

### Step 7: Check Critical Financial Queries (If Applicable)

If project-specific mappings document critical financial queries:
- Check if the change affects any documented critical financial queries
- Verify calculations remain accurate (pricing, margins, costs, commissions, tax)
- Verify historical data integrity (ensure past records aren't corrupted)

### Step 8: Trace Critical Paths (If Documented)

If project-specific mappings document critical data flow paths:
- Identify which critical paths the change touches
- Document all steps in the flow that consume the changed entity
- Flag integration points (external webhooks, APIs, batch jobs)

### Step 9: Assess Risk Level

Use the following risk assessment framework:

**CRITICAL** (Production incident risk):
- Financial calculations (pricing, margins, tax, commissions)
- Permission/access control logic
- Schema changes to tables with millions of rows
- API changes for external integrations (no version control)
- Cardinality changes without migration plan

**HIGH** (Data integrity risk):
- Schema changes to core business entities
- Aggregation query changes
- Business logic affecting workflows
- API changes for mobile apps

**MEDIUM** (Workflow disruption risk):
- UI changes to shared components
- Validation rule changes
- Feature flag changes
- Non-critical API changes (internal only)

**LOW** (Minimal risk):
- Pure styling changes
- New optional fields (no existing consumers)
- Logging additions
- Test-only changes

### Step 10: Present Analysis Using Standard Template

Present findings using this template:

```markdown
## Blast Radius Analysis: [Change Description]

### Summary
- **Change Type:** [Schema / API / Business Logic / UI / Integration]
- **Risk Level:** [CRITICAL / HIGH / MEDIUM / LOW]
- **Estimated Impact:** [# of files, # of systems, # of workflows]

### Proposed Change
[1-2 sentences describing what will change]

### Downstream Consumers

#### 1. Database / Data Layer
- **Tables affected:** [list]
- **Queries affected:** [list with file paths]
- **Aggregations affected:** [list with file paths]
- **Views/CTEs affected:** [list]

#### 2. API / Integration Layer
- **Endpoints affected:** [list]
- **Consumers:** [mobile app, webhooks, internal services]
- **Response shape changes:** [old → new]

#### 3. Business Logic
- **Calculations affected:** [list with file paths]
- **Workflows affected:** [list user journeys]
- **Reports/Dashboards affected:** [list]

#### 4. UI / Component Layer
- **Components affected:** [list with usage count]
- **Screens affected:** [list user-facing pages]
- **State management changes:** [Redux slices, context providers]

#### 5. External Systems
- **Integrations affected:** [list external systems]
- **Webhooks affected:** [list]
- **Batch jobs affected:** [list scheduled tasks]

### Risks Identified

#### CRITICAL
- [Risk description] → **Mitigation:** [strategy]

#### HIGH
- [Risk description] → **Mitigation:** [strategy]

#### MEDIUM
- [Risk description] → **Mitigation:** [strategy]

### Testing Plan

- [ ] Unit tests: [specific test cases]
- [ ] Integration tests: [API contracts, data flow]
- [ ] Manual QA: [user workflows to validate]
- [ ] Staging validation: [production-like scenarios]
- [ ] Performance testing: [if changing queries/indexes]

### Rollback Plan

- **How to detect failure:** [monitoring, alerts, user reports]
- **How to rollback:** [revert PR, feature flag toggle, database migration rollback]
- **Data recovery plan:** [if data changes are involved]

### Cross-System Verification Checklist

- [ ] Database migrations tested (up and down)
- [ ] API consumers notified (if external)
- [ ] Mobile app compatibility verified (if API change)
- [ ] Dashboards/reports validated (if calculation change)
- [ ] Webhooks tested (if integration change)
- [ ] Batch jobs tested (if scheduled task affected)
- [ ] Staging environment validated
- [ ] Monitoring/alerting configured
- [ ] Rollback plan documented and tested

### Recommendation

[Based on risk level, recommend next steps:]
- **CRITICAL/HIGH risk:** Requires cross-functional review, comprehensive testing, staged rollout
- **MEDIUM risk:** Requires code review + QA validation
- **LOW risk:** Standard code review + automated tests
```

### Step 11: Read Change Protocols (If Anything is AFFECTED)

If the analysis reveals ANY of the following are affected, read the corresponding change protocol:

**If database schema is affected:**
- Read `.claude/docs/change-protocols.md` (if exists in project)
- Or read universal database change best practices

**If API is affected:**
- Check for versioning strategy documentation
- Check for API contract documentation

**If financial calculations are affected:**
- Read financial change protocol (if documented)
- Flag for cross-functional review (PM + Engineering Lead + Finance)

**If external integrations are affected:**
- Read integration change protocol (if documented)
- Flag for notification to external parties

### Step 12: Document New Findings (If Applicable)

If this analysis discovered dependencies NOT documented in `.claude/docs/blast-radius-guide.md`:
- Inform the user that the project-specific guide should be updated
- Provide specific additions (new entity consumers, new critical queries, new integrations)
- Reference the `/update-docs` skill for maintaining documentation

---

## Expected Behavior

### Universal Adaptation (Any Project)
- **WITH project-specific mappings:** Use documented mappings as starting point, grep to verify and discover new consumers
- **WITHOUT project-specific mappings:** Use grep patterns exclusively, follow universal questions comprehensively

### Discovery Tax Gradient
- **First analysis (no mappings):** 20-30 minutes (full grep-based discovery)
- **With documented mappings:** 5-10 minutes (use mappings + verify with grep)
- **Over time:** Documentation grows richer, analyses become faster

### Risk-Based Blocking
- **CRITICAL risk:** Present analysis and ask user to confirm they understand the risks before proceeding
- **HIGH risk:** Present analysis and recommend cross-functional review
- **MEDIUM/LOW risk:** Present analysis and proceed with standard workflow

---

## Common Change Scenarios

### Example 1: Database Column Addition
**Change:** Adding `delivery_notes` column to `orders` table

**Analysis steps:**
1. Find queries reading `orders` table (SELECT)
2. Find queries writing to `orders` table (INSERT, UPDATE)
3. Find views/CTEs using `orders`
4. Find API endpoints returning order data
5. Find UI components displaying order data
6. Assess: Is this optional? Are consumers safe with optional chaining?

**Typical risk:** MEDIUM (new optional field, unlikely to break existing code)

### Example 2: Cardinality Change
**Change:** Projects can now have multiple delivery addresses (1:1 → 1:N)

**Analysis steps:**
1. Find code assuming single address (`.First()`, `project.address` direct access)
2. Find aggregations involving projects (GROUP BY address might double-count)
3. Find UI displaying address (designed for single value?)
4. Find API consumers expecting single address
5. Find external systems receiving address data

**Typical risk:** CRITICAL (code assumptions break, aggregations corrupt, UI needs redesign)

### Example 3: Business Logic Change
**Change:** Modifying margin calculation formula

**Analysis steps:**
1. Find dashboards/reports displaying margins
2. Find workflows using margin (approval thresholds)
3. Find aggregations (SUM, AVG of margins)
4. Find external systems receiving margin data
5. Check if historical data should remain unchanged

**Typical risk:** CRITICAL (financial data, affects reports and workflows)

### Example 4: API Response Shape Change
**Change:** Renaming field `total` to `total_price` in `/api/orders` response

**Analysis steps:**
1. Find all consumers of this API (mobile app, internal services, webhooks)
2. Check if consumers use optional chaining (safe) or direct access (breaks)
3. Check API versioning strategy (can we keep both fields temporarily?)
4. Check TypeScript types that need updating

**Typical risk:** HIGH (breaking change for external consumers) or MEDIUM (if versioned API)

### Example 5: Shared Component Change
**Change:** Adding required prop to `Button` component

**Analysis steps:**
1. Find all usages of `Button` component (grep for imports and JSX usage)
2. Count number of usages
3. Check if making prop required breaks existing usages
4. Check if prop has sensible default

**Typical risk:** MEDIUM (many usages, but TypeScript will catch missing props)

---

## Tips for Effective Analysis

1. **Start broad, narrow down:** Use grep to cast a wide net, then filter to relevant results
2. **Include file paths and line numbers:** Makes it easy for developers to find and update consumers
3. **Quantify impact:** "Affects 12 files, 3 dashboards, 1 external integration" is more actionable than "affects multiple systems"
4. **Provide mitigation strategies:** Don't just identify risks, suggest how to mitigate them
5. **Consider phased rollout:** For high-risk changes, suggest feature flags or staged deployment
6. **Think about edge cases:** What happens to historical data? What happens on rollback?
7. **Don't over-analyze:** LOW risk changes don't need exhaustive analysis. Focus effort on HIGH/CRITICAL risks

---

## Integration with Other Skills

This skill is invoked by:
- `/story` skill (Step 3: when story involves schema/API/cardinality/business logic changes)
- `/plan-feature` skill (Step 5: when architecture involves risky changes)
- `/pre-commit-safety` skill (validates that blast radius analysis was performed before commit)

This skill can invoke:
- `/update-docs` skill (if new dependencies discovered that should be documented)

---

## Success Metrics

After using this skill, you should be able to answer:
- What files need to be updated? (with specific paths)
- What tests need to be run? (with specific test cases)
- What workflows need to be validated? (with specific user journeys)
- What is the risk level? (CRITICAL/HIGH/MEDIUM/LOW)
- What is the rollback plan? (specific steps)

If any of these questions can't be answered, the analysis is incomplete.

---

## Notes

- This skill is designed to work in ANY codebase
- The universal questions ensure comprehensive coverage even without pre-documented mappings
- Project-specific documentation makes analyses faster over time (discovery tax gradient)
- For CRITICAL/HIGH risk changes, always recommend cross-functional review
- Always err on the side of caution. It's better to over-analyze than to miss a critical dependency
