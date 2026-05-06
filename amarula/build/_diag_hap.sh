#!/usr/bin/env bash
# Diagnose the failed power_dialog HAP signing.
set -uo pipefail

PWLIST=/root/ohos/out/rk3568/obj/base/powermgr/power_manager/power_dialog/power_dialog_hap/unsigned_hap_path_list.json

echo "===UNSIGNED_HAP_PATH_LIST==="
if [ -f "$PWLIST" ]; then
  cat "$PWLIST"
else
  echo "MISSING: $PWLIST"
fi
echo
echo "===HAPS_BEING_SIGNED==="
if [ -f "$PWLIST" ]; then
  python3 -c "import json; d=json.load(open('$PWLIST')); print('\n'.join(d) if isinstance(d,list) else '\n'.join(d.values()))" 2>/dev/null | while IFS= read -r f; do
    if [ -f "$f" ]; then
      sz=$(stat -c%s "$f")
      magic=$(head -c4 "$f" | xxd -p)
      echo "  $f -> $sz bytes, magic=$magic (PK\03\04 = 504b0304 = valid zip)"
    else
      echo "  $f -> MISSING"
    fi
  done
fi
echo
echo "===HAP_BUILD_ARTIFACTS==="
find /root/ohos/out/rk3568/obj/base/powermgr/power_manager/power_dialog -maxdepth 4 -name "*.hap" 2>/dev/null | while IFS= read -r f; do
  sz=$(stat -c%s "$f")
  echo "  $f -> $sz bytes"
done
echo
echo "===HVIGORW_LOG_TAIL==="
find /root/ohos/out/rk3568/obj/base/powermgr/power_manager/power_dialog -name "*.log" 2>/dev/null | head -3 | while IFS= read -r f; do
  echo "--- $f ---"
  tail -30 "$f"
done
echo
echo "===HAP_SOURCE_DIR==="
ls -la /root/ohos/base/powermgr/power_manager/power_dialog/ 2>/dev/null | head -20
