#!/usr/bin/env bash
F=/home/geektrading/aosp/frameworks/base/services/core/java/com/circleos/server/wallet/ShongololoWalletService.java
echo "=== 88-122 constants+fields ==="; sed -n '88,122p' "$F"
echo "=== 274-286 dailyRemaining+offlineAccum ==="; sed -n '274,286p' "$F"
echo "=== 299,313 beginNfcSession limits ==="; sed -n '299,313p' "$F"
echo "=== 352,360 acceptRecv ==="; sed -n '352,360p' "$F"
echo "=== 515,540 finalizeSend+offerBytes ==="; sed -n '515,540p' "$F"
echo "=== 588,602 markSettled ==="; sed -n '588,602p' "$F"
echo "=== rolloverDay ==="; grep -n -A4 'private void rolloverDay' "$F"
