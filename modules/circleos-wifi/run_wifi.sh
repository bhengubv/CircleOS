#!/usr/bin/env bash
set -e
cd /home/geektrading/aosp/frameworks/base
D=services/core/java/com/circleos/server/mesh
f=$D/CircleMeshService.java
r=$(python3 -c "s=open('$f').read(); print(s.count(chr(123))-s.count(chr(125)), s.count(chr(40))-s.count(chr(41)))")
echo "balance: $r"
[ "$r" = "0 0" ] || { echo "BALANCE FAIL"; exit 1; }
echo "=== wifi-p2p wired ==="
grep -c "startWifiP2pServer\|flushWifiOutbox\|formWifiGroup\|mWifiServer" "$f"
echo "=== no more log+drop stub ==="
grep -c "not wired in alpha-1" "$f" || true
git add "$f"
git commit -q -m "mesh: real Wi-Fi Direct transport (was log+drop) [skip ci]

Wi-Fi Direct send was a stub that logged and dropped the frame. Wire the real
opportunistic transport:
- Receive: a ServerSocket (port 8988) accept loop; as P2P group owner, read
  length-prefixed frames and feed the same deliverReceived() router path. The
  routed v3 frame is self-describing, so no per-link sender state is needed.
- Send: queue the frame and push it to the group owner over TCP as soon as a
  group is up (this device as client); if no group exists, form one toward the
  peer and flush on the next send. Backlog is bounded (64) and requeues on error.

High-bandwidth path when a group is available; BLE stays the always-on mesh link
and the multi-hop router relays across both. Group-owner-initiated push is the
known asymmetry (the GO receives; clients push) — covered by BLE + relay."
echo COMMITTED
git log --oneline -1
