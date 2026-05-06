#!/usr/bin/env bash
# Proper audit: compare snapshot/edited against the post-sync HEAD content
# (extracted via `git show HEAD:relpath`), not against the live working tree
# (which still contains our edits because force-sync did not reset them).
set -uo pipefail

SNAP=/mnt/c/Dev/Solutions/com.bhengubv/CircleOS/amarula/_ohos_patches_take_snapshot
EDITED=$SNAP/edited
ORIGINAL=$SNAP/original
LIVE=/root/ohos
TMP=/tmp/audit_head
mkdir -p "$TMP"
rm -rf "$TMP"/*

group_a=(
  "productdefine/common/products/amarula.json"
  "build/toolchain/concurrent_links.gni"
  "build/config/compiler/BUILD.gn"
  "build/toolchain/rustc_wrapper.py"
  "build/compile_standard_whitelist.json"
  "arkcompiler/ets_frontend/arkguard/compile_arkguard.py"
  "third_party/typescript/compile_typescript.py"
  "foundation/multimedia/av_session/frameworks/native/session/test/unittest/BUILD.gn"
  "foundation/multimedia/av_session/services/session/server/test/BUILD.gn"
)

# Find which project a relpath belongs to (walk up looking for .git)
find_project_root() {
  local f="$LIVE/$1"
  local d
  d=$(dirname "$f")
  while [ "$d" != "$LIVE" ] && [ "$d" != "/" ]; do
    if [ -d "$d/.git" ]; then
      echo "$d"
      return
    fi
    d=$(dirname "$d")
  done
  return 1
}

printf "%-80s %-20s %s\n" "FILE" "VERDICT" "NOTE"
printf "%-80s %-20s %s\n" "$(printf '=%.0s' {1..80})" "$(printf '=%.0s' {1..20})" "$(printf '=%.0s' {1..40})"

for rel in "${group_a[@]}"; do
  ed="$EDITED/$rel"
  orig="$ORIGINAL/$rel"

  if [ ! -f "$ed" ]; then
    printf "%-80s %-20s %s\n" "$rel" "MISSING_SNAPSHOT" "not in snapshot"
    continue
  fi

  proj=$(find_project_root "$rel")
  if [ -z "$proj" ]; then
    printf "%-80s %-20s %s\n" "$rel" "NO_PROJECT_FOUND" "could not find .git"
    continue
  fi

  # Path of the file relative to its project root
  filerel=${rel#${proj#$LIVE/}/}
  # Extract HEAD version after sync
  head_file="$TMP/$rel.head"
  mkdir -p "$(dirname "$head_file")"
  if ! git -C "$proj" show "HEAD:$filerel" > "$head_file" 2>/dev/null; then
    # NEW file (not in HEAD)
    rm -f "$head_file"
    if [ -f "$orig" ]; then
      printf "%-80s %-20s %s\n" "$rel" "WAS_DELETED_UPSTREAM" "we have edit but file no longer in upstream HEAD"
    else
      printf "%-80s %-20s %s\n" "$rel" "NEW_KEEP" "our addition; not in upstream"
    fi
    continue
  fi

  # We have: orig (pre-sync HEAD), ed (our edit), head_file (post-sync HEAD)
  if [ ! -f "$orig" ]; then
    # NEW file but it suddenly exists in upstream — surprising
    printf "%-80s %-20s %s\n" "$rel" "UPSTREAM_ADDED" "we created it; upstream now also has one"
    continue
  fi

  # Did upstream change this file since our snapshot?
  if cmp -s "$orig" "$head_file"; then
    upstream_changed="no"
  else
    upstream_changed="yes"
  fi

  # Does post-sync upstream now match our edited version?
  if cmp -s "$ed" "$head_file"; then
    matches_ours="yes"
  else
    matches_ours="no"
  fi

  if [ "$matches_ours" = "yes" ]; then
    printf "%-80s %-20s %s\n" "$rel" "DROP_UPSTREAM_CAUGHT_UP" "upstream HEAD now matches our edit"
  elif [ "$upstream_changed" = "no" ]; then
    printf "%-80s %-20s %s\n" "$rel" "REAPPLY_CLEAN" "upstream unchanged; reapply our patch"
  else
    printf "%-80s %-20s %s\n" "$rel" "CONFLICT_REVIEW" "upstream changed AND ours differs from new HEAD"
  fi
done

echo
echo "=== diff details for CONFLICT_REVIEW files ==="
for rel in "${group_a[@]}"; do
  ed="$EDITED/$rel"
  orig="$ORIGINAL/$rel"
  head_file="$TMP/$rel.head"
  [ -f "$ed" ] && [ -f "$orig" ] && [ -f "$head_file" ] || continue
  if ! cmp -s "$orig" "$head_file" && ! cmp -s "$ed" "$head_file"; then
    echo "----- $rel -----"
    echo "    upstream changed: HEAD diff vs our snapshot original"
    diff "$orig" "$head_file" | head -30
    echo "    our patch: edit vs snapshot original"
    diff "$orig" "$ed" | head -30
    echo
  fi
done
