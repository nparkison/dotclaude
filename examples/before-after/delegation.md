# Delegation: Spawning Agents Instead of Coding Immediately

> **Prompt:** "Add a user preferences page for notification settings"

## Without dotclaude

Claude starts writing code immediately.

```
Claude: I'll add a user preferences page for notification settings.

[Read] src/pages/Dashboard.tsx
[Read] src/components/Layout.tsx
[Edit] src/pages/Preferences.tsx (creating new file)
[Edit] src/routes.tsx (adding /preferences route)
[Edit] src/components/Nav.tsx (adding nav link)
```

The result compiles. It uses a local `useState` hook for form state, hardcodes
notification categories based on what Claude guessed, and wires up a save
button to a `fetch('/api/preferences', { method: 'POST' })` call. The pattern
does not match the rest of the app, which uses React Query and a typed API
client. No edge cases handled: no loading state, no error state, no empty state
for users with no preferences set yet.

## With dotclaude

Claude delegates before touching any code.

```
Claude: Before writing anything, I want to map the existing patterns.
Spawning three agents in parallel.

Task(Explore): "Find all existing settings and preferences patterns in the
  codebase. Look for: form patterns, how API mutations are handled, how state
  is managed for user-level config, and where notification-related types live."

Task(Explore): "Find the notification system. What notification types exist?
  What's the data model? Is there an existing API endpoint?"

Task(UX Expert): "Review a proposed notification preferences page. Consider:
  how users discover this page, how preferences are grouped, what the default
  state looks like for a new user, how the user knows their changes saved,
  and whether any current patterns in a typical SaaS settings flow are missing."
```

After the agents report back:

```
Explore found:
- Settings pages use a <SettingsLayout> wrapper with section tabs
- Mutations go through `useMutation` from React Query + a typed `apiClient`
- Notification types are defined in src/types/notifications.ts (6 categories)
- Existing endpoint: PUT /api/users/:id/notification-preferences

UX Expert flagged:
- New users have no preferences set. Need a sensible default state
- "Save" should be per-section, not one global button (reduces anxiety)
- In-page success toast already exists as <Toast variant="success">

Task(Plan): "Design the preferences page implementation using the patterns
  above. Use SettingsLayout, React Query useMutation, apiClient, and the
  existing Toast component."

Task(general-purpose): "Implement the plan."
```

The result fits the codebase. The UX edge cases are handled before a line
of implementation code is written.

## What changed

- Default Claude read two files and started writing. dotclaude spawned three
  agents before touching any code, and discovered the existing patterns and
  API endpoint first.
- The UX Expert caught the empty-state problem and the per-section save
  preference before implementation, not during code review.
- The final code uses the same mutation pattern as every other page in the
  app because an Explore agent found that pattern explicitly.
