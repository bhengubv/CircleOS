#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Integrate MeshRouter into CircleMeshService: routed v3 frames on send (direct or
# multi-hop flood), and decode->deliver/relay/drop on receive. Link encryption +
# size-bucket padding still wrap the frame.
import sys
F = "frameworks/base/services/core/java/com/circleos/server/mesh/CircleMeshService.java"
s = open(F, encoding="utf-8").read()
if "mRouter" in s:
    print("router already integrated"); sys.exit(0)

# 1) router field after FRAME_BUCKETS
fb = "    private static final int[] FRAME_BUCKETS = {256, 512, 1024, 2048, 4096, 8192, 16384};"
if fb not in s:
    print("FAIL: FRAME_BUCKETS anchor"); sys.exit(1)
s = s.replace(fb, fb + "\n\n    /** Multi-hop store-and-forward routing (v3 frames). */\n"
              "    private final MeshRouter mRouter = new MeshRouter(512);", 1)

# 2) helper methods before currentServiceUuid()
hanchor = "    /** Current rotating BLE service UUID (daily;"
if hanchor not in s:
    print("FAIL: currentServiceUuid anchor"); sys.exit(1)
helpers = r'''    private byte[] myIdBytes() { return MeshRouter.idToBytes(mDeviceId); }

    private static byte[] padToBucket(byte[] frame) {
        int bucket = frame.length;
        for (int b : FRAME_BUCKETS) { if (b >= frame.length) { bucket = b; break; } }
        return bucket == frame.length ? frame : java.util.Arrays.copyOf(frame, bucket);
    }

    /** Forward a frame to every known peer; the router's dedup prevents loops. */
    private void relayToAll(byte[] frame) {
        for (Peer peer : mPeers.values()) {
            try {
                if (peer.transport == Transport.BLE) sendViaBle(peer, frame);
                else sendViaWifiP2p(peer, frame);
            } catch (Throwable ignored) {}
        }
    }

    private void broadcastReceived(String sender, byte[] payload) {
        final String text = new String(payload, java.nio.charset.StandardCharsets.UTF_8);
        android.content.Intent i =
                new android.content.Intent("za.co.circleos.mesh.action.MESSAGE_RECEIVED");
        i.putExtra("sender_id", sender);
        i.putExtra("msg_text", text);
        i.setFlags(android.content.Intent.FLAG_INCLUDE_STOPPED_PACKAGES);
        try { mContext.sendBroadcastAsUser(i, android.os.UserHandle.ALL); }
        catch (Throwable t) { mContext.sendBroadcast(i); }
        Slog.i(TAG, "delivered mesh message from " + sender + " (" + payload.length + "b)");
    }

'''
s = s.replace(hanchor, helpers + hanchor, 1)

# 3) sendMessage: build a routed frame; send direct or flood toward dst
old_send = (
    "            final Peer p = mPeers.get(recipientDeviceId);\n"
    "            if (p == null) {\n"
    "                Slog.i(TAG, \"sendMessage: unknown peer \" + recipientDeviceId);\n"
    "                return false;\n"
    "            }\n"
    "            // We dispatch to the worker so the caller's binder thread\n"
    "            // never blocks on a transport that may need real I/O.\n"
    "            mHandler.post(() -> dispatchMessage(p, payload, msgType));\n"
    "            return true;")
if old_send not in s:
    print("FAIL: sendMessage block not matched"); sys.exit(1)
new_send = (
    "            final Peer direct = mPeers.get(recipientDeviceId);\n"
    "            final byte[] pl = payload;\n"
    "            final String dstId = recipientDeviceId;\n"
    "            // Worker thread so the binder caller never blocks on transport I/O.\n"
    "            mHandler.post(() -> {\n"
    "                final byte[] frame = padToBucket(mRouter.encode(\n"
    "                        MeshRouter.idToBytes(dstId), myIdBytes(), MeshRouter.DEFAULT_TTL, pl));\n"
    "                if (direct != null) {\n"
    "                    if (direct.transport == Transport.BLE) sendViaBle(direct, frame);\n"
    "                    else sendViaWifiP2p(direct, frame);\n"
    "                } else {\n"
    "                    relayToAll(frame); // recipient not in direct range -> multi-hop flood\n"
    "                }\n"
    "            });\n"
    "            return true;")
s = s.replace(old_send, new_send, 1)

# 4) deliverReceived: decode -> route -> deliver / relay / drop
old_dr_start = "    private void deliverReceived(android.bluetooth.BluetoothDevice device, byte[] wire) {"
if old_dr_start not in s:
    print("FAIL: deliverReceived not found"); sys.exit(1)
# replace the body between the old start and its closing by matching the full old method
old_dr = (
    "    private void deliverReceived(android.bluetooth.BluetoothDevice device, byte[] wire) {\n"
    "        if (wire == null) return;\n"
    "        byte[] frame = MeshLinkPrivacy.linkDecrypt(\n"
    "                MeshLinkPrivacy.currentEpoch(System.currentTimeMillis()), wire);\n"
    "        if (frame == null) { Slog.i(TAG, \"drop: not a Circle link frame\"); return; }\n"
    "        byte[] payload = unframe(frame);\n"
    "        if (payload == null) return;\n"
    "        final String sender = shortIdFromMac(device == null ? \"\" : device.getAddress());\n"
    "        final String text = new String(payload, java.nio.charset.StandardCharsets.UTF_8);\n"
    "        android.content.Intent i =\n"
    "                new android.content.Intent(\"za.co.circleos.mesh.action.MESSAGE_RECEIVED\");\n"
    "        i.putExtra(\"sender_id\", sender);\n"
    "        i.putExtra(\"msg_text\", text);\n"
    "        i.setFlags(android.content.Intent.FLAG_INCLUDE_STOPPED_PACKAGES);\n"
    "        try {\n"
    "            mContext.sendBroadcastAsUser(i, android.os.UserHandle.ALL);\n"
    "        } catch (Throwable t) {\n"
    "            mContext.sendBroadcast(i);\n"
    "        }\n"
    "        Slog.i(TAG, \"delivered mesh message from \" + sender + \" (\" + payload.length + \"b)\");\n"
    "    }")
if old_dr not in s:
    print("FAIL: deliverReceived body not matched"); sys.exit(1)
new_dr = (
    "    private void deliverReceived(android.bluetooth.BluetoothDevice device, byte[] wire) {\n"
    "        if (wire == null) return;\n"
    "        byte[] frame = MeshLinkPrivacy.linkDecrypt(\n"
    "                MeshLinkPrivacy.currentEpoch(System.currentTimeMillis()), wire);\n"
    "        if (frame == null) { Slog.i(TAG, \"drop: not a Circle link frame\"); return; }\n"
    "        MeshRouter.Parsed p = mRouter.decode(frame);\n"
    "        if (p == null) return;\n"
    "        switch (mRouter.route(p, myIdBytes())) {\n"
    "            case DELIVER:\n"
    "                broadcastReceived(MeshRouter.bytesToId(p.src), p.payload);\n"
    "                break;\n"
    "            case RELAY:\n"
    "                relayToAll(padToBucket(mRouter.reframeForRelay(p)));\n"
    "                break;\n"
    "            default:\n"
    "                break; // DROP (duplicate / TTL-exhausted)\n"
    "        }\n"
    "    }")
s = s.replace(old_dr, new_dr, 1)

open(F, "w", encoding="utf-8").write(s)
print("MeshRouter integrated (routed send + relay receive)")
