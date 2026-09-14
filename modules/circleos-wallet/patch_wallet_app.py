#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Wire the incoming-transfer broadcast (sent by ShongololoWalletService) into
# WalletActivity so showIncomingTransferDialog actually fires after an NFC tap.
import sys
F = "vendor/circle/apps/SdpktTitanium/src/za/co/circleos/sdpkt/app/WalletActivity.java"
s = open(F, encoding="utf-8").read()
if "mIncomingReceiver" in s:
    print("already wired"); sys.exit(0)

# 1) receiver field
fld_anchor = "    private Button    mBtnPay;"
if fld_anchor not in s:
    print("FAIL: field anchor"); sys.exit(1)
fld = fld_anchor + '''
    private boolean   mIncomingRegistered;
    private final android.content.BroadcastReceiver mIncomingReceiver =
            new android.content.BroadcastReceiver() {
        @Override public void onReceive(Context ctx, android.content.Intent intent) {
            if (intent == null) return;
            String sid = intent.getStringExtra("session_id");
            if (sid == null) return;
            ShongololoTransaction tx = new ShongololoTransaction();
            tx.amountCents = intent.getLongExtra("amount_cents", 0);
            tx.senderDeviceId = intent.getStringExtra("sender_id");
            tx.type = ShongololoTransaction.TYPE_RECV;
            showIncomingTransferDialog(sid, tx);
        }
    };'''
s = s.replace(fld_anchor, fld, 1)

# 2) register on resume
res_anchor = (
    "        refreshWallet();\n"
    "        // Phase 4: Quick Pay tile launched us — start NFC reader immediately\n"
    "        handleQuickPayIntent(getIntent());\n"
    "    }")
if res_anchor not in s:
    print("FAIL: onResume anchor"); sys.exit(1)
res_new = (
    "        refreshWallet();\n"
    "        // Phase 4: Quick Pay tile launched us — start NFC reader immediately\n"
    "        handleQuickPayIntent(getIntent());\n"
    "        if (!mIncomingRegistered) {\n"
    "            registerReceiver(mIncomingReceiver, new android.content.IntentFilter(\n"
    "                    \"za.co.circleos.sdpkt.action.INCOMING_TRANSFER\"),\n"
    "                    Context.RECEIVER_NOT_EXPORTED);\n"
    "            mIncomingRegistered = true;\n"
    "        }\n"
    "    }")
s = s.replace(res_anchor, res_new, 1)

# 3) unregister on pause
pau_anchor = (
    "    protected void onPause() {\n"
    "        super.onPause();\n"
    "        disableNfcReader();\n"
    "    }")
if pau_anchor not in s:
    print("FAIL: onPause anchor"); sys.exit(1)
pau_new = (
    "    protected void onPause() {\n"
    "        super.onPause();\n"
    "        disableNfcReader();\n"
    "        if (mIncomingRegistered) {\n"
    "            try { unregisterReceiver(mIncomingReceiver); } catch (Throwable ignored) {}\n"
    "            mIncomingRegistered = false;\n"
    "        }\n"
    "    }")
s = s.replace(pau_anchor, pau_new, 1)

open(F, "w", encoding="utf-8").write(s)
print("WalletActivity: incoming-transfer receiver wired")
