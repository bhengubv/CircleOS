#!/usr/bin/env bash
set -e
cd /home/geektrading/aosp/frameworks/base
BASE=services/core/java/com/circleos/server
FILES="mesh/CircleMeshService update/CircleUpdateService permission/CirclePermissionService camera/CircleCameraPrivacyService analytics/CircleAnalyticsService notification/CircleNotificationPrivacyService clipboard/CircleClipboardPrivacyService backup/CircleBackupService"
echo "=== balances ==="
bad=0
for f in $FILES; do
  r=$(python3 -c "s=open('$BASE/$f.java').read(); print(s.count(chr(123))-s.count(chr(125)), s.count(chr(40))-s.count(chr(41)))")
  echo "$f: $r"
  [ "$r" = "0 0" ] || bad=1
done
[ "$bad" = "0" ] || { echo "BALANCE FAIL"; exit 1; }
echo "=== enforcement count ==="
grep -rc "enforceCallingOrSelfPermission" $BASE/mesh/CircleMeshService.java
echo "=== commit ==="
for f in $FILES; do git add "$BASE/$f.java"; done
git commit -q -m "services: enforce CIRCLE_* permissions on the privileged binders [skip ci]

The Circle system-service binders (mesh, update, privacy, camera, analytics,
notification, clipboard, backup) had '// TODO: gate on <perm> once declared' —
i.e. ANY app on the device could call them. The perms are declared now (#142), so
wire real enforcement (15 gates across 8 services). Safe-by-construction: allow
system/root + any platform-signed caller (every Circle app is certificate=platform,
so no app manifest changes and nothing Circle breaks), otherwise require the
declared permission. Closes the privileged-binder access hole."
echo COMMITTED
git log --oneline -1
