# Guardrails: Review Gates Before Shared-System Actions

> **Prompt:** "Create a bug ticket for the broken export button and push the fix"

## Without dotclaude

Claude acts on both requests without pausing.

```
Claude: I'll create the ticket and push the fix.

[Linear API] Creating issue...
  Title: "Export button broken"
  Priority: Medium
  Status: Todo
  Team: Engineering
  (no description, no reproduction steps, no affected users)

Issue created: ENG-1089

[Edit] src/components/ExportButton.tsx (applying fix)
[Bash] git add src/components/ExportButton.tsx
[Bash] git commit -m "fix export button"
[Bash] git push origin main
```

Two actions taken against shared systems with no review: a ticket created
with a thin description that the team will have to clean up later, and code
pushed directly to main with a commit message that tells you nothing about
what actually broke or why.

## With dotclaude

Claude drafts everything and waits for a green light before acting.

```
Claude: Before I create anything, let me draft the ticket for your review.

--- DRAFT TICKET ---
Title: Export button fails silently for datasets over 10k rows
Priority: High
Team: Engineering
Labels: bug, data-export
Description:
  Steps to reproduce:
  1. Navigate to Reports
  2. Select a date range returning >10k rows
  3. Click Export CSV

  Expected: CSV file downloads
  Actual: Button shows loading state briefly, then resets. No error shown.
  No network request is made after the initial click.

  Impact: Any user trying to export large reports. Affects the
  end-of-month reporting workflow several enterprise accounts use.

Root cause (preliminary): ExportButton.tsx has a 5MB payload guard that
  silently aborts. The guard has no user-facing feedback.
---

Does this look right? I can adjust priority, description, or labels before
creating it.
```

User: "Looks good, create it and push the fix."

```
Claude: Ticket created: ENG-1089.

Committing the fix now.

[Edit] src/components/ExportButton.tsx
[Bash] git add src/components/ExportButton.tsx
[Bash] git commit -m "fix(export): show error toast when payload exceeds size limit"

Ready to push. This will go to origin/main. Confirm?
```

User: "Yes, push it."

```
[Bash] git push origin main
Done.
```

## What changed

- Default Claude created a ticket with no description and pushed to main
  without pausing. Both shared-system actions happened before the user
  could review anything.
- With dotclaude, the Draft-Before-Create rule fires for the ticket, and
  the push-guard hook asks for confirmation before touching the remote.
- The commit message is also meaningful: it tells future readers what
  broke and what the fix does, not just "fix export button."
