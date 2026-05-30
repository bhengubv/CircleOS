#!/usr/bin/env bash
# Sync the Circle source tree into a local AOSP checkout, then apply our
# upstream patches.
#
# Run this from the root of the CircleOS repo, with $AOSP_DIR pointing at
# a synced AOSP 15 checkout. Defaults to ~/aosp.
#
# What it does:
#   1. Rsyncs vendor/circle/ -> $AOSP_DIR/vendor/circle/
#   2. Applies patches/frameworks-base/*.patch against $AOSP_DIR/frameworks/base
#      using `git apply --check` first, so a partially-applied series can't
#      leave the tree in a half-broken state.
#   3. Optionally drops a sentinel file at $AOSP_DIR/vendor/circle/.synced
#      with the source commit SHA so the build can record it.
#
# Idempotent: re-applying patches is detected and skipped.

set -eo pipefail

AOSP_DIR="${AOSP_DIR:-${HOME}/aosp}"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ ! -d "$AOSP_DIR/frameworks/base" ]; then
    echo "ERROR: $AOSP_DIR/frameworks/base does not exist." >&2
    echo "Set AOSP_DIR to your AOSP 15 checkout, or run scripts/sync.sh first." >&2
    exit 1
fi

echo ">>> 1. Syncing vendor/circle/ -> $AOSP_DIR/vendor/circle/"
mkdir -p "$AOSP_DIR/vendor/circle"
rsync -a --delete \
    --exclude '.git/' \
    --exclude '*.swp' \
    --exclude '__pycache__/' \
    "$SRC_DIR/vendor/circle/" \
    "$AOSP_DIR/vendor/circle/"

echo ">>> 2. Applying patches/frameworks-base/*.patch"
cd "$AOSP_DIR/frameworks/base"
shopt -s nullglob
PATCHES=("$SRC_DIR"/patches/frameworks-base/*.patch)
if [ ${#PATCHES[@]} -eq 0 ]; then
    echo "    (no patches yet)"
else
    for p in "${PATCHES[@]}"; do
        name="$(basename "$p")"
        # Idempotent: detect already-applied patches by trying reverse first.
        if git apply --check -R "$p" >/dev/null 2>&1; then
            echo "    [skip]  $name (already applied)"
            continue
        fi
        if ! git apply --check "$p" >/dev/null 2>&1; then
            echo "    [FAIL]  $name does not apply cleanly." >&2
            echo "            Run: cd $AOSP_DIR/frameworks/base && git apply --reject $p" >&2
            exit 2
        fi
        git apply "$p"
        echo "    [apply] $name"
    done
fi

echo ">>> 3. Writing sentinel"
SHA="$(cd "$SRC_DIR" && git rev-parse --short=12 HEAD 2>/dev/null || echo unknown)"
DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cat > "$AOSP_DIR/vendor/circle/.synced" <<EOF
source = bhengubv/CircleOS
sha    = $SHA
synced = $DATE
host   = $(hostname)
EOF

echo ">>> done. AOSP_DIR=$AOSP_DIR is ready to build."
