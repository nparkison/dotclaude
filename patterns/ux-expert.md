# UX Expert Consultation Gate

Spawn a dedicated UX-focused sub-agent to review any user-facing change before implementation begins. It's a quality gate, not a blocker.

## Problem

Claude will build exactly what you ask for. Ask for a settings page, you get a settings page. But the grouping might be confusing, the save behavior might be unclear, error states might be missing, and the mobile layout might be broken. Claude optimizes for "does it work?" not "is it good to use?"

UX problems compound. A confusing flow in one place sets a precedent. Other features copy it. New engineers treat it as the established pattern. By the time someone notices, there are six places that work the same bad way.

Catching UX issues after implementation is expensive. A refactor touches components, tests, styles, and sometimes data models. Catching issues at the plan stage is nearly free because nothing has been built yet.

Most solo developers and small teams don't have a dedicated UX person to review designs. This pattern fills that gap. You get a second perspective at the moment it's cheapest to act on.

## Pattern

Before finalizing any user-facing implementation plan, spawn a general-purpose sub-agent with a UX Expert persona. Give it the proposed design or feature description. Ask it to look at the change through a specific lens.

The UX agent isn't reviewing aesthetics. It's reviewing usability: whether users can figure out what to do, whether the interface behaves the way they expect, and whether the feature actually solves the problem they have.

The agent should return concrete, actionable feedback. Not "consider the user experience" but "the save button needs to provide feedback because there's no visible indication the action completed" or "grouping settings by event type forces users to scroll across four sections to configure email notifications; group by channel instead."

Vague feedback can't be acted on. Push for specifics in your prompt.

The UX review fits into the delegation-first workflow at step 3: after `Explore` has mapped the codebase and `Plan` has produced an implementation design, but before any code is written. Changing a plan is free. Refactoring a built feature is not.

## Implementation

### The prompt pattern

```
Task(general-purpose): "Act as a Senior UX Expert. Review [feature/change] considering:
- User journey: How does this fit into the user's workflow?
- Cognitive load: Is this intuitive or does it add complexity?
- Edge cases: Empty states, errors, loading states.
- Accessibility: Is this usable for all users?
- Consistency: Does this match existing patterns users expect?
- User goals: Does this help users accomplish their actual objectives?
Provide specific UX recommendations and flag any concerns."
```

Replace `[feature/change]` with the proposed design from your Plan agent. The more context you give (existing patterns, user type, what the feature replaces), the more useful the feedback.

### When to invoke

- Before finalizing any UI or flow implementation plan
- When choosing between two interaction approaches (e.g., modal vs. inline editing)
- When designing a new user-facing feature from scratch
- When reviewing error handling and empty states for an existing feature
- Any time you catch yourself thinking "users will figure it out"

### Fitting it into the workflow

```
1. Task(Explore): "Map the relevant parts of [repo]"
2. Task(Plan):    "Design [feature] based on these existing patterns"
3. Task(UX Expert): "Review the proposed design for usability issues"  <-- here
4. [Synthesize Plan + UX feedback. Present to user for approval.]
5. Task(general-purpose): "Implement the approved plan"
6. Task(Bash): "Run tests and linting"
```

Steps 2 and 3 can run in parallel if you already have the Explore results and can draft the UX prompt without waiting for Plan to finish.

### Adding it to CLAUDE.md

```
## UX Expert Consultation

Before finalizing any user-facing implementation, spawn a UX Expert agent:

Task(general-purpose): "Act as a Senior UX Expert. Review [feature/change] considering:
- User journey: How does this fit into the user's workflow?
- Cognitive load: Is this intuitive or does it add complexity?
- Edge cases: Empty states, errors, loading states.
- Accessibility: Is this usable for all users?
- Consistency: Does this match existing patterns users expect?
- User goals: Does this help users accomplish their actual objectives?
Provide specific UX recommendations and flag any concerns."

Invoke before finalizing UI plans, when choosing between interaction approaches,
and when reviewing error handling. The UX review happens at the plan stage, not
after implementation.
```

## Example

**User request:** "Add a notification preferences page."

After `Explore` maps the existing settings structure and `Plan` produces a design, the UX agent reviews the proposed implementation:

**What Plan produced:**
- A single page listing all notification events (new comment, mention, weekly digest, etc.)
- Toggle for each event with email/push/in-app columns
- Save button at the bottom

**What the UX agent flagged:**
- Grouping by event type forces users to scan the whole page to configure a single channel. A user who wants to disable all email notifications has to find every email toggle individually. Group by channel (email, push, in-app) with events nested under each.
- No "saved" confirmation. The save button disappears into the page footer. Users won't know if it worked. Either auto-save with a subtle toast, or change the button state to "Saved" for 2 seconds.
- First-time users land on a page of 12 unchecked toggles. The blank state feels like an error. Start with sensible defaults on and let users opt out.
- No explanation of what "in-app" means for users who haven't seen in-app notifications yet. One line of helper text prevents a support ticket.

None of these come from the Plan agent because Plan agents optimize for completeness of implementation, not quality of experience. The UX agent catches what Plan misses.

These four changes fold into the implementation plan before a single component is written.
