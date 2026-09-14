#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Replace the alpha-1 log+drop Wi-Fi Direct send with a real opportunistic
# transport: a ServerSocket receive loop (this device as group owner) + a
# client-push send over a TCP socket when a P2P group is up, forming a group
# toward the peer when none exists. Frames are the router's self-describing v3
# envelopes, so the receive side feeds the same deliverReceived() path.
import sys
F = "frameworks/base/services/core/java/com/circleos/server/mesh/CircleMeshService.java"
s = open(F, encoding="utf-8").read()
if "mWifiServer" in s:
    print("wifi-p2p already wired"); sys.exit(0)

# 1) fields after mWifiChannel
anchor_f = ("    private WifiP2pManager     mWifiP2p;\n"
            "    private WifiP2pManager.Channel mWifiChannel;")
if anchor_f not in s:
    print("FAIL: wifi field anchor"); sys.exit(1)
s = s.replace(anchor_f, anchor_f + "\n"
    "    private static final int WIFI_PORT = 8988;\n"
    "    private volatile java.net.ServerSocket mWifiServer;\n"
    "    private final java.util.concurrent.ConcurrentLinkedQueue<byte[]> mWifiOutbox =\n"
    "            new java.util.concurrent.ConcurrentLinkedQueue<>();", 1)

# 2) start the receive server when the transport comes up
anchor_s = ("            mWifiChannel = mWifiP2p.initialize(mContext, Looper.getMainLooper(), null);\n"
            "            triggerWifiP2pDiscovery();")
if anchor_s not in s:
    print("FAIL: startWifiP2p anchor"); sys.exit(1)
s = s.replace(anchor_s, anchor_s + "\n            startWifiP2pServer();", 1)

# 3) replace the log+drop sendViaWifiP2p with the real transport + helpers
old = (
    "    private void sendViaWifiP2p(Peer p, byte[] frame) {\n"
    "        // WiFi P2P direct send requires forming a group with the peer\n"
    "        // (WifiP2pManager.connect) then opening a TCP socket to the\n"
    "        // group owner. The connect flow is async and intrusive (it\n"
    "        // disconnects existing groups). For alpha-1 we log + drop;\n"
    "        // CircleMessages will fall back to BLE when both transports\n"
    "        // know the peer. WifiP2p sends land with the file-transfer\n"
    "        // surface in alpha-2.\n"
    "        Slog.i(TAG, \"wifi-p2p send to \" + p.shortId\n"
    "                + \" queued (\" + frame.length + \" bytes) -- direct group\"\n"
    "                + \" formation not wired in alpha-1\");\n"
    "    }")
if old not in s:
    print("FAIL: sendViaWifiP2p body not matched"); sys.exit(1)

new = r'''    /**
     * Opportunistic Wi-Fi Direct send. The frame is a self-describing routed v3
     * envelope, so we queue it and push it to the group owner over TCP as soon as
     * a P2P group is up (this device as client). If no group exists we kick off
     * formation toward the peer; queued frames flush on the next attempt. High
     * bandwidth when available; BLE remains the always-on path.
     */
    private void sendViaWifiP2p(Peer p, byte[] frame) {
        if (mWifiP2p == null || mWifiChannel == null || frame == null) return;
        mWifiOutbox.offer(frame);
        while (mWifiOutbox.size() > 64) mWifiOutbox.poll(); // bound the backlog
        final String addr = (p == null) ? null : p.address;
        try {
            mWifiP2p.requestConnectionInfo(mWifiChannel, info -> {
                if (info != null && info.groupFormed) {
                    flushWifiOutbox(info);
                } else if (addr != null) {
                    formWifiGroup(addr); // no group yet -> form one; flush on next send
                }
            });
        } catch (Throwable t) {
            Slog.w(TAG, "wifi-p2p send threw", t);
        }
    }

    /** Drain the outbox to the group owner over TCP (only the client can push). */
    private void flushWifiOutbox(android.net.wifi.p2p.WifiP2pInfo info) {
        if (info == null || !info.groupFormed || info.isGroupOwner
                || info.groupOwnerAddress == null) {
            return; // group owner receives via the ServerSocket; it cannot initiate
        }
        byte[] frame;
        while ((frame = mWifiOutbox.poll()) != null) {
            java.net.Socket sock = new java.net.Socket();
            try {
                sock.connect(new java.net.InetSocketAddress(
                        info.groupOwnerAddress, WIFI_PORT), 5000);
                java.io.DataOutputStream out =
                        new java.io.DataOutputStream(sock.getOutputStream());
                out.writeInt(frame.length);
                out.write(frame);
                out.flush();
            } catch (Throwable t) {
                Slog.w(TAG, "wifi-p2p socket send failed", t);
                mWifiOutbox.offer(frame); // requeue; retry on the next attempt
                break;
            } finally {
                try { sock.close(); } catch (Throwable ignored) {}
            }
        }
    }

    /** Form a P2P group toward a peer so subsequent sends have a path. */
    private void formWifiGroup(String deviceAddress) {
        try {
            android.net.wifi.p2p.WifiP2pConfig cfg = new android.net.wifi.p2p.WifiP2pConfig();
            cfg.deviceAddress = deviceAddress;
            mWifiP2p.connect(mWifiChannel, cfg, new WifiP2pManager.ActionListener() {
                @Override public void onSuccess() { /* flushes on next send */ }
                @Override public void onFailure(int reason) {
                    Slog.i(TAG, "wifi-p2p connect failed: " + reason);
                }
            });
        } catch (Throwable t) {
            Slog.w(TAG, "wifi-p2p connect threw", t);
        }
    }

    /** Receive loop: as group owner, accept TCP frames and feed the router path. */
    private void startWifiP2pServer() {
        if (mWifiServer != null) return;
        Thread t = new Thread(() -> {
            try {
                mWifiServer = new java.net.ServerSocket(WIFI_PORT);
                while (mWifiServer != null && !mWifiServer.isClosed()) {
                    java.net.Socket sock = mWifiServer.accept();
                    try {
                        java.io.DataInputStream in =
                                new java.io.DataInputStream(sock.getInputStream());
                        int len = in.readInt();
                        if (len > 0 && len <= (1 << 20)) {
                            byte[] frame = new byte[len];
                            in.readFully(frame);
                            deliverReceived(null, frame); // routed frame is self-describing
                        }
                    } catch (Throwable ignored) {
                    } finally {
                        try { sock.close(); } catch (Throwable ignored2) {}
                    }
                }
            } catch (Throwable t2) {
                Slog.w(TAG, "wifi-p2p server stopped", t2);
            }
        }, "CircleMeshWifiServer");
        t.setDaemon(true);
        t.start();
    }'''
s = s.replace(old, new, 1)
open(F, "w", encoding="utf-8").write(s)
print("Wi-Fi Direct transport wired (ServerSocket receive + client-push send)")
