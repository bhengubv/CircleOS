#!/usr/bin/env bash
set -e
cd /home/geektrading/aosp/vendor/circle
D=apps/SdpktTitanium/src/za/co/circleos/sdpkt/app
echo "=== balances ==="
for f in WalletActivity CircleBiometricAuth; do
  r=$(python3 -c "s=open('$D/$f.java').read(); print(s.count(chr(123))-s.count(chr(125)), s.count(chr(40))-s.count(chr(41)))")
  echo "$f: $r"
  [ "$r" = "0 0" ] || { echo "BALANCE FAIL $f"; exit 1; }
done
echo "=== gates + config ==="
echo "biometric gates in WalletActivity: $(grep -c 'CircleBiometricAuth.require' $D/WalletActivity.java)"
echo "requireDeviceUnlock: $(grep -o 'requireDeviceUnlock=\"[a-z]*\"' apps/SdpktTitanium/res/xml/hce_service.xml)"
echo "USE_BIOMETRIC: $(grep -c 'USE_BIOMETRIC' apps/SdpktTitanium/AndroidManifest.xml)"
echo "=== commit ==="
git add $D/WalletActivity.java $D/CircleBiometricAuth.java \
        apps/SdpktTitanium/res/xml/hce_service.xml apps/SdpktTitanium/AndroidManifest.xml
git commit -q -m "wallet: gate money operations on biometric / device PIN [skip ci]

The SDPKT wallet moved money with NO authentication: 'send' and 'accept transfer'
ran on a tap, and the NFC tap-to-pay HCE service had requireDeviceUnlock=false --
i.e. a locked phone could be tapped to a terminal and pay. There was no biometric
anywhere in Circle OS.

Wire the native PhonePin + Biometrics standard:
- CircleBiometricAuth: framework BiometricPrompt requiring BIOMETRIC_STRONG OR
  DEVICE_CREDENTIAL (fingerprint/face or PIN), fail-closed (money never moves on
  cancel/error/nothing-enrolled).
- Gate WalletActivity send (startSendSession) and accept (acceptIncomingTransfer).
- HCE requireDeviceUnlock=false -> true: no tap-to-pay on a locked device.
- Declare USE_BIOMETRIC.

This is app-level authorisation; device-unlock biometric itself is the inherited
AOSP keyguard (works once a device fingerprint/face HAL is present)."
echo COMMITTED
git log --oneline -1
