#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Add store-and-forward "store" to the mesh: hold frames when no peer is reachable
# and flush them when a peer is discovered (BLE scan / Wi-Fi P2P). Completes the
# carry-until-you-meet behaviour that makes the mesh work with zero infrastructure.
import sys
F = "frameworks/base/services/core/java/com/circleos/server/mesh/CircleMeshService.java"
s = open(F, encoding="utf-8").read()
if "mMeshOutbox" in s:
    print("store-and-forward already wired"); sys.exit(0)

edits = []

# A) outbox field (after the wifi outbox)
A_old = ("    private final java.util.concurrent.ConcurrentLinkedQueue<byte[]> mWifiOutbox =\n"
         "            new java.util.concurrent.ConcurrentLinkedQueue<>();")
A_new = A_old + ("\n    /** Store-and-forward: frames held when no peer is reachable; flushed on discovery. */\n"
                 "    private final java.util.concurrent.ConcurrentLinkedQueue<byte[]> mMeshOutbox =\n"
                 "            new java.util.concurrent.ConcurrentLinkedQueue<>();")
edits.append(("A outbox field", A_old, A_new))

# B) sendMessage: store when there are no peers at all
B_old = (
    "                if (direct != null) {\n"
    "                    if (direct.transport == Transport.BLE) sendViaBle(direct, frame);\n"
    "                    else sendViaWifiP2p(direct, frame);\n"
    "                } else {\n"
    "                    relayToAll(frame); // recipient not in direct range -> multi-hop flood\n"
    "                }")
B_new = (
    "                if (mPeers.isEmpty()) {\n"
    "                    storeForLater(frame); // no peer in range -> carry until we meet one\n"
    "                } else if (direct != null) {\n"
    "                    if (direct.transport == Transport.BLE) sendViaBle(direct, frame);\n"
    "                    else sendViaWifiP2p(direct, frame);\n"
    "                } else {\n"
    "                    relayToAll(frame); // recipient not in direct range -> multi-hop flood\n"
    "                }")
edits.append(("B sendMessage store", B_old, B_new))

# C) helpers after relayToAll
C_old = (
    "    private void relayToAll(byte[] frame) {\n"
    "        for (Peer peer : mPeers.values()) {\n"
    "            try {\n"
    "                if (peer.transport == Transport.BLE) sendViaBle(peer, frame);\n"
    "                else sendViaWifiP2p(peer, frame);\n"
    "            } catch (Throwable ignored) {}\n"
    "        }\n"
    "    }")
C_new = C_old + r'''

    /** Hold a frame we couldn't send (no peers) until one is discovered. */
    private void storeForLater(byte[] frame) {
        mMeshOutbox.offer(frame);
        while (mMeshOutbox.size() > 128) mMeshOutbox.poll(); // bound; drop oldest
        Slog.i(TAG, "mesh: stored frame for later (" + mMeshOutbox.size() + " queued)");
    }

    /** Flush stored frames once a peer appears -- the carry-until-you-meet step. */
    private void flushMeshOutbox() {
        if (mMeshOutbox.isEmpty() || mPeers.isEmpty()) return;
        byte[] frame;
        int n = 0;
        while ((frame = mMeshOutbox.poll()) != null) { relayToAll(frame); n++; }
        if (n > 0) Slog.i(TAG, "mesh: flushed " + n + " stored frame(s) on peer discovery");
    }'''
edits.append(("C helpers", C_old, C_new))

# D) flush on BLE discovery
D_old = (
    "            mPeers.put(key, new Peer(key,\n"
    "                    safeBtName(d),\n"
    "                    Transport.BLE,\n"
    "                    d.getAddress(),\n"
    "                    d,\n"
    "                    now));\n"
    "        }")
D_new = (
    "            mPeers.put(key, new Peer(key,\n"
    "                    safeBtName(d),\n"
    "                    Transport.BLE,\n"
    "                    d.getAddress(),\n"
    "                    d,\n"
    "                    now));\n"
    "            if (!mMeshOutbox.isEmpty()) flushMeshOutbox();\n"
    "        }")
edits.append(("D ble flush", D_old, D_new))

# E) flush on Wi-Fi P2P discovery
E_old = (
    "            mPeers.put(key, new Peer(key, d.deviceName, Transport.WIFI_P2P,\n"
    "                    d.deviceAddress, null, now));\n"
    "        }\n"
    "    }")
E_new = (
    "            mPeers.put(key, new Peer(key, d.deviceName, Transport.WIFI_P2P,\n"
    "                    d.deviceAddress, null, now));\n"
    "        }\n"
    "        if (!mMeshOutbox.isEmpty()) flushMeshOutbox();\n"
    "    }")
edits.append(("E wifi flush", E_old, E_new))

# F) refresh the now-stale sendViaBle comment
F_old = (
    "        // are logged and the message is dropped (no store-and-forward\n"
    "        // yet -- that lands with the v2 AIDL that exposes IMessageReceiver).")
F_new = (
    "        // are logged, but the router floods to other peers and frames with\n"
    "        // no reachable peer are held by the mesh outbox (store-and-forward).")
edits.append(("F comment", F_old, F_new))

for name, old, new in edits:
    if old not in s:
        print("FAIL:", name); sys.exit(1)
    s = s.replace(old, new, 1)

open(F, "w", encoding="utf-8").write(s)
print("store-and-forward wired (outbox + flush on BLE/Wi-Fi discovery)")
