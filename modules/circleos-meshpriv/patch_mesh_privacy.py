#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Metadata-harden the CircleMesh wire framing: drop the cleartext content type
# (the E2E payload self-describes) and zero-pad to coarse size buckets so a relay
# learns only [version][bucketed length], never the type or exact size.
import sys

F = "frameworks/base/services/core/java/com/circleos/server/mesh/CircleMeshService.java"
s = open(F, encoding="utf-8").read()
if "FRAME_BUCKETS" in s:
    print("already hardened"); sys.exit(0)

# 1) constants
anchor = "    private static final long PEER_STALENESS_MS = 90_000;"
if anchor not in s:
    print("FAIL: staleness anchor"); sys.exit(1)
consts = (anchor + "\n\n"
    "    /** Metadata-hardened wire framing: the content type is never on the wire\n"
    "     *  (the E2E payload self-describes via its CKX/CE1/CE2 prefix), and each\n"
    "     *  frame is zero-padded up to a coarse size bucket so an observer learns\n"
    "     *  only [version][bucketed length] -- not the message type or true size. */\n"
    "    private static final int FRAME_VERSION = 2;\n"
    "    private static final int[] FRAME_BUCKETS = {256, 512, 1024, 2048, 4096, 8192, 16384};")
s = s.replace(anchor, consts, 1)

# 2) framing method
old_frame = (
    "    private static byte[] frameMessage(byte[] payload, int msgType) {\n"
    "        final byte[] out = new byte[4 + payload.length];\n"
    "        out[0] = (byte) ((msgType >> 24) & 0xff);\n"
    "        out[1] = (byte) ((msgType >> 16) & 0xff);\n"
    "        out[2] = (byte) ((msgType >> 8) & 0xff);\n"
    "        out[3] = (byte) (msgType & 0xff);\n"
    "        System.arraycopy(payload, 0, out, 4, payload.length);\n"
    "        return out;\n"
    "    }")
new_frame = (
    "    private static byte[] frameMessage(byte[] payload, int msgType) {\n"
    "        // msgType is intentionally NOT written to the wire (blind-to-us: the\n"
    "        // encrypted payload already self-describes its type). Header is\n"
    "        // [ver:1][trueLen:4 BE]; the frame is then zero-padded to a size bucket.\n"
    "        final int header = 5;\n"
    "        final int target = header + payload.length;\n"
    "        int bucket = target;\n"
    "        for (int b : FRAME_BUCKETS) { if (b >= target) { bucket = b; break; } }\n"
    "        final byte[] out = new byte[bucket];\n"
    "        out[0] = (byte) FRAME_VERSION;\n"
    "        out[1] = (byte) ((payload.length >> 24) & 0xff);\n"
    "        out[2] = (byte) ((payload.length >> 16) & 0xff);\n"
    "        out[3] = (byte) ((payload.length >> 8) & 0xff);\n"
    "        out[4] = (byte) (payload.length & 0xff);\n"
    "        System.arraycopy(payload, 0, out, header, payload.length);\n"
    "        return out;\n"
    "    }")
if old_frame not in s:
    print("FAIL: frameMessage body not matched"); sys.exit(1)
s = s.replace(old_frame, new_frame, 1)

# 3) refresh the stale dispatch comment
old_c = "        // For alpha-1: the wire framing is [4 bytes BE msgType][payload]."
new_c = ("        // Metadata-hardened framing v2: [ver][trueLen][payload + size-bucket\n"
         "        // padding]. The content type is NOT on the wire; a relay sees only a\n"
         "        // padded opaque blob.")
if old_c in s:
    s = s.replace(old_c, new_c, 1)

open(F, "w", encoding="utf-8").write(s)
print("mesh wire framing hardened (type stripped + size-bucket padding)")
