# Contributing

This is a community project. Contributions are welcome: new hooks, skills, patterns, convention doc
templates, bug fixes, and documentation improvements.

## What makes a good contribution

**Hooks** should solve a real problem you've hit. Include inline comments explaining what the hook
does and how to customize it. Include the `settings.json` registration snippet.

**Skills** follow the existing format (name, description, trigger conditions in frontmatter). Explain
when to use the skill and when not to.

**Patterns** follow the Problem/Pattern/Implementation/Example structure. Must be based on real
usage, not theoretical.

**Convention doc templates** should be generic enough to apply to most projects of that type.

## How to contribute

1. Fork the repo
2. Create a branch: `feat/my-hook-name`
3. Add your files
4. Run the scrub checklist below
5. Open a PR with a clear description of what the contribution does and why

## Scrub checklist

Before submitting, verify:

- [ ] No company or org names
- [ ] No personal names, emails, or usernames
- [ ] No API tokens or paths to personal directories
- [ ] No team-specific project IDs
- [ ] Placeholder values used for anything org-specific (e.g., `{{YOUR_ORG}}`)

## Style guide

- Write like a human, not a language model
- No em dashes
- Keep docs concise
- Code blocks should be copy-pasteable
- Comments in hooks and scripts should explain "why", not "what"

## What we won't merge

- Hooks or skills that are too specific to one org's workflow
- Anything that requires a paid service to function (unless clearly marked optional)
- Contributions with personal info that wasn't scrubbed
