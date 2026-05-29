#!/usr/bin/env bash
# circleos-gsi: build the GSI from synced AOSP source.
#
# Override defaults via env vars:
#   AOSP_DIR       checkout dir (default: $HOME/aosp)
#   LUNCH_TARGET   AOSP lunch combo (default: aosp_arm64-trunk_staging-userdebug)

# Note: AOSP's build/envsetup.sh references unset vars ($TOP etc.) and breaks
# under `set -u`. We keep -e and pipefail but drop nounset.
set -eo pipefail

AOSP_DIR="${AOSP_DIR:-${HOME}/aosp}"
LUNCH_TARGET="${LUNCH_TARGET:-aosp_arm64-trunk_staging-userdebug}"

if [ ! -d "$AOSP_DIR/.repo" ]; then
    echo "AOSP not synced at $AOSP_DIR. Run ./scripts/sync.sh first." >&2
    exit 1
fi

# ccache: dramatically speeds up incremental rebuilds (typically 5–10x).
# AOSP only uses host ccache when these env vars are set explicitly.
# scripts/setup.sh already configures ~/.ccache to 50 GB with compression.
export USE_CCACHE="${USE_CCACHE:-1}"
export CCACHE_EXEC="${CCACHE_EXEC:-/usr/bin/ccache}"

cd "$AOSP_DIR"

# shellcheck disable=SC1091
source build/envsetup.sh

lunch "$LUNCH_TARGET"

m -j"$(nproc)" systemimage

OUT="$AOSP_DIR/out/target/product/generic_arm64/system.img"
if [ -f "$OUT" ]; then
    SIZE=$(du -h "$OUT" | awk '{print $1}')
    echo ""
    echo "[+] Built GSI: $OUT  ($SIZE)"
    echo "[+] Push to a device for DSU install:"
    echo "      adb push $OUT /sdcard/Download/system.img"
    echo "      (then: Settings → System → Developer options → DSU Loader → Local image)"
else
    echo "Build did not produce system.img. Check the log above." >&2
    exit 1
fi
