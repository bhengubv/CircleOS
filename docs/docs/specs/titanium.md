# Titanium Wallet — Technical Specification

## Overview

Titanium Wallet enables NFC tap-to-pay without internet access using the **SDPKT** (Signed Digital Payment Key Token) protocol. Payments are fully offline-capable; settlement with the Shongololo network occurs asynchronously when connectivity is available.

---

## Protocol: SDPKT v1

### Token structure

```
SDPKT Token (256 bytes):
┌─────────────────────────────────────────────────────────┐
│ Header (4 bytes)                                        │
│   magic:       0x534450  ("SDP")                        │
│   version:     0x01                                     │
├─────────────────────────────────────────────────────────┤
│ Payload (196 bytes)                                     │
│   payer_pubkey:    32 bytes (Ed25519 public key)        │
│   payee_pubkey:    32 bytes (Ed25519 public key)        │
│   amount_sdpkt:    8 bytes  (uint64, micro-₷ units)    │
│   timestamp:       8 bytes  (Unix timestamp ms)         │
│   nonce:           16 bytes (random)                    │
│   currency_code:   4 bytes  ("SDPK")                   │
│   expiry_secs:     4 bytes  (uint32, default 300)       │
│   memo:            92 bytes (UTF-8, null-padded)        │
├─────────────────────────────────────────────────────────┤
│ Signature (64 bytes)                                    │
│   Ed25519 signature of SHA-256(header + payload)        │
└─────────────────────────────────────────────────────────┘
```

### Amount encoding

All amounts are stored in **micro-Shongololo** (μ₷):
- 1 ₷ = 1,000,000 μ₷
- Minimum payment: 100 μ₷ (₷0.0001)
- Maximum offline payment: ₷5,000 (configurable)

---

## Key Management

### Key generation

On first boot (or wallet reset), the device generates:

```
Ed25519 key pair:
  private key → stored in Android Keystore (TEE-backed on supported hardware)
  public key  → registered with Shongololo settlement network on first internet connection
```

### Key storage

- Private key is stored in the **Android Keystore** backed by the Trusted Execution Environment (TEE) where available
- On devices without TEE, the key is stored in software keystore encrypted with the device PIN
- The key is never exported from the device

### Key registration

On internet connection after wallet activation:

```
POST https://api.shongololo.co.za/v1/keys/register
{
  "public_key_b64": "<base64-encoded Ed25519 pubkey>",
  "device_id_hash": "<SHA-256 of device serial + salt>",
  "timestamp": 1740000000000,
  "signature_b64": "<signature of payload>"
}
```

---

## NFC Payment Flow

### Tap-to-pay (payer device)

```
1. User opens Titanium Wallet → tap "Pay"
2. Enter amount and optional memo
3. Device generates SDPKT token:
   - Fills payer_pubkey, amount, timestamp, nonce
   - Signs with private key
4. Token is written to NFC NDEF record (ISO 14443-4)
5. User taps phone to merchant terminal or payee device
6. Token transmitted via NFC
```

### Receive (payee device)

```
1. Payee device reads SDPKT via NFC
2. Verify header magic and version
3. Verify timestamp + nonce: reject if expired (> expiry_secs) or nonce seen before
4. Verify Ed25519 signature against payer_pubkey
5. Check payer_pubkey balance in local settlement cache:
   - If cached balance ≥ amount: accept immediately
   - If not cached: add to pending settlement queue
6. Credit payee balance (provisionally)
7. Display ◯ success animation
```

---

## Settlement

### Deferred settlement

Tokens are queued in the local **SettlementQueue** (SQLite database) and submitted to the Shongololo network when internet is available:

```
POST https://api.shongololo.co.za/v1/settle
{
  "tokens": [ "<base64-SDPKT>", ... ],
  "device_pubkey": "<payee pubkey>",
  "batch_timestamp": 1740000000000,
  "batch_signature": "<signature of token list>"
}
```

The settlement server:
1. Verifies each token signature
2. Checks for double-spend (nonce uniqueness across the network)
3. Deducts from payer's balance
4. Credits payee's balance
5. Returns settlement receipt

### Double-spend protection

- Each token has a 16-byte cryptographically random nonce
- The settlement server maintains a global nonce ledger
- Duplicate nonces are rejected regardless of when they arrive
- Each device also maintains a local nonce cache (24-hour window) for fast rejection before network

### Offline balance limits

The settlement server enforces maximum unconfirmed exposure per public key:
- **Default limit:** ₷1,000 unconfirmed
- **Verified limit:** ₷10,000 (after KYC for higher amounts)
- Payments that would exceed the limit are rejected offline and must wait for settlement

---

## Mesh Payment Relay

In mesh mode, payment tokens can be relayed to settlement via nearby connected nodes:

```
Payee (offline) → Mesh relay (online) → Shongololo settlement server
```

The relay does not have access to the token contents — it forwards the encrypted SDPKT blob as-is. The relay receives a ₷0.001 fee per settled token.

---

## Security Properties

| Property | Mechanism |
|----------|-----------|
| Unforgeability | Ed25519 signature — requires private key |
| Replay prevention | Nonce uniqueness + timestamp expiry |
| Privacy | No persistent device identifier in token (only public key) |
| Double-spend prevention | Network nonce ledger + offline limits |
| Key protection | Android Keystore (TEE on supported hardware) |
| Transport security | NFC NDEF + optional BLE backup channel (encrypted with X25519) |

---

## Related code

| File | Purpose |
|------|---------|
| `frameworks/base/core/java/android/circleos/TitaniumWallet.java` | Wallet entry point, NFC dispatch |
| `frameworks/base/core/java/android/circleos/wallet/SdpktToken.java` | Token construction and verification |
| `frameworks/base/core/java/android/circleos/wallet/SettlementQueue.java` | SQLite queue, HTTP POST to settlement server |
| `frameworks/base/core/java/android/circleos/wallet/KeyManager.java` | Ed25519 key generation and Keystore integration |
