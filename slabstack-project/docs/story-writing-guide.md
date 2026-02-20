# Shortcut Story Writing Guide

## Core Philosophy

**Stories are for WHAT and WHY — developers decide HOW.**

A story should communicate the business problem and the desired outcome clearly enough that a developer can design their own solution. Over-specifying implementation robs developers of ownership and buries the intent under technical noise.

### The 30-Second Test

A developer should be able to read a story in 30 seconds and answer:
1. **Who** has this problem?
2. **What** is the problem or limitation?
3. **What** does "done" look like from the user's perspective?

If the story fails this test, it's too long, too technical, or missing business context.

---

## Story Structure

### Required Sections

#### 1. Title
- Clear, action-oriented — describes the capability being added or changed
- Written from the user's perspective when possible
- Good: *"Allow dispatchers to assign multiple trucks to a single quote"*
- Bad: *"Add truck_assignments join table and multi-truck API endpoints"*

#### 2. Business Context (2-3 sentences)
Answer these questions in plain language:
- **Who** is affected? (role/persona)
- **What** is the current pain or limitation?
- **What** does solving this unlock for the business?

Example:
> Dispatchers currently create separate quotes for each truck on a multi-truck job. This means a 3-truck delivery requires 3 quotes, 3 approval cycles, and 3 invoices — tripling the administrative work and increasing the chance of pricing errors. This story enables assigning multiple trucks to a single quote, streamlining the workflow.

#### 3. User Story
Standard format: *As a [role], I want [capability] so that [benefit].*

Keep it to one sentence. If you need multiple user stories, the story is probably too large — break it up.

#### 4. Acceptance Criteria
**Describe observable outcomes, not implementation steps.**

Each criterion should be something a QA person or product manager can verify by using the product — not by reading code.

✅ **Good acceptance criteria:**
- Dispatcher can assign 1-5 trucks to a quote line item
- Each truck shows its own delivery cost on the quote summary
- Removing a truck recalculates the quote total immediately
- Quote PDF lists each assigned truck with its individual cost

❌ **Bad acceptance criteria (never do this):**
- Create a `truck_assignments` join table with `quote_line_item_id` and `truck_id` foreign keys
- Add a POST endpoint at `/api/quote-line-items/{id}/trucks`
- Update the `useQuoteLineItem` hook to support an array of truck assignments
- Add a migration to create the new table with UUID primary key

### Recommended Sections

#### 5. Out of Scope
Explicitly state what this story does NOT cover. This prevents scope creep and sets expectations.

Example:
> - Does not include bulk truck assignment across multiple line items
> - Does not change how single-truck quotes work
> - Invoice generation for multi-truck quotes is a separate story

#### 6. Design Reference
Link to Figma, wireframes, or mockups if they exist. Don't describe the UI in paragraphs — point to the visual.

### Optional Section

#### 7. Technical Constraints (use sparingly)
Only include if there are **hard constraints the developer needs to know** that they wouldn't discover naturally:
- "Must work with existing offline sync — data can't require server roundtrip"
- "Existing customer API contract cannot break (v2 consumed by 12 integrations)"
- "Performance requirement: quote recalculation must complete in under 500ms"

This is NOT a place for implementation suggestions, architecture recommendations, or technical design. If the constraint is something a competent developer would discover on their own, omit it.

---

## What to NEVER Include in Story Body

| Don't include | Why |
|--------------|-----|
| Database schema / migration details | Developer decides data model |
| API endpoint specs or payload shapes | Developer designs the API |
| File paths or module references | Couples story to current code structure |
| Step-by-step implementation instructions | Robs developer of design ownership |
| Code snippets or pseudocode | Story is not a technical spec |
| Detailed technical architecture | Belongs in design doc if needed |
| Framework-specific instructions | Developer chooses their tools |

## Where Technical Context Goes Instead

If we've done technical analysis or have implementation ideas that might be useful:

1. **Separate technical design doc** — linked from the story, not inlined
2. **Story comment/thread** — after the story is created, add technical notes as a comment that developers can optionally reference
3. **Grooming conversation** — discuss technical approach verbally; the story stays clean
4. **Epic-level description** — broader technical context can live at the epic level where it provides architectural framing without cluttering individual stories

The key principle: **technical context should be opt-in, not mandatory reading.**

---

## Story Sizing Guidance

If a story description is getting long, it's usually a sign the story is too big. Split it.

- **Good story size:** Can be explained in one user story sentence with 3-6 acceptance criteria
- **Too big:** Multiple user stories, 10+ acceptance criteria, or requires multiple teams
- **Too small:** A single acceptance criterion that's really a task, not a story

---

## Anti-Patterns to Avoid

### 1. The "Technical Spec Disguised as a Story"
A story that reads like implementation instructions. Usually happens when the person writing it has already solved the problem mentally and writes down their solution instead of the problem.

### 2. The "Kitchen Sink"
A story that tries to cover every edge case, error state, and scenario upfront. Trust the developer to handle edge cases — call out only the non-obvious ones in acceptance criteria.

### 3. The "Solution-First Story"
Starting with "We need to add a new table/endpoint/component..." instead of starting with the user's problem. Always lead with the problem.

### 4. The "Copy-Paste from Technical Analysis"
Dumping raw technical investigation into a story. Technical analysis is input TO story writing, not the story itself. Distill it down to business outcomes.

---

## Template

When creating a new story, use this structure:

```
**Title:** [Action-oriented capability description]

**Business Context:**
[2-3 sentences: Who has this problem? What's the current pain? What does solving it unlock?]

**User Story:**
As a [role], I want [capability] so that [benefit].

**Acceptance Criteria:**
- [Observable outcome 1]
- [Observable outcome 2]
- [Observable outcome 3]

**Out of Scope:**
- [What this story does NOT cover]

**Design:** [Link to Figma/wireframe if applicable]

**Technical Constraints:** [Only if non-obvious hard constraints exist]
```

---

## Shortcut Defaults

When creating stories in Shortcut, always use these defaults unless explicitly told otherwise:

- **Team:** Engineering
- **Workflow State:** Unprioritized (the default backlog state for the Engineering workflow)

These ensure new stories land in the proper triage queue rather than accidentally appearing in active workflow states.

<!-- Updated 2026-02-19: Added Shortcut defaults section — team and workflow state -->
<!-- Created 2026-02-02: Initial story writing guide based on developer feedback about over-detailed stories in multi-truck epic -->
