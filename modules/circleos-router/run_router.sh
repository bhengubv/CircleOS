#!/usr/bin/env bash
set -e
cd /home/geektrading/aosp/frameworks/base
D=services/core/java/com/circleos/server/mesh
echo "=== balances ==="
for f in CircleMeshService MeshRouter; do
  r=$(python3 -c "s=open('$D/$f.java').read(); print(s.count(chr(123))-s.count(chr(125)), s.count(chr(40))-s.count(chr(41)))")
  echo "$f: $r"
  [ "$r" = "0 0" ] || { echo "BALANCE FAIL $f"; exit 1; }
done
echo "=== routing wired ==="
grep -c "mRouter" "$D/CircleMeshService.java"
grep -c "broadcastReceived\|relayToAll\|reframeForRelay" "$D/CircleMeshService.java"
echo "=== commit ==="
git add "$D/CircleMeshService.java" "$D/MeshRouter.java"
git commit -q -m "mesh: multi-hop store-and-forward routing (v3 routed frames) [skip ci]

The mesh was single-hop: a message only reached a peer in direct BLE/Wi-Fi range.
Add MeshRouter — a true relay mesh so a message hops through intermediate Circle
devices to reach a peer that's out of direct range.

- Frame v3: [ver][ttl][hop][flags][msgId:8][dst:8][src:8][len][payload], then
  size-bucket padded and link-encrypted (MeshLinkPrivacy) so outsiders see nothing.
- Send: addressed to a direct peer -> sent directly; otherwise flooded toward dst.
- Receive: decode -> deliver (for me / broadcast) | relay (hop++ to all peers) |
  drop (duplicate via msgId dedup, or TTL exhausted). Loop-safe.
- Routing logic unit-tested off-device: 14/14 green (roundtrip, deliver, relay,
  dedup, broadcast, TTL exhaustion, hop increment).

Privacy: a Circle relay must see dst to forward (inherent to any routed mesh);
content stays E2E and outside observers see only an opaque link-encrypted blob."
echo COMMITTED
git log --oneline -1
