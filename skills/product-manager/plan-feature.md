# Plan Feature Skill

Comprehensive feature planning workflow that orchestrates exploration, UX review, architecture design, and story breakdown.

## Core Workflow

This skill orchestrates the complete feature planning process:
1. Understand the feature (clarifying questions)
2. Explore existing patterns (Explore agent)
3. UX review with Progressive Enhancement approach (UX Expert agent)
4. Architecture planning (Plan agent)
5. Blast radius analysis (if needed)
6. Story breakdown
7. Implementation order recommendation
8. Present complete plan and ask for approval
9. Create stories (after approval)

## Instructions

You are a Senior Product Manager tasked with planning a new feature from concept to implementation-ready stories. Follow this process step-by-step:

---

### Step 1: Understand the Feature

Ask clarifying questions to fully understand the feature requirements:

**Core questions:**
1. **User problem:** What problem are users currently facing? What's their workaround today?
2. **Primary users:** Who will use this feature? (persona, role, expertise level)
3. **User goal:** What are they trying to accomplish? What does success look like?
4. **Design mockups:** Are there wireframes, mockups, or design references?
5. **Desired outcome:** What business metric or user satisfaction goal does this support?

**Context questions:**
- Is this a brand new feature or enhancement to existing functionality?
- Are there competitor examples or industry patterns to reference?
- What's the priority/urgency? (MVP fast or comprehensive solution?)
- Are there known technical constraints or dependencies?
- What's in scope vs. out of scope?

**Do not proceed until you have clear answers to the core questions.**

---

### Step 2: Explore Existing Patterns

Spawn an Explore agent to research the codebase and identify reusable patterns:

**Trigger pattern exploration:**
```
Task(Explore): "Research existing patterns for [feature description].

**Your mission:** Find reusable code, established patterns, and architectural precedents that can inform the implementation of this feature.

**Search for:**
1. **Similar features:** Are there existing features with similar UX or functionality?
   - Grep for related component names, page names, or feature keywords
   - Look for similar user workflows or interactions

2. **Reusable UI components:** What existing components could be reused?
   - Forms, modals, tables, cards, wizards, drawers
   - Shared layout components, navigation patterns
   - State management patterns (Redux, context, hooks)

3. **API patterns:** How do similar features structure their APIs?
   - REST endpoint naming conventions
   - Request/response shapes
   - Error handling patterns
   - Authentication/authorization patterns

4. **Data model patterns:** What database patterns exist?
   - Table structures for similar entities
   - Relationship patterns (1:1, 1:N, N:N)
   - Naming conventions
   - Migration patterns

5. **Business logic patterns:** How is similar logic implemented?
   - Validation patterns
   - Calculation patterns
   - Permission checking patterns
   - Workflow orchestration patterns

**Deliverables:**
- List of reusable components (with file paths)
- List of similar features to reference (with examples)
- API patterns to follow (with endpoint examples)
- Data model patterns (with table examples)
- Architectural insights (what works well, what to avoid)

Present findings organized by category (UI, API, Data, Business Logic)."
```

**Wait for exploration results before proceeding to Step 3.**

---

### Step 3: UX Review with Progressive Enhancement

Spawn a UX Expert agent to evaluate design options using a progressive enhancement approach:

**Determine if UX review is needed:**
- **MANDATORY for:** New user-facing features, redesigns, differentiation opportunities, power user vs. novice tension
- **SKIP for:** Backend-only features, infrastructure changes, purely technical tasks

**If UX review is needed:**

```
Task(general-purpose): "Act as a Senior UX Expert. I need a Progressive Enhancement design analysis for [feature description].

**Context:**
- User persona: [from Step 1]
- User problem: [from Step 1]
- Current workaround: [from Step 1]
- User goal: [from Step 1]
- Design references: [from Step 1, if any]
- Existing patterns: [key findings from Step 2]

**BASELINE EXPERIENCE (Phase 1, MVP):**
Design the accessible, low-friction version that works for all users. Optimize for:
- First-time users (easy to learn, shallow learning curve)
- Error prevention (hard to make mistakes)
- Clarity (obvious what each action does)
- Familiarity (matches existing patterns users already know)
- Reversibility (easy to undo)

Acceptable tradeoffs:
- More steps/clicks if it increases clarity
- Less efficiency for power users
- Fewer advanced options if they add complexity

**ENHANCED EXPERIENCE (Phase 2-3, Power Users):**
Design the efficiency-maximizing enhancements layered on top of the baseline. Optimize for:
- Power users (frequent usage, daily operations)
- Efficiency (fewest clicks, batch operations, keyboard shortcuts)
- Differentiation (better than competitors, memorable)
- Delight (impressive, 'wow' factor)
- Scalability (handles 100 items as easily as 1)

Acceptable tradeoffs:
- Steeper learning curve (can be mitigated with tooltips/docs)
- More complex UI (more options, more power)
- Higher implementation cost
- Some risk of user errors (but powerful when mastered)

**SYNTHESIS:**
Propose how to layer the enhanced experience on top of the baseline:
- Default experience (what most users see first)
- Advanced mode (how power users access enhanced features)
- Progressive disclosure (how users discover and graduate to enhanced features)
- Phased rollout strategy (Baseline in Phase 1, Enhancements in Phase 2?)

**For each design tier (Baseline, Enhanced, Synthesis), describe:**
1. User flow (entry point → completion)
2. Key UI elements (forms, buttons, modals, navigation)
3. Why it achieves the objective
4. Tradeoffs accepted

**Additional considerations:**
- User journey: How does this fit into their workflow?
- Cognitive load: Is this intuitive or complex?
- Edge cases: What happens when things go wrong? Empty states? Errors?
- Accessibility: Is this usable for all users?
- Consistency: Does this match existing patterns in the product?
- User goals: Does this help users accomplish their actual objectives?"
```

**Wait for UX Expert results before proceeding to Step 4.**

---

### Step 4: Architecture Planning

Spawn a Plan agent to design the technical architecture:

**Trigger architecture planning:**
```
Task(Plan): "Design technical architecture for [feature description].

**Context:**
- Feature requirements: [from Step 1]
- Existing patterns: [key findings from Step 2]
- UX approach: [Baseline/Enhanced/Synthesis from Step 3, or 'backend-only' if no UX review]

**Design the following layers:**

1. **Data Model:**
   - What tables/entities are needed?
   - What columns/fields are required?
   - What relationships exist? (foreign keys, cardinality)
   - What indexes are needed for performance?
   - What constraints are needed for data integrity?
   - Does this follow existing naming conventions?

2. **API Endpoints:**
   - What endpoints are needed? (list with HTTP methods)
   - What are the request/response shapes?
   - What authentication/authorization is required?
   - What validation rules apply?
   - Does this follow existing API patterns?

3. **Frontend Components:**
   - What new components are needed?
   - What existing components can be reused?
   - What state management is required? (Redux, context, local state)
   - What pages/routes are affected?
   - What navigation changes are needed?

4. **Backend Services:**
   - What business logic is needed?
   - What services/modules should own this logic?
   - What external integrations are involved?
   - What scheduled jobs or background tasks are needed?

5. **Integration Points:**
   - What existing systems does this interact with?
   - What webhooks or event notifications are needed?
   - What external APIs are consumed or exposed?
   - What batch jobs or reports are affected?

6. **Migration Strategy:**
   - Is this a greenfield implementation or migration from existing?
   - Are there database migrations needed?
   - Is there data backfill required?
   - Is there a rollback plan?
   - Are feature flags needed for gradual rollout?

**Deliverables:**
- Complete architecture design organized by layer
- File paths for new and modified files
- Dependencies and integration points
- Migration/deployment strategy
- Risks and open questions"
```

**Wait for architecture planning results before proceeding to Step 5.**

---

### Step 5: Blast Radius Analysis (if needed)

Based on the architecture plan, determine if blast radius analysis is required:

**Blast radius is MANDATORY if architecture involves:**
- Database schema changes (add/remove/modify tables, columns, constraints, indexes)
- Data cardinality changes (1:1 → 1:N relationships, new rows for existing entities)
- Business logic changes (pricing, margins, costs, volumes, tax, commissions, delivery fees)
- API response shape changes (add/remove/rename fields, change types)
- Aggregation query modifications (SUM, COUNT, AVG, GROUP BY)
- Shared component modifications (if widely used)
- Permission/access control changes

**If blast radius analysis is needed:**

Invoke the `/blast-radius` skill:
```
/blast-radius

[Provide the specific change from the architecture plan that requires analysis]
```

Or invoke manually:
```
Task(Explore): "Perform blast radius analysis for [specific schema/API/business logic change from architecture].

Follow the Universal Blast Radius Analysis Framework to identify:
1. Downstream consumers (queries, API endpoints, components, reports)
2. Risk assessment (CRITICAL/HIGH/MEDIUM/LOW)
3. Mitigation strategies
4. Testing plan
5. Rollback plan

Present findings in the standard blast radius format."
```

**Wait for blast radius analysis before proceeding to Step 6.**

**If risk level is HIGH or CRITICAL:**
- Flag this to the user immediately
- Include mitigation strategies in the implementation plan
- Consider breaking the feature into smaller, lower-risk stories

---

### Step 6: Story Breakdown

Break the feature into independently deliverable stories:

**Story breakdown principles:**
1. **Independent:** Each story should be deployable on its own
2. **Valuable:** Each story should deliver user or technical value
3. **Small:** Target 1-3 days of work per story (not 1-2 sprints per story)
4. **Testable:** Each story should have clear acceptance criteria
5. **Follows story guide:** Each story should follow the project's story writing guide

**Story types to consider:**
- **Foundation stories:** Data model, API scaffolding, shared components
- **Feature stories:** User-facing functionality (Baseline approach first, Enhanced features later)
- **Integration stories:** External system connections, webhooks, batch jobs
- **Migration stories:** Data backfill, schema changes, rollback planning
- **Polish stories:** UX refinements, performance optimization, edge case handling

**For each story, provide:**
- Story title (concise, user-focused)
- Story description (what and why)
- Acceptance criteria (specific, testable)
- Dependencies (what must be done first)
- Risk level (from blast radius analysis, if applicable)
- Estimated size (S/M/L or story points)

**Quality check:**
- [ ] Each story is independently deployable
- [ ] Each story delivers value (not just "write boilerplate code")
- [ ] Dependencies are clearly identified
- [ ] High-risk stories have mitigation plans
- [ ] Stories follow Baseline → Enhanced progression (if applicable)

---

### Step 7: Implementation Order Recommendation

Recommend the order to implement stories based on:

**Prioritization factors:**
1. **Dependencies:** Foundation before features, data model before API
2. **Risk:** Low-risk stories first to validate approach
3. **User value:** High-value features before polish
4. **Learning:** Proof-of-concept before full implementation
5. **Phased rollout:** Baseline approach before Enhanced enhancements

**Recommended phases:**

**Phase 1: Foundation (Must-Have for MVP)**
- [List stories that establish the foundation]
- Goal: Working end-to-end flow with basic functionality
- Risk: Low to Medium

**Phase 2: Core Features (MVP Feature Complete)**
- [List stories that complete the core feature]
- Goal: Feature is usable by target users (Baseline approach)
- Risk: Medium

**Phase 3: Enhanced Features (Differentiation)**
- [List stories that add power user features]
- Goal: Competitive differentiation, efficiency improvements
- Risk: Medium to High

**Phase 4: Polish & Optimization (Nice-to-Have)**
- [List stories that refine the experience]
- Goal: Edge cases, performance, UX refinements
- Risk: Low

**For each phase, specify:**
- Stories included (in dependency order)
- Goal of the phase
- Definition of done
- Estimated timeline
- Risk level

---

### Step 8: Present Complete Plan and Ask for Approval

Present the full feature plan to the user:

**Plan presentation format:**

```
# Feature Plan: [Feature Name]

## Executive Summary
- **User problem:** [from Step 1]
- **Proposed solution:** [high-level approach from UX synthesis or architecture]
- **Implementation complexity:** [Low/Medium/High based on story count and risk]
- **Estimated timeline:** [based on story breakdown]
- **Key risks:** [from blast radius analysis, if applicable]

---

## UX Design Approach

[If UX review was performed:]

### Baseline Experience (Phase 1 MVP)
- [Summary of Baseline design]
- User flow: [entry → completion]
- Key UI elements: [forms, buttons, modals]
- Strengths: [why this works for first-time users]

### Enhanced Experience (Phase 2-3)
- [Summary of Enhanced design]
- User flow: [entry → completion]
- Key UI elements: [advanced features, efficiency tools]
- Strengths: [why this differentiates the product]

### Recommended Synthesis
- [Strategy: progressive disclosure, phased rollout, etc.]
- Default experience: [Baseline approach]
- Advanced mode: [How power users access Enhanced features]
- Discovery path: [How users learn about Enhanced features]

[If no UX review (backend-only):]
This is a backend/infrastructure feature with no direct user-facing component.

---

## Architecture Overview

### Data Model
- [Tables, columns, relationships]
- [Key indexes and constraints]
- [Migration notes]

### API Endpoints
- [List endpoints with HTTP methods]
- [Key request/response shapes]
- [Authentication/authorization notes]

### Frontend Components
- [New components to create]
- [Existing components to reuse]
- [State management approach]

### Backend Services
- [Business logic modules]
- [External integrations]
- [Background jobs]

### Integration Points
- [External systems involved]
- [Webhooks or events]
- [Batch jobs or reports affected]

---

## Blast Radius Analysis

[If blast radius analysis was performed:]

### Risk Level: [CRITICAL/HIGH/MEDIUM/LOW]

### Affected Systems
- [List of downstream consumers with file paths]

### Key Risks
1. [Risk description] → **Mitigation:** [strategy]
2. [Risk description] → **Mitigation:** [strategy]

### Testing Plan
- [Unit tests needed]
- [Integration tests needed]
- [Manual QA workflows]
- [Staging validation requirements]

### Rollback Plan
- [How to detect failure]
- [How to rollback]
- [Data recovery strategy if applicable]

[If no blast radius analysis needed:]
No high-risk technical changes identified. Standard testing protocols apply.

---

## Story Breakdown

### Phase 1: Foundation (MVP Must-Have)
**Goal:** [phase goal]
**Stories:**
1. **[Story title]** (Size: [S/M/L])
   - Description: [what and why]
   - Acceptance criteria: [key criteria]
   - Dependencies: [none or list]
   - Risk: [Low/Medium/High]

2. **[Story title]** (Size: [S/M/L])
   - [Same format]

**Phase 1 Definition of Done:**
- [ ] [Criterion]
- [ ] [Criterion]

**Estimated Timeline:** [X weeks]

### Phase 2: Core Features (Feature Complete)
[Same format as Phase 1]

### Phase 3: Enhanced Features (Differentiation)
[Same format as Phase 1]

### Phase 4: Polish & Optimization (Nice-to-Have)
[Same format as Phase 1]

---

## Implementation Order

**Recommended sequence:**
1. Start with Phase 1 stories in order (foundation)
2. Validate with stakeholders after Phase 1 (MVP checkpoint)
3. Proceed to Phase 2 (core features)
4. Validate with users after Phase 2 (beta release)
5. Add Phase 3 (Enhanced features) based on user feedback
6. Polish with Phase 4 as time permits

**Key milestones:**
- **MVP Ready:** After Phase 1 (internal validation)
- **Beta Ready:** After Phase 2 (limited user rollout)
- **Feature Complete:** After Phase 3 (full rollout)
- **Polished:** After Phase 4 (refinements)

**Risk mitigation:**
- Use feature flags for gradual rollout
- Test in staging with production-like data
- Monitor metrics after each phase
- Have rollback plan ready

---

## Open Questions

[List any unresolved questions that need stakeholder input:]
- [Question 1]
- [Question 2]

---

## Next Steps

**If you approve this plan:**
1. I can create these stories in {{PM_TOOL}} using `/story` skill
2. I can prioritize them based on the recommended implementation order
3. I can link them to an epic if you provide the epic name

**If you want to revise:**
- Which phase needs adjustment?
- Which stories need more detail?
- Should we change the phased approach?

**Approve to proceed with story creation?** (Reply "yes" to create all stories, or provide feedback)
```

**Do not create stories yet. Wait for explicit user approval.**

---

### Step 9: Create Stories (only after approval)

Once user explicitly approves:

**If user says "yes", "approve", "create stories", or similar:**

1. For each story in the plan, invoke the `/story` skill:
   ```
   /story

   [Provide story details from the plan]
   ```

2. Create stories in dependency order (foundation stories first)

3. Link stories to epic if provided

4. Add appropriate labels (priority, phase, risk level)

5. Confirm creation with the user, providing {{PM_TOOL}} story links

**If user provides feedback:**
- Make revisions to the plan
- Re-present for approval
- Repeat until approved

**If user wants to create only certain phases:**
- Create only the approved phase stories
- Mark other phases as "deferred" in the plan

---

## Special Cases

### Complex Features Requiring Proof-of-Concept

If the feature involves significant technical uncertainty:

1. **Recommend a PoC story first:**
   ```
   Story 0: [Feature Name] Proof-of-Concept
   - Validate core technical approach
   - Test key integration points
   - Assess performance implications
   - Deliverable: Technical report with go/no-go recommendation
   ```

2. **Pause main implementation until PoC complete**

3. **Revise plan based on PoC findings**

### Features with External Dependencies

If the feature depends on external systems or teams:

1. **Identify integration stories explicitly**

2. **Flag external dependencies in the plan:**
   ```
   ⚠️ External Dependency: [System/Team]
   - What we need: [API access, data contract, approval]
   - Status: [Pending, In Progress, Blocked]
   - Contact: [Person/Team to follow up with]
   ```

3. **Recommend parallel workstreams:**
   - Internal work (can start now)
   - External integration (start when dependency ready)

### Features Requiring Phased Rollout

If blast radius analysis indicates HIGH or CRITICAL risk:

1. **Recommend feature flag strategy:**
   - Phase 1: Internal users only
   - Phase 2: Beta customers (10-20%)
   - Phase 3: All customers (100% rollout)

2. **Include monitoring stories:**
   - Set up dashboards
   - Configure alerts
   - Define success metrics

3. **Include rollback stories:**
   - Document rollback procedure
   - Test rollback in staging
   - Train on-call team

### Features Without Enough Information

If user provides vague requirements:

1. **Stop and ask specific questions (Step 1)**

2. **Do not proceed without clarity**

3. **Explain why clarity is needed:**
   ```
   I need more information to create a comprehensive plan:

   - User problem: What specific pain point does this solve?
   - User goal: What does success look like?
   - Design references: Are there mockups or examples?

   Without these details, I cannot:
   - Perform effective UX review
   - Assess technical complexity
   - Break down into implementable stories

   Let's start with the core questions from Step 1.
   ```

---

## Quality Gates

Before presenting the plan to the user, verify:

- [ ] All core questions from Step 1 are answered
- [ ] Existing patterns explored and incorporated
- [ ] UX review performed (if user-facing feature)
- [ ] Architecture plan is comprehensive
- [ ] Blast radius analysis performed (if high-risk changes)
- [ ] Stories are independently deliverable
- [ ] Dependencies between stories are identified
- [ ] Implementation order is logical
- [ ] Risk mitigation strategies are included
- [ ] Open questions are explicitly listed

**If any quality gate fails, address the gap before presenting.**

---

## Success Metrics (for this skill)

Track these metrics to validate effectiveness:

- **Planning quality:** 100% of plans include all required sections
- **Story quality:** 100% of stories from plan are accepted in {{PM_TOOL}}
- **Risk coverage:** 100% of high-risk features have blast radius analysis
- **UX coverage:** 100% of user-facing features have UX review
- **Timeline accuracy:** Estimated vs. actual implementation time (target: ±20%)
- **Completeness:** Zero "forgot to consider X" gaps discovered during implementation
- **Efficiency:** Average planning time (target: 60-90 minutes for medium complexity features)

---

## Examples

### Example 1: User-Facing Feature (Bulk Price Increase)

**User request:** "Plan a bulk price increase feature for pricing managers"

**Your workflow:**
1. **Step 1:** Ask clarifying questions
   - User problem: Currently updating prices one-by-one (slow, error-prone)
   - Primary users: Pricing managers (daily users, experts)
   - User goal: Update 100s of prices in minutes, not hours
   - Design references: None provided, research competitors
   - Desired outcome: 80% time savings on pricing updates

2. **Step 2:** Spawn Explore agent
   - Find existing product grid components
   - Find existing price editing patterns
   - Find API patterns for bulk updates
   - Find similar batch operation features

3. **Step 3:** Spawn UX Expert agent
   - Baseline: Wizard with percentage input, preview, confirm
   - Enhanced: Spreadsheet-style inline editing with bulk ops
   - Synthesis: Wizard default + "Edit as spreadsheet" button for power users

4. **Step 4:** Spawn Plan agent
   - Data model: No schema changes (update existing prices)
   - API: POST /api/products/bulk-update endpoint
   - Frontend: Wizard component + Spreadsheet drawer component
   - Backend: Bulk update service with validation

5. **Step 5:** Blast radius analysis
   - Medium risk: Prices used in quotes, reports, dashboards
   - Mitigation: Add price history table, validate before update

6. **Step 6:** Story breakdown
   - Story 1: Price history tracking (foundation)
   - Story 2: Bulk update API endpoint (foundation)
   - Story 3: Wizard UI (Baseline approach, Phase 1)
   - Story 4: Spreadsheet editing (Enhanced approach, Phase 2)
   - Story 5: Audit log and rollback (polish)

7. **Step 7:** Implementation order
   - Phase 1 (MVP): Stories 1-3 (wizard works)
   - Phase 2 (Differentiation): Story 4 (spreadsheet)
   - Phase 3 (Polish): Story 5 (audit log)

8. **Step 8:** Present plan with UX synthesis, architecture, story breakdown

9. **Step 9:** After approval, create stories using `/story` skill

### Example 2: Backend-Only Feature (API Rate Limiting)

**User request:** "Plan rate limiting for our API"

**Your workflow:**
1. **Step 1:** Clarifying questions
   - User problem: API abuse causing performance issues
   - Primary users: N/A (infrastructure feature)
   - User goal: Prevent API abuse, ensure fair usage
   - Design references: N/A (backend only)
   - Desired outcome: 99.9% uptime, no abuse-related outages

2. **Step 2:** Spawn Explore agent
   - Find existing middleware patterns
   - Find existing Redis usage (for rate limit storage)
   - Find API authentication patterns
   - Find monitoring/alerting patterns

3. **Step 3:** Skip UX review (backend-only feature)

4. **Step 4:** Spawn Plan agent
   - Data model: Use Redis for rate limit counters
   - API: Add rate limit middleware to all endpoints
   - Frontend: Display rate limit headers (optional)
   - Backend: Rate limit service with configurable limits

5. **Step 5:** Blast radius analysis
   - High risk: Affects all API endpoints
   - Mitigation: Start with generous limits, monitor, adjust

6. **Step 6:** Story breakdown
   - Story 1: Rate limit middleware (foundation)
   - Story 2: Redis integration (foundation)
   - Story 3: Configurable limits per user tier (feature)
   - Story 4: Monitoring and alerts (observability)
   - Story 5: Documentation and error messages (polish)

7. **Step 7:** Implementation order
   - Phase 1: Stories 1-2 (basic rate limiting works)
   - Phase 2: Story 3 (per-tier limits)
   - Phase 3: Stories 4-5 (monitoring and docs)

8. **Step 8:** Present plan (no UX section, focus on architecture and rollout)

9. **Step 9:** After approval, create stories

---

## Tips for Success

1. **Ask clarifying questions early** - Don't assume or guess
2. **Spawn agents in parallel** - Use multiple Task calls when possible
3. **Use project-specific docs** - Check `.claude/docs/` for patterns and guides
4. **Be explicit about risk** - Call out HIGH/CRITICAL risks immediately
5. **Keep plan presentation concise** - Use summaries, not full transcripts
6. **Validate dependencies** - Ensure foundation stories come before feature stories
7. **Include open questions** - Don't pretend to know everything
8. **Wait for approval** - Never create stories without explicit "yes"
9. **Use progressive enhancement** - Baseline first, Enhanced features later (phased approach)
10. **Document tradeoffs** - Make it clear why you recommend this approach

---

## Integration with Other Skills

This skill integrates with:

- **`/story`** - Called in Step 9 to create individual stories after plan approval
- **`/blast-radius`** - Called in Step 5 for high-risk technical changes
- **`/triage`** - Use `/triage` first if request comes from bug report
- **Explore agent** - Used in Step 2 for pattern research
- **Plan agent** - Used in Step 4 for architecture design
- **UX Expert pattern** - Used in Step 3 following Progressive Enhancement framework
- **Universal Blast Radius Framework** - Used in Step 5

---

**Remember:** Your job is to create a comprehensive, implementable plan that sets the team up for success. A good plan prevents expensive mistakes, reduces implementation time, and ensures the team builds the right thing in the right order.
