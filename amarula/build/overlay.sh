#!/usr/bin/env bash
# Amarula — overlay our productdefine + vendor config onto the OH source tree.
# Copies so the OH build system sees amarula as a first-class product.
set -euo pipefail

OHOS_DIR="${OHOS_DIR:-$HOME/ohos}"
AMARULA_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "[amarula/overlay] source: $AMARULA_DIR"
echo "[amarula/overlay] target: $OHOS_DIR"

mkdir -p "$OHOS_DIR/productdefine/common/products"
cp -v "$AMARULA_DIR/productdefine/amarula.json" "$OHOS_DIR/productdefine/common/products/amarula.json"

mkdir -p "$OHOS_DIR/vendor/circle"
rsync -a --delete "$AMARULA_DIR/vendor/circle/" "$OHOS_DIR/vendor/circle/"

# hihope board ohos.build expects vendor/hihope/${product_name}/bluetooth
mkdir -p "$OHOS_DIR/vendor/hihope/amarula"
rsync -a --delete "$AMARULA_DIR/vendor/hihope/amarula/" "$OHOS_DIR/vendor/hihope/amarula/"

mkdir -p "$OHOS_DIR/device/board/circle"
rsync -a --delete "$AMARULA_DIR/device/board/circle/" "$OHOS_DIR/device/board/circle/"

# Source tree patches — directories that are not vendor/device but need
# targeted file fixes in the OH source tree (no --delete to avoid side effects)
for patch_dir in foundation kernel base third_party arkcompiler; do
  if [ -d "$AMARULA_DIR/$patch_dir" ]; then
    echo "[amarula/overlay] patching $patch_dir/"
    rsync -a "$AMARULA_DIR/$patch_dir/" "$OHOS_DIR/$patch_dir/"
  fi
done

# OHOS source-tree patches under _ohos_patches/ (kept separate from amarula/build/)
if [ -d "$AMARULA_DIR/_ohos_patches" ]; then
  echo "[amarula/overlay] patching _ohos_patches/"
  rsync -a "$AMARULA_DIR/_ohos_patches/" "$OHOS_DIR/"
fi

echo "[amarula/overlay] done."
echo "next: run ./build.sh"
