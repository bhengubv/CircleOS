#!/usr/bin/env bash
set -e
cd /home/geektrading/aosp/vendor/circle
F=apps/SdpktTitanium/src/za/co/circleos/sdpkt/app/WalletActivity.java
r=$(python3 -c "s=open('$F').read(); print(s.count(chr(123))-s.count(chr(125)), s.count(chr(40))-s.count(chr(41)))")
echo "WalletActivity balance: $r"
[ "$r" = "0 0" ] || { echo "BALANCE FAIL"; exit 1; }
echo "receiver refs: $(grep -c mIncomingReceiver $F)"
git add "$F"
git commit -q -m "wallet: fire the incoming-transfer dialog on the service broadcast [skip ci]

showIncomingTransferDialog existed but nothing ever called it -- the receive side
of an NFC payment had no UI trigger. Register a broadcast receiver (resume/pause)
for za.co.circleos.sdpkt.action.INCOMING_TRANSFER (sent by ShongololoWalletService
when a signed OFFER arrives) and raise the accept/decline dialog, which is itself
biometric-gated. Closes the receive-side wiring gap alongside the new backend."
echo COMMITTED
git log --oneline -1
