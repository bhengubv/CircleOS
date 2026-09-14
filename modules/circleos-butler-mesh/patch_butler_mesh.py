#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Wire Butler's mesh send/receive through the E2E gateway (MeshServiceConnection).
# Run from the Butler app dir.
import sys

# Copy + repackage MeshCrypto + PendingStore from CircleMessages into Butler.
OLD_PKG = "za.co.circleos.messages"
NEW_PKG = "za.co.circleos.butler"
for fn in ("MeshCrypto.java", "PendingStore.java"):
    src = "../CircleMessages/src/za/co/circleos/messages/" + fn
    dst = "src/za/co/circleos/butler/" + fn
    t = open(src, encoding="utf-8").read()
    t = t.replace("package " + OLD_PKG + ";", "package " + NEW_PKG + ";", 1)
    open(dst, "w", encoding="utf-8").write(t)
print("copied + repackaged crypto into Butler")

# MeshActivity: pass context to the gateway + decrypt incoming via handleIncoming.
MA = "src/za/co/circleos/butler/MeshActivity.java"
s = open(MA, encoding="utf-8").read()
if "handleIncoming" in s:
    print("MeshActivity already wired")
else:
    if "mMesh = new MeshServiceConnection();" not in s:
        print("FAIL: MeshActivity constructor not found"); sys.exit(1)
    s = s.replace("mMesh = new MeshServiceConnection();",
                  "mMesh = new MeshServiceConnection(this);", 1)
    old = (
        '            String senderId = intent.getStringExtra(EXTRA_SENDER_ID);\n'
        '            String text     = intent.getStringExtra(EXTRA_MSG_TEXT);\n'
        '            if (text == null) return;\n'
        '            String label = (senderId != null && senderId.length() >= 8)\n'
        '                    ? senderId.substring(0, 8) + "…"\n'
        '                    : "Peer";\n'
        '            addMessage(new ChatMessage(label, text, false));'
    )
    new = (
        '            String senderId = intent.getStringExtra(EXTRA_SENDER_ID);\n'
        '            String wire     = intent.getStringExtra(EXTRA_MSG_TEXT);\n'
        '            if (wire == null) return;\n'
        '            String text = mMesh.handleIncoming(senderId, wire);\n'
        '            if (text == null) return; // handshake / undecryptable\n'
        '            String label = (senderId != null && senderId.length() >= 8)\n'
        '                    ? senderId.substring(0, 8) + "…"\n'
        '                    : "Peer";\n'
        '            addMessage(new ChatMessage(label, text, false));'
    )
    if old not in s:
        print("FAIL: MeshActivity receiver block not matched"); sys.exit(1)
    s = s.replace(old, new, 1)
    open(MA, "w", encoding="utf-8").write(s)
    print("MeshActivity wired")

# MeshMessageReceiver: decrypt before notifying.
MR = "src/za/co/circleos/butler/MeshMessageReceiver.java"
r = open(MR, encoding="utf-8").read()
if "handleIncoming" in r:
    print("MeshMessageReceiver already wired")
else:
    old = (
        '        String senderId = intent.getStringExtra(MeshActivity.EXTRA_SENDER_ID);\n'
        '        String text     = intent.getStringExtra(MeshActivity.EXTRA_MSG_TEXT);\n'
        '        if (text == null || text.isEmpty()) return;'
    )
    new = (
        '        String senderId = intent.getStringExtra(MeshActivity.EXTRA_SENDER_ID);\n'
        '        String wire     = intent.getStringExtra(MeshActivity.EXTRA_MSG_TEXT);\n'
        '        if (wire == null || wire.isEmpty()) return;\n'
        '\n'
        '        MeshServiceConnection conn = new MeshServiceConnection(context);\n'
        '        conn.connect();\n'
        '        String text = conn.handleIncoming(senderId, wire);\n'
        '        if (text == null) return; // handshake / undecryptable - no notification'
    )
    if old not in r:
        print("FAIL: MeshMessageReceiver block not matched"); sys.exit(1)
    r = r.replace(old, new, 1)
    open(MR, "w", encoding="utf-8").write(r)
    print("MeshMessageReceiver wired")
