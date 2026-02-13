#!/usr/bin/env bash
#
# backup-product-planning.sh — Sync product-planning/ to Google Drive.
# These contain binary files (pptx, screenshots) that don't belong in git.
#
# NOTE: Uses cp instead of rsync because rsync's temp-file-then-rename
# strategy silently fails on Google Drive's drvfs mount in WSL.
#
set -euo pipefail

SOURCE="$HOME/work/clients/Slabstack/repo/product-planning"
GDRIVE_BASE="/mnt/i/My Drive/NP-brain-backup"
DEST="$GDRIVE_BASE/Slabstack/product-planning"

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

# ─── Clean and copy ─────────────────────────────────────────────
echo "=== product-planning backup ==="
echo "Source: $SOURCE"
echo "Dest:   $DEST"
echo ""

# Copy to temp dir first, then swap — avoids data loss if cp fails partway
DEST_TMP="${DEST}.tmp.$$"

echo "  Copying files..."
cp -r "$SOURCE" "$DEST_TMP"

# Only remove old backup after new copy succeeds
if [[ -d "$DEST" ]]; then
    echo "  Replacing old backup..."
    rm -rf "$DEST"
fi
mv "$DEST_TMP" "$DEST"

# Remove Zone.Identifier files that Windows leaves behind
find "$DEST" -name "*:Zone.Identifier" -delete 2>/dev/null || true

# ─── Verify ──────────────────────────────────────────────────────
src_count=$(find "$SOURCE" -type f ! -name "*:Zone.Identifier" | wc -l)
dest_count=$(find "$DEST" -type f | wc -l)
dest_size=$(du -sh "$DEST" | cut -f1)

echo ""
echo "  Source files: $src_count"
echo "  Backed up:    $dest_count"
echo "  Size:         $dest_size"

if [[ "$src_count" -ne "$dest_count" ]]; then
    echo ""
    echo "  ⚠  WARNING: File count mismatch! Check for copy errors."
else
    echo "  ✓ All files backed up."
fi

echo ""
echo "=== Backup complete ==="
echo "Files at: $DEST"
