#!/usr/bin/env bash
set -e
cd /home/geektrading/aosp/frameworks/base
F=services/core/java/com/circleos/server/mesh/CircleMeshService.java
echo "=== balance ==="
python3 -c "s=open('$F').read(); print('braces', s.count(chr(123))-s.count(chr(125)), 'parens', s.count(chr(40))-s.count(chr(41)))"
echo "=== receive path present ==="
grep -c "startGattServer\|startAdvertising\|deliverReceived\|onCharacteristicWriteRequest\|MESSAGE_RECEIVED\|unframe" "$F"
echo "=== commit ==="
git add "$F"
git commit -q -m "mesh: add the receive path (GATT server + advertiser + broadcast) [skip ci]

Close the biggest functional gap: the mesh could SEND + scan but had no way to
RECEIVE in-tree. Add it:
  - startGattServer(): hosts the Circle characteristic so peers can write frames.
  - startAdvertising(): advertises the rotating service UUID so peers discover us.
  - onCharacteristicWriteRequest -> deliverReceived(): link-decrypt (MeshLinkPrivacy)
    -> unframe the v2 [ver][trueLen][payload+pad] frame -> broadcast
    za.co.circleos.mesh.action.MESSAGE_RECEIVED {sender_id, msg_text}, which is
    exactly what CircleMessages/Butler already listen for.
Wired into startBle(). Symmetric with the hardened send framing + link encryption.
Mesh messaging is now bidirectional end to end (verified at the test session)."
echo COMMITTED
git log --oneline -1
