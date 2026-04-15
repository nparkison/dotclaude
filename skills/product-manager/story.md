# Story Writing Skill

Create well-structured user stories following the project's story writing guide.

## Core Workflow

1. Read project-specific story writing guide
2. Ask clarifying questions
3. Run blast radius analysis (if technical change)
4. Draft story following guide template
5. Present story + technical considerations separately
6. Create in {{PM_TOOL}} only after explicit approval

**Design work (UX Expert) is opt-in only - never automatic.**

---

## Instructions

### Step 1: Read Story Writing Guide

Read `.claude/docs/story-writing-guide.md` in the current project and follow its guidelines.

If the file doesn't exist, use standard story structure: Title, Business Context, User Story, Acceptance Criteria, Out of Scope.

---

### Step 2: Ask Clarifying Questions

**Required:**
1. **Who** is this for? (persona/role)
2. **What** are they trying to accomplish?
3. **Why** does this matter? (business value)
4. **Design references?** (mockups, wireframes, examples)

**Additional based on context:**
- Feature type? (new feature, enhancement, bug fix, technical task)
- Specific acceptance criteria or edge cases?
- Known constraints or dependencies?
- Priority/urgency?

**Do not proceed without clear answers to required questions.**

---

### Step 3: Run Blast Radius Analysis (if needed)

**Automatic blast radius analysis if the story involves:**
- Database schema changes (add/remove/modify tables, columns, constraints, indexes)
- Data cardinality changes (1:1 → 1:N relationships, new rows for existing entities)
- Business logic changes (pricing, margins, costs, volumes, tax, commissions, delivery fees)
- API response shape changes (add/remove/rename fields, change types)
- Aggregation query modifications (SUM, COUNT, AVG, GROUP BY)
- Shared component modifications (if widely used)
- Permission/access control changes

**Skip blast radius if:**
- Simple content changes (text, labels, styling)
- Backend-only changes with no downstream impact
- Trivial bug fixes with obvious, isolated fixes

**Delegate analysis:**
```
Task(Explore): "Perform blast radius analysis for [change description].

Follow framework from `.claude/docs/blast-radius-guide.md` if it exists.

**Required Analysis:**
1. **Data Layer:** What queries read/write this? What joins on this? What aggregations use this?
2. **API Layer:** Who consumes this? What response shape do they expect?
3. **Business Logic:** What calculations use this? What workflows depend on this?
4. **UI Layer:** What components display this? What state management is involved?
5. **Cross-System:** What external integrations, webhooks, batch jobs are affected?

**Search Patterns:**
- Use Grep to find all references to affected tables/columns/endpoints/functions
- Check for aggregation queries (SUM, COUNT, AVG, GROUP BY)
- Check for foreign key relationships and JOINs
- Check for API consumers (fetch, axios calls)
- Check for component usage (imports, JSX)

**Deliverables:**
1. List of all downstream consumers (with file paths and line numbers)
2. Risk assessment (CRITICAL/HIGH/MEDIUM/LOW)
3. Identified risks and mitigation strategies
4. Testing plan
5. Rollback plan (if CRITICAL or HIGH risk)

Present findings in standard blast radius format."
```

**Important:** Blast radius findings are presented SEPARATELY to the user - not automatically included in the story draft. The user decides what (if anything) to include.

---

### Step 4: Draft Story

Follow the template from `.claude/docs/story-writing-guide.md`:

**Required sections:**
- **Title:** Action-oriented, user perspective (e.g., "Allow dispatchers to assign multiple trucks to a quote")
- **Business Context:** 2-3 sentences (who/what pain/what it unlocks)
- **User Story:** As a [role], I want [capability] so that [benefit]
- **Acceptance Criteria:** Observable outcomes only (not implementation steps)
- **Out of Scope:** What this story does NOT cover

**Optional sections:**
- **Design References:** Links to Figma, wireframes, mockups
- **Technical Constraints:** Only non-obvious hard constraints (e.g., "Must work offline", "Cannot break existing API contract")

**NEVER include in story body:**
- Database schemas or migration details
- API endpoint specs or payload shapes
- File paths or module references
- Step-by-step implementation instructions
- Code snippets or pseudocode
- Detailed blast radius findings

**Refer to story-writing-guide.md for anti-patterns and what to avoid.**

---

### Step 5: Present for Review

Present the story draft and technical considerations SEPARATELY:

```markdown
# Story Draft: [Title]

**Title:** [Action-oriented title]

**Business Context:**
[2-3 sentences from story writing guide format]

**User Story:**
As a [role],
I want [capability],
So that [benefit].

**Acceptance Criteria:**
- [ ] [Observable outcome 1]
- [ ] [Observable outcome 2]
- [ ] [Observable outcome 3]

**Out of Scope:**
- [What this does NOT cover]

**Design References:** [Links if provided]

---

## Technical Considerations to Review
[Only if blast radius was performed]

**Risk Level:** [CRITICAL/HIGH/MEDIUM/LOW]

**Affected Systems:**
- [System 1: file/path:line]
- [System 2: file/path:line]
- [System 3: file/path:line]

**Key Risks:**
1. [Risk description]
2. [Risk description]

**Mitigation Strategies:**
- [Mitigation approach 1]
- [Mitigation approach 2]

**Testing Plan:**
- [Testing requirement 1]
- [Testing requirement 2]

**Rollback Plan:** [If CRITICAL/HIGH risk]

---

**You decide:** Which (if any) technical details should be added to the story?

Ready to create in {{PM_TOOL}}? (Reply "yes" to create, or provide feedback for revisions)
```

**Do not create the story in {{PM_TOOL}} yet. Wait for explicit user approval.**

---

### Step 6: Create in {{PM_TOOL}} (only after approval)

Once user explicitly approves ("yes", "approve", "create it"):

1. Create the story in {{PM_TOOL}} using the available API or MCP tool
2. Include only the story content the user approved (may include technical details they selected)
3. Set appropriate labels if requested
4. Confirm creation with a {{PM_TOOL}} story link

**If user provides feedback or requests changes:**
- Make revisions
- Re-present for approval
- Repeat until approved

**If user says "not yet" or "hold off":**
- Acknowledge and do not create in {{PM_TOOL}}

---

## Special Cases

### HIGH or CRITICAL Risk Stories

If blast radius analysis identifies HIGH or CRITICAL risk:

**Stop and notify user immediately:**
```
⚠️ HIGH RISK STORY DETECTED

Blast radius analysis indicates this change has HIGH/CRITICAL risk:
- [Primary risk]
- [Secondary risk]

Recommended actions before proceeding:
- [Mitigation strategy 1]
- [Mitigation strategy 2]

Do you want to:
1. Proceed with mitigation plan
2. Revise scope to reduce risk
3. Cancel story creation
```

**Do not proceed without explicit user acknowledgment.**

### Stories Without Enough Information

If user provides vague or incomplete requirements:

1. **Do not guess or assume**
2. **Ask specific follow-up questions:**
   ```
   I need more information to write a quality story:

   - Who is the primary user? (persona/role)
   - What specific problem are they facing?
   - What does success look like for this feature?
   - Are there any design references or examples?
   ```
3. **Wait for clarification before proceeding**

### User Requests Design Work

If user explicitly asks for UX/design feedback:

1. Reference the UX Expert delegation pattern from CLAUDE.md
2. Use `Task(general-purpose)` with UX-focused prompt
3. Present design synthesis separately (not in story)
4. User decides what (if anything) goes into story

**Design work is always opt-in, never automatic.**

---

## Quality Checklist

Before presenting the story, verify:

- [ ] All required clarifying questions answered
- [ ] Blast radius analysis performed (if technical change)
- [ ] Story follows guide template structure
- [ ] Acceptance criteria are observable outcomes (not implementation steps)
- [ ] Out of scope is explicitly defined
- [ ] Technical findings presented separately (not in story draft)
- [ ] No automatic design work included
- [ ] Awaiting approval before {{PM_TOOL}} creation

**If any quality gate fails, address the gap before presenting.**

---

## Tips for Success

1. **Always ask clarifying questions** - Don't guess or assume
2. **Run blast radius early** - Saves time if scope needs adjustment
3. **Be explicit about risk** - If HIGH/CRITICAL, stop and get acknowledgment
4. **Keep story clean** - Technical details presented separately for user to review
5. **Wait for approval** - Never create in {{PM_TOOL}} without explicit "yes"
6. **Reference project docs** - Always check `.claude/docs/story-writing-guide.md` first
7. **Include file paths** - In blast radius analysis, always provide specific locations

---

## Integration with Other Skills

This skill integrates with:

- **`/blast-radius`** - Can be invoked separately for deeper analysis if needed
- **`/triage`** - Use `/triage` first if this is a bug report; use `/story` after confirming it's a new story
- **`/plan-feature`** - For complex multi-story features, use `/plan-feature` first to break down into stories

---

**Remember:** Create clean stories focused on WHAT and WHY. Technical details are presented separately for your review. Design work is opt-in only.
