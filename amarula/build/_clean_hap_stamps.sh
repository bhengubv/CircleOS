#!/usr/bin/env bash
# Wipe stale HAP-related stamps so ninja rebuilds them properly.
# Keeps all C++ object files and ccache work intact.
set -uo pipefail

OUT=/root/ohos/out/rk3568/obj
echo "=== before cleanup ==="
date "+%F %T"
echo "compile_app stamps: $(find "$OUT" -name '*_compile_app.stamp' 2>/dev/null | wc -l)"
echo "hap stamps:         $(find "$OUT" -name '*_hap.stamp' 2>/dev/null | wc -l)"
echo

echo "=== deleting ==="
# 1. compile_app stamps — force hvigor rebuild
find "$OUT" -name '*_compile_app.stamp' -delete 2>/dev/null
# 2. hap stamps — force sign re-run
find "$OUT" -name '*_hap.stamp' -delete 2>/dev/null
# 3. hap collect stamps
find "$OUT" -name '*_hap__collect.stamp' -delete 2>/dev/null
# 4. hap notice stamps
find "$OUT" -name '*_hap_notice.stamp' -delete 2>/dev/null
# 5. hap info stamps
find "$OUT" -name '*_hap_info.stamp' -delete 2>/dev/null
# 6. dialog_hap.stamp (the inner ones)
find "$OUT" -name 'dialog_hap.stamp' -delete 2>/dev/null

# Also clean any partial hvigor build dirs in HAP source trees
echo "Cleaning hvigor build dirs in HAP sources..."
for d in /root/ohos/base/powermgr /root/ohos/applications/standard /root/ohos/foundation; do
  find "$d" -maxdepth 6 -type d -name "build" -path "*/entry/build" 2>/dev/null | while read -r b; do
    rm -rf "$b"
  done
done

echo
echo "=== after cleanup ==="
echo "compile_app stamps: $(find "$OUT" -name '*_compile_app.stamp' 2>/dev/null | wc -l)"
echo "hap stamps:         $(find "$OUT" -name '*_hap.stamp' 2>/dev/null | wc -l)"
echo "DONE"
