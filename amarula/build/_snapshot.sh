#!/usr/bin/env bash
# Snapshot every modified file in /root/ohos to the overlay folder so they
# survive a `repo sync`. Saves BOTH the current modified version (edited/)
# and the original git HEAD version (original/) so we can audit later.
set -uo pipefail

SNAP=/mnt/c/Dev/Solutions/com.bhengubv/CircleOS/amarula/_ohos_patches_take_snapshot
EDITED=$SNAP/edited
ORIGINAL=$SNAP/original
mkdir -p "$EDITED" "$ORIGINAL"

# Fresh start — wipe any previous snapshot
rm -rf "$EDITED" "$ORIGINAL"
mkdir -p "$EDITED" "$ORIGINAL"

echo "Snapshot dir: $SNAP"
echo

cd /root/ohos

# Walk every project that has modifications.
# repo forall sets REPO_PATH = relative path to project from cwd.
# For each modified file, copy current contents and HEAD contents.
echo "===SCANNING==="
repo forall -c bash -c '
  if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    git status --porcelain 2>/dev/null | while IFS= read -r line; do
      status=${line:0:2}
      f=${line:3}
      # strip surrounding quotes if any
      f=${f#\"}; f=${f%\"}
      # rename: " R " has format "old -> new"; take new
      f=${f##*-> }
      # Skip deletions
      case "$status" in
        " D"|"D "|"DD") continue ;;
      esac
      rel="$REPO_PATH/$f"
      src="/root/ohos/$rel"
      [ -f "$src" ] || continue
      mkdir -p "'"$EDITED"'/$(dirname "$rel")"
      cp -f "$src" "'"$EDITED"'/$rel"
      # Save original HEAD version. We are in the project root inside repo forall.
      mkdir -p "'"$ORIGINAL"'/$(dirname "$rel")"
      if ! git show "HEAD:$f" > "'"$ORIGINAL"'/$rel" 2>/dev/null; then
        # File is new (untracked) — no HEAD version
        rm -f "'"$ORIGINAL"'/$rel"
        echo "NEW $rel"
      else
        echo "MOD $rel"
      fi
    done
  fi
' 2>/dev/null

echo
echo "===SUMMARY==="
echo "Edited files saved:    $(find "$EDITED" -type f 2>/dev/null | wc -l)"
echo "Originals saved:       $(find "$ORIGINAL" -type f 2>/dev/null | wc -l)"
echo
echo "===EDITED_TREE==="
find "$EDITED" -type f 2>/dev/null | sort
