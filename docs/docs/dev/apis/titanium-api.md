# Titanium Wallet API (Android)

The Titanium Wallet API is an Android system API communicating with `CircleWalletService` via AIDL.

---

## Permissions

```xml
<uses-permission android:name="android.permission.CIRCLE_WALLET_READ" />
<uses-permission android:name="android.permission.CIRCLE_WALLET_PAY" />
```

`CIRCLE_WALLET_PAY` requires the user to explicitly grant payment permission to your app (like `BIND_ACCESSIBILITY_SERVICE` — it's a dangerous permission).

---

## TitaniumWallet

```java
import android.circleos.wallet.TitaniumWallet;
import android.circleos.wallet.SdpktToken;
import android.circleos.wallet.WalletBalance;

TitaniumWallet wallet = TitaniumWallet.getInstance(context);
```

### Get balance

```java
WalletBalance balance = wallet.getBalance();
long confirmedMicroSdpkt = balance.getConfirmed();     // settled balance
long pendingMicroSdpkt = balance.getPending();          // awaiting settlement
long totalMicroSdpkt = balance.getTotal();

// Convert to ₷: divide by 1_000_000
double sdpktAmount = totalMicroSdpkt / 1_000_000.0;
```

### Create a payment token

```java
wallet.createPayment(
    /* amount_micro_sdpkt */ 50_000_000L,  // ₷50.00
    /* memo */ "Coffee at Circle Cafe",
    new TitaniumWallet.PaymentCallback() {
        @Override
        public void onTokenReady(SdpktToken token) {
            // Token is ready — write to NFC or display as QR
            byte[] rawToken = token.toBytes();
            NdefMessage ndefMsg = token.toNdefMessage();
        }

        @Override
        public void onError(int errorCode, String message) {
            // Handle error
        }
    }
);
```

### Receive a payment (NFC)

Override `onNewIntent` in your activity:

```java
@Override
protected void onNewIntent(Intent intent) {
    super.onNewIntent(intent);
    if (NfcAdapter.ACTION_NDEF_DISCOVERED.equals(intent.getAction())) {
        Parcelable[] rawMessages = intent.getParcelableArrayExtra(NfcAdapter.EXTRA_NDEF_MESSAGES);
        NdefMessage ndefMessage = (NdefMessage) rawMessages[0];

        wallet.receivePayment(ndefMessage, new TitaniumWallet.ReceiveCallback() {
            @Override
            public void onPaymentReceived(SdpktToken token, long amountMicroSdpkt) {
                // Payment received — show success UI
                showPaymentSuccess(amountMicroSdpkt / 1_000_000.0);
            }

            @Override
            public void onPaymentRejected(int reason) {
                // Expired, duplicate, invalid signature, etc.
            }
        });
    }
}
```

---

## SdpktToken

| Method | Description |
|--------|-------------|
| `getPayerPubkey()` | Payer's Ed25519 public key (32 bytes) |
| `getPayeePubkey()` | Payee's public key |
| `getAmountMicroSdpkt()` | Amount in micro-₷ (divide by 1M for ₷) |
| `getTimestamp()` | Creation timestamp (Unix ms) |
| `getNonce()` | 16-byte random nonce |
| `getMemo()` | Payment memo (UTF-8, max 92 bytes) |
| `isExpired()` | True if older than `expiry_secs` |
| `toBytes()` | 256-byte raw token |
| `toNdefMessage()` | NFC NDEF message for tap-to-pay |

---

## Rejection reasons (onPaymentRejected)

| Code | Constant | Meaning |
|------|----------|---------|
| 1 | `REASON_EXPIRED` | Token older than expiry_secs |
| 2 | `REASON_DUPLICATE_NONCE` | Nonce already seen (replay attack) |
| 3 | `REASON_INVALID_SIGNATURE` | Signature verification failed |
| 4 | `REASON_INSUFFICIENT_BALANCE` | Payer's offline limit exceeded |
| 5 | `REASON_WALLET_LOCKED` | Wallet requires PIN unlock |
