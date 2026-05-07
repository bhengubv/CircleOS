#!/usr/bin/env bash
# Clean OH source clone — separate init from sync, verify each.
set -uo pipefail

OHOS_DIR="$HOME/ohos"
MANIFEST_URL="https://github.com/openharmony/manifest"
BRANCH="OpenHarmony-5.1.0-Release"

export PATH="$HOME/.local/bin:$PATH"

# git tuning for slow/large fetches
git config --global http.postBuffer 1048576000
git config --global http.lowSpeedLimit 1000
git config --global http.lowSpeedTime 600
git config --global core.compression 0
git config --global --add safe.directory '*'

echo "==================================="
date '+%F %T %Z'
echo "OH source clone — clean restart"
echo "==================================="

# Wipe partial state
if [ -d "$OHOS_DIR" ]; then
  echo "removing partial $OHOS_DIR..."
  rm -rf "$OHOS_DIR"
fi
mkdir -p "$OHOS_DIR"
cd "$OHOS_DIR"

echo
echo "=== repo init ==="
repo init -u "$MANIFEST_URL" -b "$BRANCH" --no-repo-verify 2>&1
INIT_RC=$?
echo "init exit code: $INIT_RC"

if [ ! -f "$OHOS_DIR/.repo/manifest.xml" ]; then
  echo "FATAL: manifest.xml not created. Init failed."
  ls -la "$OHOS_DIR/.repo/" 2>/dev/null | head -20
  exit 1
fi
echo "manifest.xml present: $(wc -l < "$OHOS_DIR/.repo/manifest.xml") lines"
date '+%F %T %Z'

echo
echo "=== repo sync (this takes 30-90 min, ~50 GB) ==="
date '+%F %T %Z'
repo sync -c -j4 --no-clone-bundle --retry-fetches=3 --force-sync 2>&1
SYNC_RC=$?
echo "sync exit code: $SYNC_RC"
date '+%F %T %Z'

echo
echo "=== SUMMARY ==="
echo "Tree size: $(du -sh "$OHOS_DIR" 2>/dev/null | head -1)"
echo "Project count: $(find "$OHOS_DIR/.repo/projects" -name '*.git' -type d 2>/dev/null | wc -l)"
echo "Disk free: $(df -h "$OHOS_DIR" | tail -1)"
echo
echo "=== DONE rc=$SYNC_RC ==="
