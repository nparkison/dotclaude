#!/usr/bin/env bash
#
# backup-product-planning.sh — Sync product-planning/ to Google Drive.
# These contain binary files (pptx, screenshots) that don't belong in git.
#
set -euo pipefail

SOURCE="$HOME/work/clients/Slabstack/repo/product-planning/"
GDRIVE_BASE="/mnt/i/My Drive/NP-brain-backup"
DEST="$GDRIVE_BASE/Slabstack/product-planning/"

# ─── Preflight ───────────────────────────────────────────────────
if [[ ! -d "$SOURCE" ]]; then
    echo "ERROR: Source not found: $SOURCE"
    exit 1
fi

if [[ ! -d "$GDRIVE_BASE" ]]; then
    echo "ERROR: Google Drive not mounted at $GDRIVE_BASE"
    echo ""
    echo "Mount it with:"
    echo "  sudo mkdir -p /mnt/i && sudo mount -t drvfs I: /mnt/i"
    exit 1
fi

# ─── Sync ────────────────────────────────────────────────────────
echo "=== product-planning backup ==="
echo "Source: $SOURCE"
echo "Dest:   $DEST"
echo ""

mkdir -p "$DEST"

# rsync with:
#   -rlptD  archive without group/owner (avoids chgrp errors on Windows mounts)
#   -v      verbose
#   --delete  remove files from dest that no longer exist in source
#   --exclude skip Windows Zone.Identifier files
rsync -rlptDv --delete \
    --exclude="*:Zone.Identifier" \
    "$SOURCE" "$DEST"

echo ""
echo "=== Backup complete ==="
echo "Files synced to: $DEST"
