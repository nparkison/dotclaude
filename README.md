```
 ██████   ██████  ████████  ██████ ██       ██████  ██  ██  ██████   ██████
 ██   ██ ██    ██    ██    ██      ██      ██   ██  ██  ██  ██   ██ ██
 ██   ██ ██    ██    ██    ██      ██      ██████   ██  ██  ██   ██ █████
 ██   ██ ██    ██    ██    ██      ██      ██   ██  ██  ██  ██   ██ ██
 ██████   ██████     ██     ██████ ██████  ██   ██  ██████  ██████   ██████
```

**Most people use 10% of Claude Code. This is the other 90%.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude-Code-orange)](https://claude.ai/code)

<!-- ![demo](examples/screenshots/demo.gif) -->

Dotfiles for Claude Code. A battle-tested configuration that transforms Claude from a capable assistant into a disciplined engineering system: guardrails, persistent memory, and a full library of reusable skills and hooks.

---

## The Problem

Out of the box, Claude Code is powerful but unguarded. Three patterns show up immediately once you start using it seriously:

- **No guardrails.** Claude pushes to production, creates PRs without asking, appends commit attribution you never requested, and takes irreversible actions in shared systems without a review gate. One missing instruction and something you didn't intend is already live.
- **No persistence.** Every session starts from zero. Claude doesn't know your codebase conventions, your team's review preferences, or how your project is organized. You re-explain the same context, session after session. And when a session ends, everything you discussed vanishes. No searchable history, no way to connect today's work to last month's investigation.
- **No workflow.** Default Claude works as an individual contributor. One task at a time, no delegation, no parallelism, no structure. There's nothing stopping it from doing everything itself when the right answer is to orchestrate specialists.

dotclaude fixes all three.

---

## What's In The Box

| Component | What it does | Count |
|---|---|---|
| `/setup` | **Start here.** Interactive wizard that asks about your tools and workflow, fills all placeholders, registers hooks, and removes what you don't need. Zero manual editing. | 1 skill |
| `claude.md` | Annotated reference CLAUDE.md. Covers delegation policy, guardrails, memory conventions, and project-specific context. | 1 |
| `hooks/` | Pre/post tool execution guards: push protection, audit logging, draft-before-create gates, commit message cleanup | 9 |
| `skills/developer/` | Dev workflows: blast radius analysis, bug triage, release notes, PR review, security review, branch management | 7 |
| `skills/product-manager/` | PM force multipliers: story writing, sprint prep, CS documentation, feature delivery | 4 |
| `patterns/` | Philosophy docs: delegation-first, draft-before-create, triage-first, UX review gates | 5 |
| `docs/` | Convention doc templates. Codify your codebase knowledge so Claude stops guessing | 5 |
| `obsidian/` | Auto-export every session to Obsidian. Searchable history, project wikilinks, graph view integration | 1 hook + templates |

---

## Quick Start

> **You don't need to read all of this.** Clone the repo, run the installer, then tell Claude Code (or Codex, Gemini CLI, etc.) to "set up dotclaude for my project." It will read the files, ask you a few questions, and configure everything. The repo is designed to be set up by an AI agent, not by hand.

```bash
git clone https://github.com/nparkison/dotclaude.git
cd dotclaude
./install.sh  # Interactive, pick what you want
```

Then open Claude Code and run `/setup`. The wizard asks about your tools and workflow, fills in all placeholder values, removes sections that don't apply, and registers hooks in your settings.json. No manual editing required.

Or cherry-pick individual files. Everything is designed to work independently.

---

## Philosophy: Manager, Not IC

Default Claude works as an individual contributor. You give it a task, it does it. You give it another task, it does that. It's fast and capable, but you're still in the loop for everything: reviewing every output, catching every mistake, providing context on every session.

dotclaude configures Claude to work as a manager. It delegates research tasks to sub-agents, runs parallel workstreams where possible, enforces review gates before touching shared systems, and maintains persistent memory across sessions. You describe the outcome you want. Claude figures out how to orchestrate the work.

Two patterns define this most concretely. The delegation-first pattern means Claude's first instinct for any non-trivial task is to spawn a specialized sub-agent: an Explore agent for codebase research, a Plan agent for architecture design, a Bash agent for execution. It synthesizes the results instead of doing everything itself. The draft-before-create pattern means Claude never creates items in shared external systems (PM tool stories, GitHub PRs, Slack messages) without presenting a draft and getting explicit approval first. These aren't suggestions. They're enforced by hooks.

The result is that you stop babysitting a chatbot and start orchestrating a system. Claude gets more done, makes fewer irreversible mistakes, and accumulates knowledge about your codebase over time instead of starting from scratch every session.

---

## Persistent Knowledge: The Obsidian Layer

Every Claude Code session disappears when you close it. The decisions you made, the files you explored, the dead ends you tried. Gone. You can scroll back through your terminal, but there's no searchable history, no way to connect today's work to last week's investigation, no way to spot patterns across months of usage.

dotclaude fixes this with an automatic Obsidian export pipeline. A Stop hook fires when every session ends, parses the raw session data, and writes a structured note to your vault. No manual step. No copy-paste.

Each note includes YAML frontmatter, the full conversation (user turns, Claude responses, tools called), a ranked list of every tool used, every file touched, and a link to the raw transcript. Sessions are auto-tagged by project based on your working directory, and wikilinks connect session notes to your project notes.

```
┌──────────────┐     ┌──────────────────┐     ┌───────────────────┐
│ Claude Code  │────▶│ session-to-      │────▶│ Obsidian Vault    │
│ Session ends │     │ obsidian.py      │     │                   │
│              │     │ (Stop hook)      │     │ Sessions/         │
│ JSONL on     │     │                  │     │   note.md         │
│ disk         │     │ Parses JSONL     │     │   _raw/data.jsonl │
└──────────────┘     │ Strips sys tags  │     └───────────────────┘
                     │ Writes markdown  │
                     └──────────────────┘
```

Over time, your vault becomes a searchable knowledge base of every AI-assisted work session. Use Dataview to query sessions by project, date, or tool usage. Use the graph view to see how sessions cluster around projects. The knowledge compounds instead of evaporating.

This is what six months of AI-assisted work sessions look like in Obsidian's graph view. Every node is a session. Every connection is a project relationship. All of it built automatically.

<p align="center">
  <img src="examples/screenshots/obsidian-graph.gif" alt="Six months of Claude Code sessions in Obsidian" />
</p>

See [obsidian/](obsidian/README.md) for the full setup guide and [example exports](obsidian/examples/).

---

## Component Deep Dives

- [Hooks](hooks/README.md): Pre/post tool execution guards
- [Skills](skills/README.md): Reusable workflow definitions
- [Patterns](patterns/): Philosophy and methodology docs
- [Convention Docs](docs/README.md): Templates for codifying codebase knowledge
- [Obsidian Integration](obsidian/README.md): Full setup guide and pipeline docs
- [Examples](examples/): Before/after comparisons and session transcripts

---

## For PMs

This isn't just for engineers. Claude Code has become my primary productivity layer as a PM, and the skills in `skills/product-manager/` are how I use it as a force multiplier, not a writing assistant.

Story writing, sprint prep, CS documentation, grooming prep: these are structured workflows with real outputs. The PM skills in this repo automate the repeatable parts while keeping the judgment calls in human hands. I'm a PM who ships production code. These skills are how I do both without losing my mind.

If you're a non-engineer who wants to use Claude Code seriously, start with the `claude.md` and the PM skills. The hooks and developer skills can come later as you get comfortable.

---

## Contributing

PRs welcome for new hooks, skills, and patterns. The goal is a collection of battle-tested configurations, not a curated showcase. If you've built something that's survived real usage, it belongs here.

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

[MIT](LICENSE). Use it however you want.
