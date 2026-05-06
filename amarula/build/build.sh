#!/usr/bin/env bash
# Amarula — build the OS image.
# First run: 4–8h (HDD bound). ccache + fast-rebuild bring subsequent runs to minutes.
set -euo pipefail

OHOS_DIR="${OHOS_DIR:-$HOME/ohos}"
PRODUCT="${PRODUCT:-amarula}"
FAST="${FAST:-0}"

cd "$OHOS_DIR"

FLAGS=(--product-name "$PRODUCT" --ccache)
if [ "$FAST" = "1" ]; then
  FLAGS+=(--fast-rebuild)
fi

echo "[amarula/build] running: ./build.sh ${FLAGS[*]}"
./build.sh "${FLAGS[@]}" 2>&1 | tee "build-$(date +%Y%m%d-%H%M%S).log"

IMG_DIR="$OHOS_DIR/out/$PRODUCT/packages/phone/images"
if [ -d "$IMG_DIR" ]; then
  echo "[amarula/build] images at: $IMG_DIR"
  ls -lh "$IMG_DIR"
else
  echo "[amarula/build] warning: expected image dir not found: $IMG_DIR"
fi
