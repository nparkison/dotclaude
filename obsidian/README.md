# Obsidian Integration

Claude Code sessions are ephemeral. The moment you close a session, everything is gone: the decisions you made, the files you touched, the dead ends you explored. You can scroll back through the terminal, but there is no searchable history, no way to cross-reference work across weeks, no way to spot patterns in how you use the tool.

This directory fixes that.

## How it works

A Stop hook fires when every session ends. It reads the session JSONL from disk, strips internal system tags, and writes a structured markdown note to your Obsidian vault. No manual step. No copy-paste.

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

## What each note contains

- **YAML frontmatter:** date, session ID, cwd, git branch, Claude version, tags
- **Metadata header:** duration, turn count, working directory, branch
- **Wikilinks:** auto-generated links to project notes (if PROJECT_MAP is configured)
- **Conversation section:** each user turn with the assistant response and tools called
- **Tools Used:** ranked list of tools by call count
- **Files Touched:** every file the session read or modified
- **Raw Transcript link:** pointer to the archived JSONL in `_raw/`

See `examples/` for real output at different session lengths.

## Quick start

**1. Copy the hook script:**
```bash
cp hooks/session-to-obsidian.py ~/.claude/hooks/
```

**2. Set your vault path:**
```bash
export OBSIDIAN_VAULT="/path/to/your/vault"
```

Or edit `VAULT_ROOT_FALLBACK` directly in the script if you prefer a hardcoded path.

**3. Register the Stop hook in `~/.claude/settings.json`:**
```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/session-to-obsidian.py"
          }
        ]
      }
    ]
  }
}
```

**4. (Optional) Configure PROJECT_MAP for auto-tagging:**

Edit the `PROJECT_MAP` dict in the script to map cwd substrings to Obsidian note names:
```python
PROJECT_MAP = {
    "my-project": "My Project",
    "client-work": "Client Work",
}
```

When the session's working directory contains a matching substring, the note gets a project tag and a wikilink to that note.

## Directory structure

```
obsidian/
├── README.md                <- this file
├── session-export/
│   └── README.md            <- detailed pipeline docs and config reference
└── examples/
    ├── example-session-short.md
    ├── example-session-medium.md
    └── example-session-long.md
```

## Integration tips

- **Dataview:** query sessions by project, date range, or tool usage across your entire history
- **Graph view:** see how session notes connect to project notes and each other
- **Tag filtering:** every note gets the `claude-session` tag automatically, plus project tags if PROJECT_MAP is set
- **Deduplication:** if you re-export a session (e.g., after updating the script), the old note is replaced, not duplicated. The script matches on `session_id` in the frontmatter.
- **Debugging:** check `~/.claude/session-export.log` if notes are not appearing

Sessions with no user turns (tool-only or empty) are skipped silently.
