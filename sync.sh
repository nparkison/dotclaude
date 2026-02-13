#!/usr/bin/env bash
#
# sync.sh — Copy Claude Code config from live locations into this repo.
# Run this before committing to capture your latest changes.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="$HOME/.claude"
AGENTS_HOME="$HOME/.agents"
SLABSTACK_REPO="$HOME/work/clients/Slabstack/repo"

echo "=== dotclaude sync ==="
echo "Syncing from live config → repo..."
echo ""

# ─── Global config ───────────────────────────────────────────────
echo "  [1/5] Global config (~/.claude/)"
mkdir -p "$SCRIPT_DIR/global/commands"
mkdir -p "$SCRIPT_DIR/global/plugins"

# Core config files
for f in CLAUDE.md hooks.json settings.json settings.local.json config.json; do
    if [[ -f "$CLAUDE_HOME/$f" ]]; then
        cp "$CLAUDE_HOME/$f" "$SCRIPT_DIR/global/$f"
        echo "        ✓ $f"
    fi
done

# Custom commands
if [[ -d "$CLAUDE_HOME/commands" ]]; then
    rsync -a --delete "$CLAUDE_HOME/commands/" "$SCRIPT_DIR/global/commands/"
    echo "        ✓ commands/ ($(ls "$CLAUDE_HOME/commands/" | wc -l) files)"
fi

# Skills (exclude symlinks — copy actual content only)
if [[ -d "$CLAUDE_HOME/skills" ]]; then
    mkdir -p "$SCRIPT_DIR/global/skills"
    # Copy non-symlink skill directories
    for skill_dir in "$CLAUDE_HOME/skills"/*/; do
        if [[ -d "$skill_dir" && ! -L "${skill_dir%/}" ]]; then
            skill_name="$(basename "$skill_dir")"
            rsync -a --delete "$skill_dir" "$SCRIPT_DIR/global/skills/$skill_name/"
            echo "        ✓ skills/$skill_name/"
        fi
    done
fi

# Plugin config (not caches)
for f in config.json installed_plugins.json known_marketplaces.json; do
    if [[ -f "$CLAUDE_HOME/plugins/$f" ]]; then
        cp "$CLAUDE_HOME/plugins/$f" "$SCRIPT_DIR/global/plugins/$f"
        echo "        ✓ plugins/$f"
    fi
done

# ─── Agents (skill targets) ─────────────────────────────────────
echo ""
echo "  [2/5] Agent skills (~/.agents/)"
if [[ -d "$AGENTS_HOME/skills" ]]; then
    mkdir -p "$SCRIPT_DIR/agents/skills"
    rsync -a --delete "$AGENTS_HOME/skills/" "$SCRIPT_DIR/agents/skills/"
    echo "        ✓ agents/skills/ ($(ls "$AGENTS_HOME/skills/" 2>/dev/null | wc -l) skills)"
fi

# ─── Project memory files ────────────────────────────────────────
echo ""
echo "  [3/5] Project memory files (~/.claude/projects/)"
# Map of project directory names → friendly names
declare -A PROJECT_MAP=(
    ["-home-npark-work-clients-Slabstack-repo"]="slabstack-repo"
    ["-mnt-c-Users-npark-OneDrive-Documents-Projects-Tucked"]="tucked"
    ["-home-npark-work-clients-Slabstack-Hiring"]="slabstack-hiring"
    ["-home-npark-work-clients-Slabstack-LogRocket-Custom-MCP"]="logrocket-mcp"
    ["-home-npark-work-clients-Slabstack-LogRocket-Custom-MCP-logrocket-mcp"]="logrocket-mcp-sub"
    ["-home-npark-work-clients-Slabstack-repo-product-planning-Bulk-Price-Increase"]="bulk-price-increase"
    ["-home-npark-work-clients-Slabstack-repo-product-planning-content"]="content"
    ["-home-npark-work-clients-Sysdyne-istrada-web"]="istrada-web"
    ["-mnt-c-Users-npark-OneDrive-Documents-Projects-NP-Clone"]="np-clone"
    ["-home-npark"]="home"
)

for project_dir in "$CLAUDE_HOME/projects"/*/; do
    project_name="$(basename "$project_dir")"
    friendly_name="${PROJECT_MAP[$project_name]:-$project_name}"
    memory_dir="$project_dir/memory"

    if [[ -d "$memory_dir" ]]; then
        mkdir -p "$SCRIPT_DIR/projects/$friendly_name"
        rsync -a --delete "$memory_dir/" "$SCRIPT_DIR/projects/$friendly_name/"
        file_count=$(find "$memory_dir" -name "*.md" | wc -l)
        echo "        ✓ $friendly_name/ ($file_count files)"
    fi
done

# ─── Slabstack project config ───────────────────────────────────
echo ""
echo "  [4/5] Slabstack project config (<repo>/.claude/)"
mkdir -p "$SCRIPT_DIR/slabstack-project/docs"

if [[ -d "$SLABSTACK_REPO/.claude/docs" ]]; then
    rsync -a --delete "$SLABSTACK_REPO/.claude/docs/" "$SCRIPT_DIR/slabstack-project/docs/"
    echo "        ✓ docs/ ($(ls "$SLABSTACK_REPO/.claude/docs/" | wc -l) files)"
fi

for f in settings.json settings.local.json; do
    if [[ -f "$SLABSTACK_REPO/.claude/$f" ]]; then
        cp "$SLABSTACK_REPO/.claude/$f" "$SCRIPT_DIR/slabstack-project/$f"
        echo "        ✓ $f"
    fi
done

# ─── Summary ─────────────────────────────────────────────────────
echo ""
echo "  [5/5] Checking for sensitive files..."
if find "$SCRIPT_DIR" -name ".credentials.json" -o -name "*.secret" -o -name "*.key" 2>/dev/null | grep -q .; then
    echo "        ⚠  WARNING: Sensitive files detected! Check .gitignore."
else
    echo "        ✓ No sensitive files found."
fi

echo ""
echo "=== Sync complete ==="
echo "Review changes with: git -C '$SCRIPT_DIR' status"
echo "Then commit and push when ready."
