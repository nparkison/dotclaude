# Skills

Skills (also called custom slash commands) are markdown files that define reusable workflows for Claude Code. Instead of typing the same multi-step instructions every session, you encode the workflow once as a skill and invoke it with a slash command. Claude reads the file and follows the workflow as written.

Skills live in two places: `~/.claude/commands/` for global skills that work across all projects, and `.claude/commands/` at the project root for project-specific workflows. A skill in the project directory takes precedence if both define the same command name.

Invoking a skill is as simple as typing `/skill-name` in Claude Code. Claude fetches the markdown file, reads the instructions, and follows them. There is no compilation step, no syntax to learn beyond markdown. The workflow is the documentation and the documentation is the workflow.

Skills can compose. `/story` invokes `/blast-radius` when the story involves a technically complex change. `/finish` calls on git operations, PM tool updates, and Obsidian note creation in sequence. You build reusable primitives and chain them together as your workflow demands.

---

## Developer Skills

| Skill | Command | What it does |
|---|---|---|
| `blast-radius.md` | `/blast-radius` | Analyzes downstream impact of code changes: traces dependencies, flags financial and aggregation risks, outputs a structured risk report with a go/no-go recommendation |
| `pre-commit-safety.md` | `/pre-commit-safety` | Final safety gate before committing: categorizes changes by risk level, runs tests and linters, checks high-risk files, presents an approval checklist before anything is staged |
| `triage.md` | `/triage` | Bug triage: searches the PM tool first for existing tickets before touching the codebase; surfaces status, owner, and epic context so you know within minutes if it's already being worked |
| `finish.md` | `/finish` | End-of-session wrap-up: reviews uncommitted code, updates the PM tool with story progress, writes session notes to Obsidian, commits and pushes |
| `monitors.md` | `/monitors` | Daily health checks: surfaces stale PRs, stuck sprint stories, and unowned work before standup so you walk in knowing what needs attention |
| `release-notes.md` | `/release-notes` | Auto-generates internal and external release notes from promotion PR data. Structured format, ready for stakeholder distribution |
| `update-docs.md` | `/update-docs` | Keeps convention docs accurate after implementation changes: prevents doc drift from accumulating into a reliability problem |

---

## Product Manager Skills

| Skill | Command | What it does |
|---|---|---|
| `story.md` | `/story` | Writes user stories: asks clarifying questions, runs blast radius analysis for technical changes, follows the project story guide template, drafts for approval before creating in the PM tool |
| `sprint-prep.md` | `/sprint-prep` | Pre-sprint briefing: analyzes the active sprint for staleness, flags backlog orphans, cross-references customer pressure to surface what actually needs to move |
| `cs-doc.md` | `/cs-doc` | Generates CS-facing feature documentation in customer language. No engineering jargon, rollout tables, FAQ section, ready for posting to internal knowledge bases |
| `plan-feature.md` | `/plan-feature` | Full feature planning from brief to implementation order: codebase exploration, UX review, architecture design, story breakdown, and sequencing in a single workflow |

---

## Skill Relationships

Skills are designed to work standalone, but they connect into a larger workflow:

```
Bug reported
  → /triage
      → existing ticket found? STOP and surface it
      → no ticket? investigate, then /story

Feature request
  → /plan-feature
      → /story (one per story)
          → /blast-radius (for technical stories)
              → implementation
                  → /pre-commit-safety
                      → /finish

Release
  → /release-notes
      → /cs-doc (for significant features)

Daily
  → /monitors (pre-standup health check)
```

The most important connection is `/triage` at the top of the bug flow. The question "is this already known?" is the cheapest one to answer, and it's the one most often skipped. `/triage` enforces the discipline of checking before investigating.

---

## For PMs

These skills are how a PM uses Claude Code as a force multiplier, not a writing assistant.

Story writing, sprint prep, and CS documentation are structured workflows with real, shippable outputs. The PM skills in this repo automate the repeatable parts: gathering context, applying templates, checking for risks, formatting for the audience. The judgment calls (prioritization, tradeoffs, customer framing) stay with you.

The PM who writes production code uses the developer skills too. `/blast-radius` before a schema migration, `/pre-commit-safety` before pushing, `/finish` to close out a session cleanly. The developer and PM skill sets are complementary, not separate tracks.

None of this requires deep engineering knowledge to use. The skills are written to be self-guided. You invoke the command, Claude asks the questions it needs, and the workflow runs. The value is in the structure: knowing that every story went through the right checklist, every bug was triaged before anyone spent an hour in the codebase, every release shipped with documentation ready.

---

## Creating Your Own Skills

Skills are markdown files. There is no framework to install.

1. Create a `.md` file in `~/.claude/commands/` (global) or `.claude/commands/` (project-specific).

2. Add YAML frontmatter at the top with identifying metadata:
   ```yaml
   ---
   name: my-skill
   description: One-line description of what this skill does
   scope: all
   version: 1.0.0
   ---
   ```

3. Write the workflow as numbered steps. Be explicit. Claude follows the instructions literally, so clarity beats brevity. Specify what to read, what to ask, what to output, and in what order.

4. Use `{{PLACEHOLDER}}` values for anything org-specific (PM tool names, repo paths, Obsidian vault locations). Document them at the top of the file so users know what to replace.

5. Skills can invoke other skills (`/blast-radius`) and spawn sub-agents for parallel work. Reference this in your workflow steps when the task benefits from parallelism or specialization.

6. Test by typing `/my-skill` in Claude Code. Iterate on the instructions until the output matches your intent.

---

## Customization

All skills in this repo use `{{PLACEHOLDER}}` values for org-specific configuration. Search and replace them before use.

Common placeholders:

| Placeholder | What to replace it with |
|---|---|
| `{{PM_TOOL}}` | Your PM tool name (Shortcut, Linear, Jira) |
| `{{YOUR_ORG}}` | Your organization or team name |
| `{{YOUR_REPO}}` | Your repository name or path |
| `{{OBSIDIAN_VAULT}}` | Absolute path to your Obsidian vault |
| `{{STORY_GUIDE}}` | Path to your story writing guide or template |

Skills are designed to work independently. Install the ones that fit your workflow and ignore the rest. There is no required set.
