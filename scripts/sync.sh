#!/usr/bin/env bash
# circleos-gsi: sync AOSP source.
# Heavy: ~150 GB on disk, multi-hour download. Resumable — safe to re-run.
#
# Override defaults via env vars:
#   AOSP_DIR     where to check out (default: $HOME/aosp)
#   AOSP_BRANCH  manifest branch / tag (default: android-15.0.0_r20)
#   JOBS         parallel sync jobs (default: nproc)

set -euo pipefail

AOSP_DIR="${AOSP_DIR:-${HOME}/aosp}"
AOSP_BRANCH="${AOSP_BRANCH:-android-15.0.0_r20}"
JOBS="${JOBS:-$(nproc)}"

if ! command -v repo >/dev/null; then
    echo "repo tool not found. Run ./scripts/setup.sh first." >&2
    exit 1
fi

mkdir -p "$AOSP_DIR"
cd "$AOSP_DIR"

if [ ! -d .repo ]; then
    echo "[+] repo init  branch=$AOSP_BRANCH"
    repo init -u https://android.googlesource.com/platform/manifest \
        -b "$AOSP_BRANCH" \
        --partial-clone --clone-filter=blob:limit=10M
fi

echo "[+] repo sync  -j${JOBS}  (this is the slow part — hours)"
repo sync -c -j"$JOBS" --fail-fast --force-sync --no-clone-bundle

echo ""
echo "[+] AOSP $AOSP_BRANCH synced to $AOSP_DIR"
echo "[+] Disk free on /:  $(df -h / | tail -1 | awk '{print $4}')"
echo "[+] Next: ./scripts/build.sh"
