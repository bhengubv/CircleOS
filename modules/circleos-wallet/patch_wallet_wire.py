#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Wire ShongololoWalletService into the build + boot:
#  1. services.core links the wallet AIDL lib (circleos-sdpkt-aidl).
#  2. SystemServer starts the service after the other Circle services.
import sys

BP = "frameworks/base/services/core/Android.bp"
SS = "frameworks/base/services/java/com/android/server/SystemServer.java"

# 1) Android.bp static_libs
s = open(BP, encoding="utf-8").read()
if "circleos-sdpkt-aidl" in s:
    print("Android.bp already wired")
else:
    anchor = '        "android.circleos-java",'
    if anchor not in s:
        print("FAIL: Android.bp anchor"); sys.exit(1)
    s = s.replace(anchor, anchor + '\n        "circleos-sdpkt-aidl",', 1)
    open(BP, "w", encoding="utf-8").write(s)
    print("Android.bp: + circleos-sdpkt-aidl")

# 2) SystemServer registration
j = open(SS, encoding="utf-8").read()
if "ShongololoWalletService" in j:
    print("SystemServer already registers wallet")
else:
    anchor = (
        '        t.traceBegin("StartCircleBackupService");\n'
        '        mSystemServiceManager.startService(\n'
        '                com.circleos.server.backup.CircleBackupService.class);\n'
        '        t.traceEnd();')
    if anchor not in j:
        print("FAIL: SystemServer anchor"); sys.exit(1)
    add = (
        '\n        t.traceBegin("StartShongololoWalletService");\n'
        '        mSystemServiceManager.startService(\n'
        '                com.circleos.server.wallet.ShongololoWalletService.class);\n'
        '        t.traceEnd();')
    j = j.replace(anchor, anchor + add, 1)
    open(SS, "w", encoding="utf-8").write(j)
    print("SystemServer: + ShongololoWalletService")

print("== wallet wiring complete ==")
