#!/usr/bin/env bash
# Amarula — pull OH 5.1.0 Release source into ~/ohos. ~45GB. First run: 3–6h on HDD, then overnight build.
# Re-runs are incremental and much faster.
# Note: OH moved from Gitee to Gitcode in Sept 2025. Branch OH-6.1 planned June 2026.
set -euo pipefail

OHOS_DIR="${OHOS_DIR:-$HOME/ohos}"
OHOS_BRANCH="${OHOS_BRANCH:-OpenHarmony-5.1.0-Release}"
OHOS_MANIFEST_URL="${OHOS_MANIFEST_URL:-https://gitcode.com/openharmony/manifest.git}"

echo "[amarula/sync] target: $OHOS_DIR"
echo "[amarula/sync] branch: $OHOS_BRANCH"
mkdir -p "$OHOS_DIR"
cd "$OHOS_DIR"

if [ ! -d ".repo" ]; then
  echo "[amarula/sync] repo init..."
  repo init -u "$OHOS_MANIFEST_URL" -b "$OHOS_BRANCH" --no-clone-bundle --depth=1
fi

echo "[amarula/sync] configuring git for large remote transfers..."
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999

echo "[amarula/sync] repo sync (this takes hours on first run)..."
# Use -j4 to avoid overwhelming Gitcode from overseas. Retry on failure — repo sync resumes.
SYNC_OK=0
for attempt in 1 2 3 4 5; do
  echo "[amarula/sync] sync attempt $attempt..."
  repo sync -c -j4 --no-clone-bundle --no-tags --force-sync && SYNC_OK=1 && break
  echo "[amarula/sync] sync failed, retrying in 30s..."
  sleep 30
done
if [ "$SYNC_OK" != "1" ]; then
  echo "[amarula/sync] ERROR: sync failed after 5 attempts. Re-run sync.sh to resume."
  exit 1
fi

echo "[amarula/sync] downloading prebuilt toolchains..."
bash build/prebuilts_download.sh

echo "[amarula/sync] done. source at $OHOS_DIR"
echo "next: run ./overlay.sh to drop Amarula's product config into the tree, then ./build.sh"
