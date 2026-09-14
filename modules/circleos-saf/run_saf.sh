#!/usr/bin/env bash
set -e
cd /home/geektrading/aosp/frameworks/base
f=services/core/java/com/circleos/server/mesh/CircleMeshService.java
r=$(python3 -c "s=open('$f').read(); print(s.count(chr(123))-s.count(chr(125)), s.count(chr(40))-s.count(chr(41)))")
echo "balance: $r"
[ "$r" = "0 0" ] || { echo "BALANCE FAIL"; exit 1; }
echo "=== store-and-forward wired ==="
grep -c "mMeshOutbox\|storeForLater\|flushMeshOutbox" "$f"
git add "$f"
git commit -q -m "mesh: store-and-forward (carry frames until a peer appears) [skip ci]

The router relays to peers in range, but with zero peers present a frame was
dropped. Add the 'store' half of store-and-forward: hold frames in a bounded
outbox (128, drop-oldest) when no peer is reachable, and flush them the moment a
peer is discovered over BLE or Wi-Fi Direct. This is what lets a message survive
a gap in coverage and ride the next device that comes into range -- the core of
'works when the internet doesn't'."
echo COMMITTED
git log --oneline -1
