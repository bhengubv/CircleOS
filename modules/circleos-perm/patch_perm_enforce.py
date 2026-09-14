#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Close the "// TODO: gate on <perm> once declared" enforcement stubs across the
# Circle system services. The perms are now declared (#142). Safe enforcement:
# allow system/root (already) + any PLATFORM-SIGNED caller (every Circle app is
# certificate:"platform", so no app manifest needs changing), otherwise require
# the declared permission. Closes the "any app can call these privileged binders"
# hole with zero breakage to Circle apps.
import re, sys

BASE = "frameworks/base/services/core/java/com/circleos/server"
FILES = [
    f"{BASE}/mesh/CircleMeshService.java",
    f"{BASE}/update/CircleUpdateService.java",
    f"{BASE}/permission/CirclePermissionService.java",
    f"{BASE}/camera/CircleCameraPrivacyService.java",
    f"{BASE}/analytics/CircleAnalyticsService.java",
    f"{BASE}/notification/CircleNotificationPrivacyService.java",
    f"{BASE}/clipboard/CircleClipboardPrivacyService.java",
    f"{BASE}/backup/CircleBackupService.java",
]

TODO_RE = re.compile(r'^(\s*)// TODO: gate on ([\w.]+)[^\n]*$', re.M)
total = 0
for f in FILES:
    try:
        s = open(f, encoding="utf-8").read()
    except FileNotFoundError:
        print("skip (missing):", f); continue
    if "checkSignatures(" in s and "enforceCallingOrSelfPermission" in s:
        print("already enforced:", f.split("/")[-1]); continue

    def repl(m):
        indent = m.group(1)
        perm = m.group(2).rstrip(".")
        return (
            f'{indent}// Allow system + any platform-signed Circle app; otherwise require the permission.\n'
            f'{indent}if (getContext().getPackageManager().checkSignatures(\n'
            f'{indent}        android.os.Binder.getCallingUid(), android.os.Process.SYSTEM_UID)\n'
            f'{indent}                == android.content.pm.PackageManager.SIGNATURE_MATCH) return;\n'
            f'{indent}getContext().enforceCallingOrSelfPermission("{perm}", "circle-api");'
        )

    ns, n = TODO_RE.subn(repl, s)
    if n:
        open(f, "w", encoding="utf-8").write(ns)
        total += n
        print(f"enforced {n} in {f.split('/')[-1]}")

print(f"== total gates wired: {total} ==")
if total == 0:
    sys.exit(1)
