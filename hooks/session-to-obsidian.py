#!/usr/bin/env python3
"""
Stop hook: Export Claude Code session transcripts to an Obsidian vault.

Generates a markdown summary with YAML frontmatter and wikilinks, and copies
the raw JSONL to _raw/ for archival. Runs from the Stop hook so it doesn't
block session exit. Skips sessions with no user turns. Deduplicates on
re-export using session_id in frontmatter.

CONFIGURATION:
  Set the environment variable OBSIDIAN_VAULT to your vault root, or edit
  the CONFIG block below. All other paths derive from VAULT_ROOT.

  Example (bash):
    export OBSIDIAN_VAULT="/path/to/your/vault"

  Alternatively, edit the fallback path in the CONFIG section:
    VAULT_ROOT_FALLBACK = Path("/path/to/your/vault")

PROJECT DETECTION (optional):
  Fill in PROJECT_MAP to auto-tag sessions and generate wikilinks based on
  the working directory. Keys are substrings matched against the session's
  cwd; values are the Obsidian note names to link.

  Example:
    PROJECT_MAP = {
        "my-project": "My Project",
        "client-work": "Client Work",
    }

SETUP (.claude/settings.json):
  {
    "hooks": {
      "Stop": [
        { "matcher": "", "hooks": [{ "type": "command", "command": "python3 /path/to/session-to-obsidian.py" }] }
      ]
    }
  }
"""

import json
import os
import sys
import re
import traceback
from datetime import datetime
from pathlib import Path
from collections import Counter

# ── CONFIG ────────────────────────────────────────────────────────────────────

# Primary: set OBSIDIAN_VAULT env var. Fallback: edit the path below.
VAULT_ROOT_FALLBACK = Path("/path/to/your/obsidian/vault")
VAULT_ROOT = Path(os.environ.get("OBSIDIAN_VAULT", str(VAULT_ROOT_FALLBACK)))

# Subdirectory inside the vault where session notes are saved.
# Change this to match your vault's folder structure.
SESSIONS_SUBDIR = "Sessions/Claude Code"

SESSIONS_DIR = VAULT_ROOT / SESSIONS_SUBDIR
RAW_DIR = SESSIONS_DIR / "_raw"

# Standard Claude Code projects directory. Do not change.
CLAUDE_PROJECTS = Path.home() / ".claude" / "projects"

# Log file for debugging export issues.
LOG_FILE = Path.home() / ".claude" / "session-export.log"

# ── PROJECT MAP ───────────────────────────────────────────────────────────────
# Map cwd substrings to Obsidian note names for auto-tagging and wikilinks.
# Leave empty ({}) to disable project detection.
#
# Format:
#   "cwd-substring": "Obsidian Note Name"
#
# Example:
#   PROJECT_MAP = {
#       "my-project": "My Project",
#       "client-work": "Client Work",
#   }

PROJECT_MAP = {}

# ── END CONFIG ────────────────────────────────────────────────────────────────

SYSTEM_TAG_PATTERNS = [
    r'<system-reminder>.*?</system-reminder>',
    r'<local-command-caveat>.*?</local-command-caveat>',
    r'<command-name>.*?</command-name>',
    r'<command-message>.*?</command-message>',
    r'<command-args>.*?</command-args>',
    r'<local-command-stdout>.*?</local-command-stdout>',
    r'<EXTREMELY_IMPORTANT>.*?</EXTREMELY_IMPORTANT>',
    r'<EXTREMELY-IMPORTANT>.*?</EXTREMELY-IMPORTANT>',
    r'<SUBAGENT-STOP>.*?</SUBAGENT-STOP>',
]


def strip_system_tags(text: str) -> str:
    for pattern in SYSTEM_TAG_PATTERNS:
        text = re.sub(pattern, '', text, flags=re.DOTALL)
    return text.strip()


def find_existing_export(session_id: str) -> Path | None:
    if not session_id or not SESSIONS_DIR.exists():
        return None
    for md_file in SESSIONS_DIR.glob("*.md"):
        try:
            with open(md_file, "r", encoding="utf-8") as f:
                for i, line in enumerate(f):
                    if i > 20:
                        break
                    if f"session_id: {session_id}" in line:
                        return md_file
        except Exception:
            continue
    return None


def find_session_file(session_id: str) -> Path | None:
    for project_dir in CLAUDE_PROJECTS.iterdir():
        if not project_dir.is_dir():
            continue
        candidate = project_dir / f"{session_id}.jsonl"
        if candidate.exists():
            return candidate
    for jsonl in CLAUDE_PROJECTS.rglob(f"{session_id}.jsonl"):
        return jsonl
    return None


def find_session_by_cwd(cwd: str) -> Path | None:
    slug = cwd.replace("/", "-").lstrip("-")
    project_dir = CLAUDE_PROJECTS / slug
    if project_dir.is_dir():
        jsonls = sorted(project_dir.glob("*.jsonl"), key=lambda p: p.stat().st_mtime)
        if jsonls:
            return jsonls[-1]
    return None


def parse_session(jsonl_path: Path) -> dict:
    turns = []
    tools_used = Counter()
    files_touched = set()
    session_id = None
    cwd = None
    git_branch = None
    version = None
    start_time = None
    end_time = None
    current_user_msg = None
    current_assistant_texts = []
    current_turn_tools = []
    seen_msg_texts = {}

    with open(jsonl_path, "r") as f:
        for line in f:
            try:
                obj = json.loads(line.strip())
            except json.JSONDecodeError:
                continue

            ts = obj.get("timestamp")
            if ts:
                if start_time is None:
                    start_time = ts
                end_time = ts

            if not session_id:
                session_id = obj.get("sessionId")
            if not cwd:
                cwd = obj.get("cwd")
            if not git_branch:
                git_branch = obj.get("gitBranch")
            if not version:
                version = obj.get("version")

            msg_type = obj.get("type")

            if msg_type == "user":
                msg = obj.get("message", {})
                content = msg.get("content", "")
                if isinstance(content, list):
                    block_types = [b.get("type") for b in content if isinstance(b, dict)]
                    if "tool_result" in block_types:
                        continue
                if isinstance(content, str) and content.strip():
                    if current_user_msg is not None:
                        all_texts = list(seen_msg_texts.values()) + current_assistant_texts
                        combined = " ".join(all_texts).strip()
                        turns.append({
                            "user": current_user_msg,
                            "assistant": combined or "(tools only)",
                            "tools": current_turn_tools,
                        })
                        current_assistant_texts = []
                        current_turn_tools = []
                        seen_msg_texts = {}
                    cleaned = strip_system_tags(content)
                    if not cleaned:
                        continue
                    current_user_msg = cleaned

            elif msg_type not in ("progress", "file-history-snapshot"):
                msg = obj.get("message", {})
                if msg.get("role") == "assistant":
                    msg_id = msg.get("id")
                    content = msg.get("content", [])
                    if isinstance(content, list):
                        for block in content:
                            if not isinstance(block, dict):
                                continue
                            if block.get("type") == "text":
                                text = block["text"].strip()
                                if text and msg_id:
                                    seen_msg_texts[msg_id] = text
                                elif text and not msg_id:
                                    current_assistant_texts.append(text)
                            elif block.get("type") == "tool_use":
                                tool_name = block.get("name", "unknown")
                                tools_used[tool_name] += 1
                                current_turn_tools.append(tool_name)
                                tool_input = block.get("input", {})
                                for key in ("file_path", "path", "filePath"):
                                    fp = tool_input.get(key)
                                    if fp and isinstance(fp, str):
                                        files_touched.add(fp)

    if current_user_msg is not None:
        all_texts = list(seen_msg_texts.values()) + current_assistant_texts
        combined = " ".join(all_texts).strip()
        turns.append({
            "user": current_user_msg,
            "assistant": combined or "(tools only)",
            "tools": current_turn_tools,
        })

    return {
        "session_id": session_id,
        "cwd": cwd,
        "git_branch": git_branch,
        "version": version,
        "start_time": start_time,
        "end_time": end_time,
        "turns": turns,
        "tools_used": tools_used,
        "files_touched": sorted(files_touched),
    }


def infer_topic(data: dict, session_name: str | None = None) -> str:
    if session_name and session_name.strip():
        topic = session_name.strip()
        topic = re.sub(r'[<>:"/\\|?*]', "", topic)
        if len(topic) > 60:
            topic = topic[:57] + "..."
        return topic
    if not data["turns"]:
        return "Untitled Session"
    for turn in data["turns"]:
        msg = turn["user"]
        if not msg or msg == "(tools only)":
            continue
        topic = msg[:80].strip()
        topic = re.sub(r"[#*`\[\]]", "", topic)
        topic = topic.split("\n")[0].strip()
        topic = re.sub(r'[<>:"/\\|?*]', "", topic)
        topic = topic.strip(". ")
        if len(topic) > 60:
            topic = topic[:57] + "..."
        if topic:
            return topic
    return "Untitled Session"


def detect_project(data: dict) -> str | None:
    cwd = data.get("cwd", "") or ""
    for keyword, project_name in PROJECT_MAP.items():
        if keyword.lower() in cwd.lower():
            return project_name
    return None


def generate_wikilinks(data: dict) -> list[str]:
    links = []
    project = detect_project(data)
    if project:
        links.append(f"[[{project}]]")
    return links


def format_duration(start: str, end: str) -> str:
    try:
        s = datetime.fromisoformat(start.replace("Z", "+00:00"))
        e = datetime.fromisoformat(end.replace("Z", "+00:00"))
        delta = e - s
        minutes = int(delta.total_seconds() / 60)
        if minutes < 1:
            return "<1 min"
        elif minutes < 60:
            return f"{minutes} min"
        else:
            hours = minutes // 60
            remaining = minutes % 60
            return f"{hours}h {remaining}m"
    except (ValueError, TypeError):
        return "unknown"


def build_markdown(data: dict, session_name: str | None = None) -> str:
    topic = infer_topic(data, session_name)
    now = datetime.now()
    date_str = now.strftime("%Y-%m-%d")
    tags = ["claude-session"]
    project = detect_project(data)
    if project:
        tag_slug = project.lower().replace(" ", "-")
        tags.append(tag_slug)

    frontmatter = {
        "date": date_str,
        "type": "session-log",
        "tags": tags,
        "session_id": data["session_id"],
        "cwd": data["cwd"],
        "git_branch": data["git_branch"],
        "claude_version": data["version"],
    }

    lines = ["---"]
    lines.append(f"date: {frontmatter['date']}")
    lines.append(f"type: {frontmatter['type']}")
    lines.append("tags:")
    for tag in frontmatter["tags"]:
        lines.append(f"  - {tag}")
    if frontmatter["session_id"]:
        lines.append(f"session_id: {frontmatter['session_id']}")
    if frontmatter["cwd"]:
        lines.append(f"cwd: {frontmatter['cwd']}")
    if frontmatter["git_branch"]:
        lines.append(f"git_branch: {frontmatter['git_branch']}")
    if frontmatter["claude_version"]:
        lines.append(f"claude_version: {frontmatter['claude_version']}")
    lines.append("---")
    lines.append("")
    lines.append(f"# {topic}")
    lines.append("")
    duration = "unknown"
    if data["start_time"] and data["end_time"]:
        duration = format_duration(data["start_time"], data["end_time"])
    lines.append(f"**Date:** {date_str}")
    lines.append(f"**Duration:** {duration}")
    lines.append(f"**Turns:** {len(data['turns'])}")
    if data["cwd"]:
        lines.append(f"**Working Dir:** `{data['cwd']}`")
    if data["git_branch"]:
        lines.append(f"**Branch:** `{data['git_branch']}`")
    lines.append("")
    wikilinks = generate_wikilinks(data)
    if wikilinks:
        lines.append("**Related:** " + " ".join(wikilinks))
        lines.append("")
    lines.append("## Conversation")
    lines.append("")
    for i, turn in enumerate(data["turns"]):
        user_msg = turn["user"][:300]
        if len(turn["user"]) > 300:
            user_msg += "..."
        lines.append(f"**User ({i+1}):** {user_msg}")
        lines.append("")
        if turn["tools"]:
            tool_list = ", ".join(turn["tools"])
            lines.append(f"*Tools: {tool_list}*")
            lines.append("")
        resp = turn["assistant"][:500]
        if len(turn["assistant"]) > 500:
            resp += "..."
        quoted = "\n".join(f"> {line}" for line in resp.split("\n"))
        lines.append(quoted)
        lines.append("")
    if data["tools_used"]:
        lines.append("## Tools Used")
        lines.append("")
        for tool, count in data["tools_used"].most_common(15):
            lines.append(f"- **{tool}**: {count}x")
        lines.append("")
    if data["files_touched"]:
        lines.append("## Files Touched")
        lines.append("")
        for fp in data["files_touched"][:30]:
            lines.append(f"- `{fp}`")
        lines.append("")
    if data["session_id"]:
        lines.append("## Raw Transcript")
        lines.append("")
        lines.append(f"[Raw JSONL](_raw/{data['session_id']}.jsonl)")
        lines.append("")
    return "\n".join(lines)


def log(level: str, message: str, session_id: str = "unknown"):
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    entry = f"[{ts}] [{level}] session={session_id} {message}\n"
    try:
        with open(LOG_FILE, "a") as f:
            f.write(entry)
    except Exception:
        pass


def main():
    try:
        stdin_data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, Exception):
        stdin_data = {}

    session_id = stdin_data.get("session_id", "unknown")
    cwd = stdin_data.get("cwd")
    jsonl_path = None
    transcript_path = stdin_data.get("transcript_path")
    if transcript_path:
        jsonl_path = Path(transcript_path)
    if (not jsonl_path or not jsonl_path.exists()) and session_id != "unknown":
        jsonl_path = find_session_file(session_id)
    if (not jsonl_path or not jsonl_path.exists()) and cwd:
        jsonl_path = find_session_by_cwd(cwd)

    if not jsonl_path or not jsonl_path.exists():
        log("SKIP", "session JSONL not found", session_id)
        sys.exit(0)

    if not VAULT_ROOT.exists():
        log("FAIL", f"vault not found at {VAULT_ROOT}. Set OBSIDIAN_VAULT env var or update VAULT_ROOT_FALLBACK in the script", session_id)
        sys.exit(0)

    data = parse_session(jsonl_path)
    if not data["turns"]:
        log("SKIP", "empty session (no user turns)", session_id)
        sys.exit(0)

    SESSIONS_DIR.mkdir(parents=True, exist_ok=True)
    RAW_DIR.mkdir(parents=True, exist_ok=True)

    session_name = stdin_data.get("session_name") or stdin_data.get("name")
    md_content = build_markdown(data, session_name)
    topic = infer_topic(data, session_name)
    date_str = datetime.now().strftime("%Y-%m-%d")

    existing = find_existing_export(data["session_id"])
    if existing:
        try:
            existing.unlink()
        except Exception:
            pass

    base_name = f"{date_str} {topic}"
    md_path = SESSIONS_DIR / f"{base_name}.md"
    if md_path.exists():
        counter = 1
        while md_path.exists():
            counter += 1
            md_path = SESSIONS_DIR / f"{base_name} ({counter}).md"

    md_path.write_text(md_content, encoding="utf-8")

    raw_dest = RAW_DIR / f"{data['session_id'] or jsonl_path.stem}.jsonl"
    if not raw_dest.exists():
        raw_dest.write_bytes(jsonl_path.read_bytes())

    log("OK", f"exported to {md_path.name} ({len(data['turns'])} turns)", session_id)
    print(json.dumps({"suppressOutput": True}))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        log("ERROR", f"{e}\n{traceback.format_exc()}")
        print(json.dumps({"suppressOutput": True}))
        sys.exit(0)
