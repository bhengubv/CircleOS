#!/usr/bin/env bash
# Audit each saved patch against the post-sync upstream.
# For each file in edited/:
#   - if also in original/: 3-way comparison (original / edited / live)
#   - else (NEW file): just confirm it's still missing upstream
# Output: tab-separated table with recommendation.
set -uo pipefail

SNAP=/mnt/c/Dev/Solutions/com.bhengubv/CircleOS/amarula/_ohos_patches_take_snapshot
EDITED=$SNAP/edited
ORIGINAL=$SNAP/original
LIVE=/root/ohos

# Files we KNOW are our deliberate patches (Group A from the brief).
# Anything not in this list is treated as "Group B/C" and noted but not analysed deeply.
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

printf "FILE\tSTATUS\tNOTE\n"
for rel in "${group_a[@]}"; do
  ed="$EDITED/$rel"
  orig="$ORIGINAL/$rel"
  live="$LIVE/$rel"

  if [ ! -f "$ed" ]; then
    printf "%s\tMISSING_FROM_SNAPSHOT\twas not captured by the snapshot\n" "$rel"
    continue
  fi

  if [ ! -f "$orig" ]; then
    # NEW file — we created it, no upstream original.
    if [ -f "$live" ]; then
      if cmp -s "$ed" "$live"; then
        printf "%s\tNEW_AND_PRESENT_UPSTREAM\tupstream now has our exact file (rare); drop\n" "$rel"
      else
        printf "%s\tNEW_UPSTREAM_HAS_DIFFERENT\tupstream now has SOMETHING here, manual decide\n" "$rel"
      fi
    else
      printf "%s\tNEW_KEEP\tnot upstream; re-apply ours verbatim\n" "$rel"
    fi
    continue
  fi

  # Have all three: original, edited, live (post-sync upstream)
  if [ ! -f "$live" ]; then
    printf "%s\tUPSTREAM_DELETED\tour file no longer in upstream tree\n" "$rel"
    continue
  fi

  # Compare original (pre-sync HEAD) vs live (post-sync HEAD)
  if cmp -s "$orig" "$live"; then
    upstream_changed="no"
  else
    upstream_changed="yes"
  fi

  # Compare edited (our patch) vs live (post-sync upstream)
  if cmp -s "$ed" "$live"; then
    same_as_live="yes"
  else
    same_as_live="no"
  fi

  if [ "$same_as_live" = "yes" ]; then
    printf "%s\tDROP_UPSTREAM_CAUGHT_UP\tupstream now matches our patched version exactly\n" "$rel"
  elif [ "$upstream_changed" = "no" ] && [ "$same_as_live" = "no" ]; then
    printf "%s\tREAPPLY_CLEAN\tupstream unchanged; re-apply our patch\n" "$rel"
  elif [ "$upstream_changed" = "yes" ] && [ "$same_as_live" = "no" ]; then
    printf "%s\tCONFLICT_REVIEW\tupstream changed AND ours differs; manual diff\n" "$rel"
  else
    printf "%s\tUNKNOWN\t(upstream_changed=%s same_as_live=%s)\n" "$rel" "$upstream_changed" "$same_as_live"
  fi
done

echo
echo "=== conflict files — diff details ==="
for rel in "${group_a[@]}"; do
  ed="$EDITED/$rel"
  orig="$ORIGINAL/$rel"
  live="$LIVE/$rel"
  [ -f "$ed" ] && [ -f "$orig" ] && [ -f "$live" ] || continue
  if ! cmp -s "$orig" "$live" && ! cmp -s "$ed" "$live" && ! cmp -s "$ed" "$orig"; then
    echo "----- $rel -----"
    echo "--- upstream diff: original vs new upstream ---"
    diff "$orig" "$live" | head -40
    echo "--- our patch: original vs our edit ---"
    diff "$orig" "$ed" | head -40
    echo
  fi
done
