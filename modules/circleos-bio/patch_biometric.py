#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Wire CircleBiometricAuth into the wallet's money operations:
#  - send transfer  -> biometric/PIN before startSendSession
#  - accept transfer -> biometric/PIN before acceptIncomingTransfer
#  - HCE tap-to-pay  -> requireDeviceUnlock true (no paying on a locked phone)
#  - declare USE_BIOMETRIC
import sys

ROOT = "vendor/circle/apps/SdpktTitanium"
WA = f"{ROOT}/src/za/co/circleos/sdpkt/app/WalletActivity.java"
XML = f"{ROOT}/res/xml/hce_service.xml"
MAN = f"{ROOT}/AndroidManifest.xml"

# 1) WalletActivity -------------------------------------------------------
s = open(WA, encoding="utf-8").read()
if "CircleBiometricAuth" in s:
    print("wallet already biometric-gated"); sys.exit(0)

# 1a) gate the outgoing send
send_old = "                    startSendSession(amtCents, memo, lockScreen);"
if send_old not in s:
    print("FAIL: send anchor"); sys.exit(1)
send_new = (
    "                    CircleBiometricAuth.require(this,\n"
    "                            getString(R.string.wallet_tap_to_pay),\n"
    "                            \"Authorise payment of \" + formatCents(amtCents),\n"
    "                            () -> startSendSession(amtCents, memo, lockScreen));")
s = s.replace(send_old, send_new, 1)

# 1b) gate the incoming accept (wrap the existing worker thread)
acc_old = (
    "            .setPositiveButton(getString(R.string.nfc_accept), (d, w) -> {\n"
    "                new Thread(() -> {\n"
    "                    try {\n"
    "                        TransactionResult res = mWallet.acceptIncomingTransfer(sessionId);")
if acc_old not in s:
    print("FAIL: accept anchor"); sys.exit(1)
acc_new = (
    "            .setPositiveButton(getString(R.string.nfc_accept), (d, w) ->\n"
    "                CircleBiometricAuth.require(this, getString(R.string.nfc_receiving),\n"
    "                        \"Authorise accepting \" + formatCents(tx.amountCents), () -> {\n"
    "                new Thread(() -> {\n"
    "                    try {\n"
    "                        TransactionResult res = mWallet.acceptIncomingTransfer(sessionId);")
s = s.replace(acc_old, acc_new, 1)

# close the extra require(...) lambda: the accept block's worker ends with
# "                }).start();\n            })" -> add one ")" to close require()
acc_close_old = (
    "                }).start();\n"
    "            })\n"
    "            .setNegativeButton(getString(R.string.nfc_decline), (d, w) -> {")
if acc_close_old not in s:
    print("FAIL: accept close anchor"); sys.exit(1)
acc_close_new = (
    "                }).start();\n"
    "            }))\n"
    "            .setNegativeButton(getString(R.string.nfc_decline), (d, w) -> {")
s = s.replace(acc_close_old, acc_close_new, 1)
open(WA, "w", encoding="utf-8").write(s)
print("WalletActivity: send + accept biometric-gated")

# 2) HCE: no tap-to-pay on a locked device --------------------------------
x = open(XML, encoding="utf-8").read()
if 'android:requireDeviceUnlock="false"' not in x:
    print("WARN: requireDeviceUnlock already not false")
else:
    x = x.replace('android:requireDeviceUnlock="false"',
                  'android:requireDeviceUnlock="true"', 1)
    open(XML, "w", encoding="utf-8").write(x)
    print("hce_service.xml: requireDeviceUnlock -> true")

# 3) declare USE_BIOMETRIC -------------------------------------------------
m = open(MAN, encoding="utf-8").read()
if "USE_BIOMETRIC" in m:
    print("USE_BIOMETRIC already declared")
else:
    nfc = '    <uses-permission android:name="android.permission.NFC" />'
    if nfc not in m:
        print("FAIL: manifest NFC anchor"); sys.exit(1)
    m = m.replace(nfc, nfc + '\n    <uses-permission android:name="android.permission.USE_BIOMETRIC" />', 1)
    open(MAN, "w", encoding="utf-8").write(m)
    print("AndroidManifest: USE_BIOMETRIC declared")

print("== biometric wiring complete ==")
