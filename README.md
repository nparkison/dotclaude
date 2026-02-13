# dotclaude

Personal Claude Code configuration backup. Contains global settings, custom commands,
skills, project-specific memory files, and Slabstack project reference docs.

## What's backed up

| Directory | Source | Contents |
|-----------|--------|----------|
| `global/` | `~/.claude/` | CLAUDE.md, hooks, settings, commands, skills, plugin config |
| `agents/` | `~/.agents/` | Skill packages (e.g., react-components) |
| `projects/` | `~/.claude/projects/*/memory/` | Per-project MEMORY.md files |
| `slabstack-project/` | `<repo>/.claude/` | Slabstack-specific reference docs and settings |

## Usage

### Sync local → repo (before committing)

```bash
./sync.sh
```

### Restore repo → local (on a new machine)

```bash
./restore.sh
```

### Backup product-planning to Google Drive

```bash
./backup-product-planning.sh
```

## What's NOT backed up here

- **Credentials** (`.credentials.json`) — re-authenticate on new machine
- **Conversation history** (`history.jsonl`) — ephemeral
- **Plugin caches** — re-downloaded automatically
- **Debug/telemetry/session data** — ephemeral
- **product-planning/** — backed up to Google Drive separately (binary files)
