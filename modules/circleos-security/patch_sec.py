#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# #142 declare CIRCLE_* framework permissions + #136 register CircleSecurityService.
# Run from the AOSP root.
import sys

# ── 1. Declare the framework permissions ──
M = "frameworks/base/core/res/AndroidManifest.xml"
s = open(M, encoding="utf-8").read()
if "CIRCLE_MESH_SEND" in s:
    print("perms already declared")
else:
    anchor = (
        '    <permission android:name="android.permission.CAMERA_OPEN_CLOSE_LISTENER"\n'
        '        android:permissionGroup="android.permission-group.UNDEFINED"\n'
        '        android:label="@string/permlab_cameraOpenCloseListener"\n'
        '        android:description="@string/permdesc_cameraOpenCloseListener"\n'
        '        android:protectionLevel="signature" />\n'
    )
    if anchor not in s:
        print("FAIL: perms anchor not found"); sys.exit(1)
    perms = (
        '\n'
        '    <!-- ===== Circle OS platform permissions (#142). Signature-only: held by\n'
        '         platform-signed Circle apps/services. ===== -->\n'
        '    <!-- Send a message through / query the CircleMeshService (circle.mesh). -->\n'
        '    <permission android:name="android.permission.CIRCLE_MESH_SEND"\n'
        '        android:protectionLevel="signature" />\n'
        '    <permission android:name="android.permission.CIRCLE_MESH_QUERY"\n'
        '        android:protectionLevel="signature" />\n'
        '    <!-- Quarantine a file (circle.quarantine); used by the TrafficLobby VPN. -->\n'
        '    <permission android:name="android.permission.CIRCLE_SECURITY_QUARANTINE"\n'
        '        android:protectionLevel="signature" />\n'
        '    <!-- OTA control plane (CircleUpdateService). -->\n'
        '    <permission android:name="za.co.circleos.permission.MANAGE_OTA"\n'
        '        android:protectionLevel="signature" />\n'
        '    <permission android:name="za.co.circleos.permission.QUERY_OTA"\n'
        '        android:protectionLevel="signature" />\n'
        '    <permission android:name="za.co.circleos.permission.TRIGGER_OTA"\n'
        '        android:protectionLevel="signature" />\n'
        '    <!-- Privacy control plane (CirclePrivacyManagerService / CirclePermissionService). -->\n'
        '    <permission android:name="za.co.circleos.permission.MANAGE_PRIVACY"\n'
        '        android:protectionLevel="signature" />\n'
        '    <permission android:name="za.co.circleos.permission.QUERY_PRIVACY"\n'
        '        android:protectionLevel="signature" />\n'
    )
    s = s.replace(anchor, anchor + perms, 1)
    open(M, "w", encoding="utf-8").write(s)
    print("perms declared")

# ── 2. Register CircleSecurityService in SystemServer ──
SS = "frameworks/base/services/java/com/android/server/SystemServer.java"
t = open(SS, encoding="utf-8").read()
if "CircleSecurityService" in t:
    print("CircleSecurityService already registered")
else:
    anchor2 = (
        '        t.traceBegin("StartCircleMeshService");\n'
        '        mSystemServiceManager.startService(\n'
        '                com.circleos.server.mesh.CircleMeshService.class);\n'
        '        t.traceEnd();\n'
    )
    if anchor2 not in t:
        print("FAIL: SystemServer mesh anchor not found"); sys.exit(1)
    reg = (
        '\n'
        '        t.traceBegin("StartCircleSecurityService");\n'
        '        mSystemServiceManager.startService(\n'
        '                com.circleos.server.security.CircleSecurityService.class);\n'
        '        t.traceEnd();\n'
    )
    t = t.replace(anchor2, anchor2 + reg, 1)
    open(SS, "w", encoding="utf-8").write(t)
    print("CircleSecurityService registered")
