#!/usr/bin/env bash
set -e
cd /home/geektrading/aosp
D=frameworks/base/services/core/java/com/circleos/server/wallet
base64 -d /tmp/wm.b64 > "$D/WalletMath.java"
base64 -d /tmp/wf.b64 > "$D/WalletFrame.java"
base64 -d /tmp/pw.b64 > /tmp/pw.py
python3 /tmp/pw.py
rm -f /tmp/pw.py /tmp/wm.b64 /tmp/wf.b64 /tmp/pw.b64
F="$D/ShongololoWalletService.java"
echo "=== balances (braces parens) ==="
for f in ShongololoWalletService WalletMath WalletFrame; do
  python3 -c "s=open('$D/$f.java').read(); print('$f', s.count(chr(123))-s.count(chr(125)), s.count(chr(40))-s.count(chr(41)))"
done
echo "=== orphan field refs (expect 0) ==="
grep -c "mAvailableCents\|mPendingInCents\|mPendingOutCents\|mDailySpentCents\|mDailyEpochDay" "$F" || echo "0 (none)"
echo "=== wiring present ==="
echo "mMath refs:           $(grep -c 'mMath' "$F")"
echo "WalletFrame.offerBytes: $(grep -c 'WalletFrame.offerBytes' "$F")"
echo "checkSend wired:        $(grep -c 'mMath.checkSend' "$F")"
echo "finalizeSend wired:     $(grep -c 'mMath.finalizeSend' "$F")"
echo "settle wired:           $(grep -c 'mMath.settleSend\|mMath.settleRecv' "$F")"
