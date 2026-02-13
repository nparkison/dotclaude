#!/usr/bin/env bash
#
# backup-all.sh — Run all backups in one shot.
# Designed to be called by cron or manually.
#
#   1. Syncs Claude Code config → dotclaude repo
#   2. Commits and pushes to GitHub (if changes exist)
#   3. Copies product-planning → Google Drive (if mounted)
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$SCRIPT_DIR/backup.log"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

log() { echo "[$TIMESTAMP] $*" >> "$LOG"; }

log "=== backup-all started ==="

# ─── 1. Sync Claude Code config ─────────────────────────────────
log "Running sync.sh..."
if "$SCRIPT_DIR/sync.sh" >> "$LOG" 2>&1; then
    log "sync.sh completed"
else
    log "sync.sh failed (exit $?)"
fi

# ─── 2. Commit and push to GitHub ───────────────────────────────
cd "$SCRIPT_DIR"

# Stage all changes
git add -A

# Only commit if there are actual changes
if ! git diff --cached --quiet; then
    CHANGED=$(git diff --cached --name-only | wc -l)
    git commit -m "auto-backup: $CHANGED file(s) updated $(date '+%Y-%m-%d')" >> "$LOG" 2>&1

    if git push >> "$LOG" 2>&1; then
        log "Pushed $CHANGED changed file(s) to GitHub"
    else
        log "WARNING: git push failed — will retry next run"
    fi
else
    log "No config changes to commit"
fi

# ─── 3. Backup product-planning to Google Drive ─────────────────
GDRIVE="/mnt/i/My Drive/NP-brain-backup"

if [[ -d "$GDRIVE" ]]; then
    log "Running product-planning backup..."
    if "$SCRIPT_DIR/backup-product-planning.sh" >> "$LOG" 2>&1; then
        log "Product-planning backup completed"
    else
        log "Product-planning backup failed (exit $?)"
    fi
else
    log "Google Drive not mounted — skipping product-planning backup"
    log "  Mount with: sudo mount -t drvfs I: /mnt/i"
fi

log "=== backup-all finished ==="
echo "" >> "$LOG"
