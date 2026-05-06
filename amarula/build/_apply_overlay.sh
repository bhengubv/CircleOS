#!/usr/bin/env bash
# Phase 3: reset live tree to clean upstream HEAD, then re-apply our overlay.
set -euo pipefail

AMARULA=/mnt/c/Dev/Solutions/com.bhengubv/CircleOS/amarula
OVERLAY=$AMARULA/_ohos_patches
SNAP=$AMARULA/_ohos_patches_take_snapshot/edited
LIVE=/root/ohos

echo "===STEP_1_COPY_SNAPSHOT_TO_OVERLAY==="
# Group A files we still need to add to the overlay
patches=(
  "build/toolchain/rustc_wrapper.py"
  "build/compile_standard_whitelist.json"
  "arkcompiler/ets_frontend/arkguard/compile_arkguard.py"
  "third_party/typescript/compile_typescript.py"
  "foundation/multimedia/av_session/frameworks/native/session/test/unittest/BUILD.gn"
  "foundation/multimedia/av_session/services/session/server/test/BUILD.gn"
)

for f in "${patches[@]}"; do
  src=$SNAP/$f
  dst=$OVERLAY/$f
  if [ ! -f "$src" ]; then
    echo "MISSING_IN_SNAPSHOT: $f"
    continue
  fi
  mkdir -p "$(dirname "$dst")"
  cp -f "$src" "$dst"
  echo "  copied: $f"
done

echo
echo "===STEP_2_RESET_LIVE_TREE==="
cd "$LIVE"
# Hard-reset every project, drop untracked files (but spare .repo)
repo forall -c bash -c 'git reset --hard HEAD 2>&1 | tail -1; git clean -fd 2>&1 | grep -v "^Removing $" | head -5' 2>&1 | tail -40 || true
echo
echo "Quick sanity — should now be clean:"
cd "$LIVE/build"
git status --short | head -5 || echo "(clean)"

echo
echo "===STEP_3_RUN_OVERLAY==="
bash "$AMARULA/build/overlay.sh"

echo
echo "===STEP_4_VERIFY==="
echo "--- concurrent_links.gni ---"
grep -n "AMARULA OVERLAY\|concurrent_links = 2" "$LIVE/build/toolchain/concurrent_links.gni" | head -3
echo "--- BUILD.gn thinlto ---"
grep -n "thinlto-jobs=2\|lldltojobs=2" "$LIVE/build/config/compiler/BUILD.gn" | head -3
echo "--- rustc_wrapper.py clippy fallback ---"
grep -n "Fallback: rustc directly" "$LIVE/build/toolchain/rustc_wrapper.py" | head -3
echo "--- compile_standard_whitelist.json bluetooth ---"
grep -c "libbt_vendor" "$LIVE/build/compile_standard_whitelist.json"
echo "--- amarula.json product ---"
ls -la "$LIVE/productdefine/common/products/amarula.json"
echo "--- arkguard timeout ---"
grep -n "timeout=1800\|timeout=300" "$LIVE/arkcompiler/ets_frontend/arkguard/compile_arkguard.py" | head -3
echo "--- typescript timeout ---"
grep -n "timeout=600\|timeout=120" "$LIVE/third_party/typescript/compile_typescript.py" | head -3

echo
echo "OVERLAY_APPLIED_DONE"
