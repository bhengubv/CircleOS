#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Register CrashReporter (UPD-3) in SystemServer, right after CircleUpdateService.
import sys
SS = "frameworks/base/services/java/com/android/server/SystemServer.java"
t = open(SS, encoding="utf-8").read()
if "CrashReporter" in t:
    print("CrashReporter already registered"); sys.exit(0)
anchor = (
    '        t.traceBegin("StartCircleUpdateService");\n'
    '        mSystemServiceManager.startService(\n'
    '                com.circleos.server.update.CircleUpdateService.class);\n'
    '        t.traceEnd();\n'
)
if anchor not in t:
    print("FAIL: CircleUpdateService anchor not found"); sys.exit(1)
reg = (
    '\n'
    '        t.traceBegin("StartCircleCrashReporter");\n'
    '        mSystemServiceManager.startService(\n'
    '                com.circleos.server.update.CrashReporter.class);\n'
    '        t.traceEnd();\n'
)
t = t.replace(anchor, anchor + reg, 1)
open(SS, "w", encoding="utf-8").write(t)
print("CrashReporter registered")
