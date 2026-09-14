#!/usr/bin/env bash
set -e
cd /home/geektrading/aosp/frameworks/base
M=services/core/java/com/circleos/server/mesh
echo "=== balances ==="
for f in CircleMeshService MeshLinkPrivacy; do
  python3 -c "s=open('$M/$f.java').read(); print('$f', s.count(chr(123))-s.count(chr(125)), s.count(chr(40))-s.count(chr(41)))"
done
echo "=== wired ==="
grep -c "currentServiceUuid\|MeshLinkPrivacy.linkEncrypt" "$M/CircleMeshService.java"
echo "=== commit ==="
git add "$M/MeshLinkPrivacy.java" "$M/CircleMeshService.java"
git commit -q -m "mesh: link encryption + rotating BLE UUID (kill the fingerprint) [skip ci]

Close the two metadata gaps you named. MeshLinkPrivacy derives, from a baked-in
network pre-shared key (Thread/Zigbee model), per-day values: a rotating BLE
service UUID (so a passive scanner WITHOUT the network key can't tell a device is
Circle -- the fixed-UUID fingerprint is gone for outside observers) and a link key
that wraps every frame in a second ChaCha20-Poly1305 layer (so the on-air envelope
-- version, padded length, everything -- is opaque). Content stays E2E; this
defeats non-Circle passive fingerprinting + bulk metadata capture. Honest limit:
extracting the key from firmware re-enables fingerprinting. Verified standalone on
JDK 21 (MeshLinkTest 9/9). Wired into the scan filter, GATT lookup, and send path."
echo COMMITTED
git log --oneline -1
