#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Register DeviceEnrollment (UPD-2) in SystemServer, after CrashReporter.
import sys
SS = "frameworks/base/services/java/com/android/server/SystemServer.java"
t = open(SS, encoding="utf-8").read()
if "DeviceEnrollment" in t:
    print("DeviceEnrollment already registered"); sys.exit(0)
anchor = (
    '        t.traceBegin("StartCircleCrashReporter");\n'
    '        mSystemServiceManager.startService(\n'
    '                com.circleos.server.update.CrashReporter.class);\n'
    '        t.traceEnd();\n'
)
if anchor not in t:
    print("FAIL: CrashReporter anchor not found"); sys.exit(1)
reg = (
    '\n'
    '        t.traceBegin("StartCircleDeviceEnrollment");\n'
    '        mSystemServiceManager.startService(\n'
    '                com.circleos.server.update.DeviceEnrollment.class);\n'
    '        t.traceEnd();\n'
)
open(SS, "w", encoding="utf-8").write(t.replace(anchor, anchor + reg, 1))
print("DeviceEnrollment registered")
