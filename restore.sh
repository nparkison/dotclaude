#!/usr/bin/env bash
#
# restore.sh — Restore Claude Code config from this repo to live locations.
# Run this on a new machine after cloning the repo.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="$HOME/.claude"
AGENTS_HOME="$HOME/.agents"
SLABSTACK_REPO="$HOME/work/clients/Slabstack/repo"

echo "=== dotclaude restore ==="
echo ""
echo "This will copy config from the repo into your live Claude Code directories."
echo "Existing files at the destinations will be OVERWRITTEN."
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# ─── Global config ───────────────────────────────────────────────
echo ""
echo "  [1/5] Global config → ~/.claude/"
mkdir -p "$CLAUDE_HOME/commands"
mkdir -p "$CLAUDE_HOME/skills"
mkdir -p "$CLAUDE_HOME/plugins"

for f in CLAUDE.md hooks.json settings.json settings.local.json config.json; do
    if [[ -f "$SCRIPT_DIR/global/$f" ]]; then
        cp "$SCRIPT_DIR/global/$f" "$CLAUDE_HOME/$f"
        echo "        ✓ $f"
    fi
done

if [[ -d "$SCRIPT_DIR/global/commands" ]]; then
    rsync -a "$SCRIPT_DIR/global/commands/" "$CLAUDE_HOME/commands/"
    echo "        ✓ commands/"
fi

if [[ -d "$SCRIPT_DIR/global/skills" ]]; then
    rsync -a "$SCRIPT_DIR/global/skills/" "$CLAUDE_HOME/skills/"
    echo "        ✓ skills/"
fi

for f in config.json installed_plugins.json known_marketplaces.json; do
    if [[ -f "$SCRIPT_DIR/global/plugins/$f" ]]; then
        cp "$SCRIPT_DIR/global/plugins/$f" "$CLAUDE_HOME/plugins/$f"
        echo "        ✓ plugins/$f"
    fi
done

# ─── Agents ──────────────────────────────────────────────────────
echo ""
echo "  [2/5] Agent skills → ~/.agents/"
if [[ -d "$SCRIPT_DIR/agents/skills" ]]; then
    mkdir -p "$AGENTS_HOME/skills"
    rsync -a "$SCRIPT_DIR/agents/skills/" "$AGENTS_HOME/skills/"
    echo "        ✓ agents/skills/"

    # Recreate the symlink in ~/.claude/skills/ if it existed
    if [[ -d "$AGENTS_HOME/skills/react-components" ]]; then
        ln -sfn "$AGENTS_HOME/skills/react-components" "$CLAUDE_HOME/skills/react-components"
        echo "        ✓ Recreated react-components symlink"
    fi
fi

# ─── Project memory files ────────────────────────────────────────
echo ""
echo "  [3/5] Project memory files → ~/.claude/projects/"

# Reverse map: friendly names → project directory names
declare -A REVERSE_MAP=(
    ["slabstack-repo"]="-home-npark-work-clients-Slabstack-repo"
    ["tucked"]="-mnt-c-Users-npark-OneDrive-Documents-Projects-Tucked"
    ["slabstack-hiring"]="-home-npark-work-clients-Slabstack-Hiring"
    ["logrocket-mcp"]="-home-npark-work-clients-Slabstack-LogRocket-Custom-MCP"
    ["logrocket-mcp-sub"]="-home-npark-work-clients-Slabstack-LogRocket-Custom-MCP-logrocket-mcp"
    ["bulk-price-increase"]="-home-npark-work-clients-Slabstack-repo-product-planning-Bulk-Price-Increase"
    ["content"]="-home-npark-work-clients-Slabstack-repo-product-planning-content"
    ["istrada-web"]="-home-npark-work-clients-Sysdyne-istrada-web"
    ["np-clone"]="-mnt-c-Users-npark-OneDrive-Documents-Projects-NP-Clone"
    ["home"]="-home-npark"
)

for project_dir in "$SCRIPT_DIR/projects"/*/; do
    friendly_name="$(basename "$project_dir")"
    real_name="${REVERSE_MAP[$friendly_name]:-$friendly_name}"
    target_dir="$CLAUDE_HOME/projects/$real_name/memory"

    mkdir -p "$target_dir"
    rsync -a "$project_dir" "$target_dir/"
    echo "        ✓ $friendly_name/"
done

# ─── Slabstack project config ───────────────────────────────────
echo ""
echo "  [4/5] Slabstack project config → <repo>/.claude/"

if [[ -d "$SLABSTACK_REPO" ]]; then
    mkdir -p "$SLABSTACK_REPO/.claude/docs"

    if [[ -d "$SCRIPT_DIR/slabstack-project/docs" ]]; then
        rsync -a "$SCRIPT_DIR/slabstack-project/docs/" "$SLABSTACK_REPO/.claude/docs/"
        echo "        ✓ docs/"
    fi

    for f in settings.json settings.local.json; do
        if [[ -f "$SCRIPT_DIR/slabstack-project/$f" ]]; then
            cp "$SCRIPT_DIR/slabstack-project/$f" "$SLABSTACK_REPO/.claude/$f"
            echo "        ✓ $f"
        fi
    done
else
    echo "        ⚠  Slabstack repo not found at $SLABSTACK_REPO — skipping"
    echo "           Update SLABSTACK_REPO in this script if the path differs."
fi

# ─── Done ────────────────────────────────────────────────────────
echo ""
echo "  [5/5] Post-restore notes"
echo "        • Re-authenticate: claude login"
echo "        • Plugin caches will re-download on first run"
echo "        • Check that symlinks resolve correctly"
echo ""
echo "=== Restore complete ==="
