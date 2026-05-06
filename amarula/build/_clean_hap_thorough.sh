#!/usr/bin/env bash
# Thorough HAP cleanup: remove every HAP project's build/ + entry/build dir,
# plus all HAP-related stamps and per-HAP subdirs in out/.
# Keeps C++ object files (ccache will replay them).
set -uo pipefail

OUT=/root/ohos/out/rk3568/obj
echo "=== START $(date '+%F %T') ==="

# 1. Find all HAP project roots (any dir with hvigorw at the project level)
echo "Finding HAP projects..."
HAP_PROJECTS=$(find /root/ohos -maxdepth 5 -name hvigorw -type f 2>/dev/null | grep -v node_modules | grep -v ".repo" | xargs -I{} dirname {})
echo "Found $(echo "$HAP_PROJECTS" | wc -l) HAP projects"

# 2. For each HAP project, nuke both source-tree build/ dirs
echo "Cleaning source-tree build/ dirs..."
for proj in $HAP_PROJECTS; do
  rm -rf "$proj/build" 2>/dev/null
  rm -rf "$proj/entry/build" 2>/dev/null
  # Also any module-level build dirs
  find "$proj" -maxdepth 3 -type d -name "build" -path "*/build" 2>/dev/null | while read -r b; do
    rm -rf "$b"
  done
done

# 3. Wipe HAP-related stamps in out/
echo "Cleaning HAP stamps..."
find "$OUT" -name '*_compile_app.stamp' -delete 2>/dev/null
find "$OUT" -name '*_hap.stamp' -delete 2>/dev/null
find "$OUT" -name '*_hap__collect.stamp' -delete 2>/dev/null
find "$OUT" -name '*_hap_notice.stamp' -delete 2>/dev/null
find "$OUT" -name '*_hap_info.stamp' -delete 2>/dev/null
find "$OUT" -name '*_hap_app_profile.stamp' -delete 2>/dev/null
find "$OUT" -name '*_hap_app_profile__metadata.stamp' -delete 2>/dev/null
find "$OUT" -name '*_hap_resources.stamp' -delete 2>/dev/null
find "$OUT" -name '*_hap_resources__compile_resources.stamp' -delete 2>/dev/null
find "$OUT" -name '*_hap_resources__metadata.stamp' -delete 2>/dev/null
find "$OUT" -name '*_hap_resources__compile_profile.stamp' -delete 2>/dev/null
find "$OUT" -name '*_hap_js_assets.stamp' -delete 2>/dev/null
find "$OUT" -name '*_hap_js_assets__metadata.stamp' -delete 2>/dev/null
find "$OUT" -name 'dialog_hap.stamp' -delete 2>/dev/null

# 4. Also delete the per-HAP subdirs in out/ that hold metadata JSONs
# These are dirs like obj/applications/standard/dlp_manager/dlp_manager/
# (named the same as the HAP)
echo "Cleaning per-HAP metadata subdirs in out/..."
# The pattern: parent dir name == HAP name. Find all unsigned_hap_path_list.json,
# the dir containing those needs to die.
find "$OUT" -name 'unsigned_hap_path_list.json' 2>/dev/null | while read -r f; do
  rm -rf "$(dirname "$f")"
done

# 5. Delete the global hvigor cache (forces fresh hvigor downloads)
echo "Clearing global hvigor cache..."
rm -rf /root/.hvigor/caches /root/.hvigor/project_caches 2>/dev/null

echo
echo "=== POST CLEANUP CHECK ==="
echo "compile_app stamps remaining: $(find "$OUT" -name '*_compile_app.stamp' 2>/dev/null | wc -l)"
echo "hap stamps remaining:         $(find "$OUT" -name '*_hap.stamp' 2>/dev/null | wc -l)"
echo "unsigned_hap_path_list.json:  $(find "$OUT" -name 'unsigned_hap_path_list.json' 2>/dev/null | wc -l)"
echo "DONE at $(date '+%F %T')"
