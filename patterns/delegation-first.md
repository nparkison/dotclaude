# Delegation-First

The core behavioral pattern in dotclaude. Configure Claude to act as an engineering manager who orchestrates specialized sub-agents, not as an individual contributor who does everything sequentially.

## Problem

Default Claude works serially. You give it a task, it does it. You give it another task, it does that too. This works fine for small, self-contained requests. It breaks down fast on anything real.

Three problems compound quickly:

**No parallelism.** If you ask Claude to investigate an auth system, a billing system, and a notification system, it researches them one at a time. Three independent tasks that could run simultaneously take three times as long.

**Context window pressure.** Claude has a finite context window. When it does all the work itself, codebase research, architecture planning, implementation, and testing all compete for the same space. By the time you're writing code, the research context is half-gone.

**You become the bottleneck.** Without delegation, you're reviewing every intermediate output. Every search result, every file read, every design decision surfaces for your attention. You wanted a system that moves fast. Instead you're babysitting a chatbot.

## Pattern

Claude's first instinct for any non-trivial task should be to spawn a sub-agent, not do the work itself.

Sub-agents each get a clean context window. They can go deep on a specific problem without noise from the rest of the session. The orchestrator's job is to write clear prompts, collect results, synthesize findings, and make decisions. It's not to do the legwork.

This also means running independent tasks in parallel. Multiple `Task` calls in a single message launch simultaneously. Research that would take 15 minutes serially takes 5 minutes in parallel.

Use specialized agent types for different work:

| Agent Type | Use For |
|---|---|
| `Explore` | Codebase research, finding files, understanding architecture |
| `Plan` | Designing implementation strategies before touching code |
| `Bash` | Git operations, builds, running commands |
| `general-purpose` | Complex multi-step implementation work |

The orchestrator synthesizes. Sub-agents execute.

**When not to delegate:**

- Single tool calls (one Read, one Grep, one simple Edit)
- Direct questions that don't require research
- Clarifying questions back to the user
- Synthesizing information already in context

Delegation has overhead. For a one-liner, doing it directly is faster. The pattern applies to tasks with real scope: research spanning multiple files or systems, implementation work, anything where a specialized agent could go deeper than the orchestrator should go itself.

## Implementation

### The core CLAUDE.md instruction

```
## Delegation-First Workflow

Act as an Expert Manager, not an Individual Contributor.

Prioritize delegating tasks to sub-agents using the Task tool. For any non-trivial
task, the first instinct should be to spawn a sub-agent. Only do work directly if
it is genuinely simpler than delegation (a single file read, a quick factual answer,
a one-liner edit).

When multiple independent tasks exist, launch multiple sub-agents simultaneously
in a single message. Never serialize work that can be parallelized.
```

### Model policy

Research agents don't need your most capable model. Implementation agents do.

```
## Sub-Agent Model Policy

- Research / exploration agents: sonnet
- Implementation agents (writing code): sonnet or opus
- Never use haiku for anything that writes production code or makes decisions
```

### Parallel vs. serial

```
# Don't do this:
Task: "Find the auth system"
[wait for result]
Task: "Find the billing system"
[wait for result]
Task: "Find the notification system"

# Do this:
Task(Explore): "Find the auth system in [repo]"
Task(Explore): "Find the billing system in [repo]"
Task(Explore): "Find the notification system in [repo]"
```

All three fire at once. You get back three results, synthesize them, move on.

## Example

**User request:** "Add a user preferences page where users can manage their notification settings."

Without delegation, Claude starts writing code immediately. It reads a few files, makes assumptions about architecture, and produces something that may or may not fit the existing patterns. You find out it missed the existing settings framework when you review the PR.

With delegation:

```
1. Task(Explore): "Find existing preferences patterns, settings pages, and
   notification systems in [repo]. What conventions are already in place?"

2. Task(Explore): "Find the user account section of the app. What routes,
   components, and data models are involved?"

[Both fire in parallel. Results come back.]

3. Task(Plan): "Design a user preferences page for notification settings.
   Base the architecture on these existing patterns: [paste Explore results].
   Produce a file-by-file implementation plan."

4. Task(general-purpose): "Act as a Senior UX Expert. Review this preferences
   page design: [paste Plan output]. Consider: discoverability, grouping of
   options, default states, save confirmation, mobile layout. Flag concerns."

[Synthesize Plan + UX review. Present to user for approval.]

5. Task(general-purpose): "Implement the notification preferences page
   following this approved plan: [paste approved plan]"

6. Task(Bash): "Run tests and linting. Report failures."
```

Steps 1 and 2 run in parallel. Steps 3 and 4 run in parallel once those results are back. Implementation only starts after the plan is reviewed.

The orchestrator never wrote a line of application code. It wrote prompts, synthesized results, and made decisions. The sub-agents did the legwork with full context and no noise from the rest of the session.
