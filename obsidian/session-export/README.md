# session-to-obsidian

Exports Claude Code session transcripts to your Obsidian vault at the end of every session.

## How It Works

The hook is registered as a `Stop` hook in `settings.json`, so it fires automatically when a session ends. It does not block exit.

**What it reads:** Claude passes session metadata (session ID, cwd, transcript path) via stdin as JSON. The script locates the JSONL transcript at `~/.claude/projects/<hash>/<session_id>.jsonl`, then falls back to scanning all project directories if the path is missing.

**What it parses:** All turns in the JSONL are walked. User messages are extracted and cleaned: system tags (`<system-reminder>`, `<command-name>`, and similar injected blocks) are stripped via regex before anything is written to disk. Tool use blocks are collected per turn and also aggregated into total counts. File paths from `Read`, `Edit`, `Write`, and `Bash` tool inputs are captured as "files touched."

**What it writes:**
- A dated markdown note in `<vault>/<SESSIONS_SUBDIR>/`
- A copy of the raw JSONL in `<vault>/<SESSIONS_SUBDIR>/_raw/` for archival

**Deduplication:** On re-export, the script scans the sessions directory for any existing note with a matching `session_id` in its frontmatter and removes it before writing the new version.

**Empty sessions are skipped** silently. If there are no user turns after cleaning, nothing is written.

## Configuration

All config lives in the `CONFIG` block near the top of the script.

| Setting | Default | Notes |
|---|---|---|
| `OBSIDIAN_VAULT` env var | (none) | Primary way to set vault path |
| `VAULT_ROOT_FALLBACK` | `/path/to/your/obsidian/vault` | Edit this if you prefer not to use env vars |
| `SESSIONS_SUBDIR` | `Sessions/Claude Code` | Subfolder inside the vault |
| `PROJECT_MAP` | `{}` | See project detection below |
| `LOG_FILE` | `~/.claude/session-export.log` | Debug log, always appended |

### Project Detection

`PROJECT_MAP` maps cwd substrings to Obsidian note names. When a match is found, the project name becomes a tag in frontmatter and a wikilink in the note body.

```python
PROJECT_MAP = {
    "my-project": "My Project",
    "client-work": "Client Work",
}
```

Leave it as `{}` to disable this feature entirely.

## Registration

Add this to `~/.claude/settings.json` (global) or `.claude/settings.json` (per-project):

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [{
          "type": "command",
          "command": "python3 ~/.claude/hooks/session-to-obsidian.py"
        }]
      }
    ]
  }
}
```

## Output Format

Each exported note has this structure:

**1. YAML frontmatter**
Fields: `date`, `type: session-log`, `tags` (always includes `claude-session`, plus a project slug if matched), `session_id`, `cwd`, `git_branch`, `claude_version`.

**2. H1 title**
Derived from the first user message, truncated to 60 characters and sanitized for use as a filename.

**3. Metadata block**
Plain key/value lines: Date, Duration (calculated from first and last timestamps), Turns, Working Dir, Branch. If `PROJECT_MAP` produced a match, a "Related" line with wikilinks follows.

**4. Conversation**
One section per turn. Each turn shows the user message (capped at 300 chars), an italicized tools list if any tools ran, and the assistant response (capped at 500 chars) as a blockquote.

**5. Tools Used**
Aggregated counts across all turns, sorted by frequency. Top 15 tools shown.

**6. Files Touched**
Deduplicated list of file paths extracted from tool inputs. Up to 30 paths shown.

**7. Raw Transcript**
A relative link to `_raw/<session_id>.jsonl`.

## Troubleshooting

**Notes are not appearing in the vault.**
Check three things in order: (1) `OBSIDIAN_VAULT` points to the right path, (2) the hook is registered in `settings.json`, (3) the log file at `~/.claude/session-export.log` shows what happened.

**The log shows "vault not found."**
Set the `OBSIDIAN_VAULT` environment variable, or edit `VAULT_ROOT_FALLBACK` directly in the script. The hook exits cleanly on vault-not-found to avoid blocking session close.

**The log shows "empty session."**
The session had no user turns after stripping system tags. This is expected for very short or purely automated sessions.

**Notes are duplicated.**
This should not happen: deduplication matches on `session_id` in frontmatter. If you see duplicates, they likely have different session IDs and are genuinely separate sessions.
