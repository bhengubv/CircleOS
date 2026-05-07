#!/usr/bin/env bash
# Clone or pull the CircleOS repo on geektrading2.
set -uo pipefail

cd "$HOME"

echo "=== CLONE_OR_PULL ==="
if [ -d CircleOS ]; then
  echo "Already exists. Pulling latest..."
  cd CircleOS
  git pull origin main 2>&1
else
  echo "Cloning fresh..."
  git clone https://github.com/bhengubv/CircleOS.git 2>&1
fi

echo
echo "=== VERIFY ==="
echo "--- repo HEAD ---"
cd "$HOME/CircleOS"
git log --oneline -3

echo
echo "--- amarula folder ---"
ls "$HOME/CircleOS/amarula/" | head -20

echo
echo "--- key overlay files ---"
for f in \
  amarula/_ohos_patches/build/toolchain/concurrent_links.gni \
  amarula/_ohos_patches/build/config/compiler/BUILD.gn \
  amarula/build/overlay.sh \
  amarula/productdefine/amarula.json
do
  if [ -f "$HOME/CircleOS/$f" ]; then
    echo "OK $f ($(wc -c < "$HOME/CircleOS/$f") bytes)"
  else
    echo "MISSING $f"
  fi
done

echo
echo "=== DONE ==="
