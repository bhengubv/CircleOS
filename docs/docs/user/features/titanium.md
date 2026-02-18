# Titanium Wallet

Titanium is Circle OS's built-in payment system. Tap phone-to-phone to send and receive Shongololo (₷) — even without internet.

---

## Getting started

1. Open the **Titanium** app.
2. Tap **Create Wallet** and set a PIN.
3. Your wallet is created and secured in the device's hardware keystore (TEE).

---

## Sending money

1. Open Titanium and tap **Send**.
2. Enter the amount in ₷ (Shongololo).
3. Hold your phone near the recipient's Circle OS phone.
4. Both phones confirm the transaction — tap **Confirm** on both.

The transaction is signed by both devices and queued for settlement.

---

## Receiving money

1. Open Titanium and tap **Receive**.
2. The other person initiates the send.
3. Hold phones together when prompted.
4. Confirm on your phone.

---

## Settlement

Transactions settle when either party comes online (via internet or mesh). Settlement is handled via the SleptOn API and confirmed on the SDPKT network.

If offline for extended periods, unsettled transactions are stored securely and settled automatically when connectivity is restored.

---

## Security features

| Feature | Description |
|---------|-------------|
| **Hardware keystore** | Keys never leave the TEE — can't be extracted |
| **Stress detection** | Titanium locks if biometric stress is detected |
| **Location rules** | Optionally restrict transactions to specific locations |
| **Passive duress** | Silent emergency mode if under threat |
| **PIN + biometric** | Dual authentication for transactions over ₷500 |

---

## Topping up

Top up your Shongololo balance via:

- Bank transfer (SleptOn payment portal)
- From another Circle OS user
- SleptOn partner merchants

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| NFC not working | Ensure NFC is enabled: Settings → Connections → NFC |
| Transaction failed | Ensure both phones have Titanium open and ready |
| Balance not showing | Check internet/mesh connectivity for settlement |
