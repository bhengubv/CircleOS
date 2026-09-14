#!/usr/bin/env bash
set -e
cd /home/geektrading/aosp
D=frameworks/base/services/core/java/com/circleos/server/wallet
mkdir -p "$D"
base64 -d /tmp/wallet.b64 > "$D/ShongololoWalletService.java"
rm -f /tmp/wallet.b64
echo "=== placed ==="
wc -l "$D/ShongololoWalletService.java"
python3 -c "s=open('$D/ShongololoWalletService.java').read(); print('braces', s.count(chr(123))-s.count(chr(125)), 'parens', s.count(chr(40))-s.count(chr(41)))"
echo "=== AIDL library packaging (vendor/circle/aidl) ==="
find vendor/circle/aidl -name "Android.bp" -o -name "Android.mk" 2>/dev/null | head
echo "--- bp content ---"
cat vendor/circle/aidl/Android.bp 2>/dev/null | head -60 || echo "(no Android.bp at vendor/circle/aidl)"
echo "=== does services.core already know sdpkt? ==="
grep -rn "sdpkt\|shongololo" frameworks/base/services/core/Android.bp 2>/dev/null || echo "(services.core does NOT reference sdpkt)"
