<!-- TEMPLATE: Copy this file to .claude/docs/ and fill in your project's specifics.
     Lines marked with {{}} are placeholders. Example content shows the expected format. -->

# Frontend Conventions: {{YOUR_REPO}}

This file captures how UI code is structured in this project. New components should follow these patterns before introducing something new.

---

## Component File Structure

One component per file. Colocate styles, tests, and stories with the component.

```
src/components/UserCard/
  UserCard.tsx         # component
  UserCard.test.tsx    # unit/integration test
  UserCard.stories.tsx # Storybook story (if applicable)
  index.ts             # re-exports UserCard
```

Component files have a consistent internal order: imports, types, constants, component function, helpers, exports.

---

## Naming Conventions

- Components: PascalCase (`InvoiceTable`, `PaymentForm`)
- Hooks: camelCase with `use` prefix (`useCurrentUser`, `useInvoiceList`)
- Utilities: camelCase (`formatCurrency`, `parseDate`)
- Event handlers: `handle` prefix (`handleSubmit`, `handleRowClick`)

Avoid abbreviations in names unless they are domain-standard (e.g., `id`, `url`, `api`).

---

## State Management

Two categories of state, managed differently:

**Server state** (data from the API): use `{{SERVER_STATE_LIBRARY}}` (e.g., TanStack Query, SWR). Never store server data in component state or global client state. Invalidate queries rather than manually updating cache.

**Client state** (UI-only: modals open, selected tab, form draft): use `{{CLIENT_STATE_LIBRARY}}` (e.g., Zustand, Jotai, React context). Keep slices small and colocated with the feature that owns them.

When unsure which category applies: if the data lives in the database, it is server state.

---

## Styling

Using `{{STYLING_APPROACH}}` (e.g., Tailwind CSS, CSS Modules, styled-components).

- Design tokens live in `{{PATH_TO_TOKENS}}`. Use tokens, not raw hex/px values.
- Responsive breakpoints: `{{BREAKPOINTS}}` (e.g., `sm: 640px, md: 768px, lg: 1024px`).
- Dark mode: `{{DARK_MODE_APPROACH}}` (e.g., `dark:` prefix in Tailwind, CSS variable swap).

Do not write inline `style=` props unless you are computing a value dynamically (e.g., a width from a JS variable).

---

## Loading and Error States

Every data-fetching component must handle three states: loading, error, and success. No exceptions.

```tsx
if (isLoading) return <Skeleton />;
if (error) return <ErrorMessage error={error} />;
return <ActualContent data={data} />;
```

Empty states (zero results) are distinct from loading states. Show a helpful empty state rather than rendering nothing. `{{PATH_TO_EMPTY_STATE_COMPONENT}}` has the standard component.

---

## What to Replace

| Placeholder | Fill In With |
|---|---|
| `{{YOUR_REPO}}` | Your repository name |
| `{{SERVER_STATE_LIBRARY}}` | e.g., TanStack Query, SWR |
| `{{CLIENT_STATE_LIBRARY}}` | e.g., Zustand, Jotai, Redux Toolkit |
| `{{STYLING_APPROACH}}` | e.g., Tailwind CSS, CSS Modules |
| `{{PATH_TO_TOKENS}}` | e.g., `src/styles/tokens.css` |
| `{{BREAKPOINTS}}` | Your actual breakpoint values |
| `{{DARK_MODE_APPROACH}}` | How dark mode is implemented |
| `{{PATH_TO_EMPTY_STATE_COMPONENT}}` | e.g., `src/components/EmptyState` |
