#!/usr/bin/env bash
# Clone OpenHarmony 5.1.0-Release on geektrading2.
# Runs as user geektrading. Should land at ~/ohos with 451 projects.
set -uo pipefail

OHOS_DIR="$HOME/ohos"
MANIFEST_URL="https://gitee.com/openharmony/manifest"
BRANCH="OpenHarmony-5.1.0-Release"

# Tune git for slow/large fetches (same settings as Windows-side fix)
git config --global http.postBuffer 1048576000
git config --global http.lowSpeedLimit 1000
git config --global http.lowSpeedTime 600
git config --global core.compression 0
git config --global --add safe.directory '*'

# Make sure repo is on PATH
export PATH="$HOME/.local/bin:$PATH"

echo "=== STEP 3: clone OpenHarmony 5.1.0-Release ==="
echo "Target:   $OHOS_DIR"
echo "Manifest: $MANIFEST_URL"
echo "Branch:   $BRANCH"
echo

mkdir -p "$OHOS_DIR"
cd "$OHOS_DIR"

# repo init — fast (just sets up .repo/, fetches manifest)
echo "--- repo init ---"
date '+%F %T'
repo init -u "$MANIFEST_URL" -b "$BRANCH" --no-repo-verify 2>&1 | tail -10

# Verify init succeeded
if [ ! -d "$OHOS_DIR/.repo" ]; then
  echo "ERROR: repo init failed"
  exit 1
fi
echo
echo "manifest contents:"
ls "$OHOS_DIR/.repo/" | head -10
echo

# repo sync — slow (~50 GB download, 30-90 min)
echo "--- repo sync ---"
date '+%F %T'
echo "starting sync with -j4 (matches 4 vCPU)..."
repo sync -c -j4 --no-clone-bundle --retry-fetches=3 2>&1 | tee "$HOME/repo_sync.log" | tail -50
echo
date '+%F %T'

echo
echo "=== SUMMARY ==="
echo "Tree size: $(du -sh "$OHOS_DIR" 2>/dev/null | head -1)"
echo "Project count: $(find "$OHOS_DIR/.repo/projects" -name '*.git' -type d 2>/dev/null | wc -l)"
echo "Disk free: $(df -h "$OHOS_DIR" | tail -1)"
echo
echo "=== STEP 3 DONE ==="
