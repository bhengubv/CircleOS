# Circle OS APIs

Circle OS exposes APIs at multiple levels: Android system APIs (Java/Kotlin), AIDL interfaces for inter-process communication, and the SleptOnAPI REST endpoints for cloud services.

---

## Android system APIs

Circle OS adds the following packages to the Android SDK:

| Package | Description |
|---------|-------------|
| `android.circleos` | Entry points: `CircleOsManager`, `TitaniumWallet`, `ButlerAI` |
| `android.circleos.privacy` | Privacy Engine: `NetworkPermissionManager`, `PrivacyDashboard` |
| `android.circleos.mesh` | Mesh network: `CircleMesh`, `MeshMessage`, `PeerInfo` |
| `android.circleos.wallet` | Titanium Wallet: `SdpktToken`, `WalletBalance` |

### Getting a system manager

```java
CircleOsManager circleOs = (CircleOsManager)
    context.getSystemService(Context.CIRCLE_OS_SERVICE);

// Or via the convenience APIs
TitaniumWallet wallet = TitaniumWallet.getInstance(context);
ButlerAI butler = ButlerAI.getInstance(context);
```

---

## AIDL interfaces

Circle OS system services use AIDL for cross-process communication. Apps should prefer the Java convenience wrappers above; the AIDL interfaces are for system components and advanced use.

| Interface | Service | Purpose |
|-----------|---------|---------|
| `ICircleMeshService` | `CircleMeshService` | Send/receive mesh messages, query peers |
| `ICirclePrivacyService` | `CirclePrivacyService` | Query/modify network permissions |
| `ICircleWalletService` | `CircleWalletService` | Create SDPKT tokens, query balance |
| `ICircleUpdateService` | `CircleUpdateService` | Check for/apply OTA updates |
| `ICircleFileDmzService` | `CircleFileDmzService` | Submit files for sanitisation, query quarantine |
| `ICircleNotificationPrivacyService` | `CircleNotificationPrivacyService` | Control notification metadata stripping |
| `ISleptOnService` | `SleptOnService` | Install apps, query catalogue |

AIDL definitions are in:
```
frameworks/base/core/java/android/circleos/aidl/
```

---

## SleptOnAPI REST endpoints

Base URL: `https://api.slepton.co.za`

### Authentication

All authenticated endpoints require either:

- `Authorization: Bearer <dev_token>` (developer portal token)
- `X-Api-Key: <api_key>` (API key with appropriate scope)

Scopes: `os:publish`, `os:admin`, `app:publish`, `app:admin`.

### Endpoint groups

| Group | Base path | Auth | Description |
|-------|-----------|------|-------------|
| OTA releases | `/os/releases` | publish/admin | Publish and manage OS releases |
| App catalogue | `/api/apps` | public/publish | Browse and submit apps |
| Waitlist | `/api/circle/waitlist` | public | Join/query device waitlist |
| Devices | `/api/circle/devices` | public | Device compatibility catalogue |
| Developer | `/api/developer` | bearer | Developer account management |
| Payments | `/api/payments` | bearer | App purchase settlement |

See the full API reference pages for each group:

- [OTA Release API](ota-api.md)
- [App Catalogue API](app-api.md)
- [Developer API](developer-api.md)
- [Waitlist API](waitlist-api.md)

---

## Example: check for update

```bash
curl "https://api.slepton.co.za/os/releases/latest?channel=stable&device=abc123"
```

```json
{
  "has_update": true,
  "release": {
    "version": "1.0.4",
    "manifest_url": "https://ota.circleos.co.za/stable/circeos-1.0.4.zip",
    "rollout_percent": 100,
    "min_version": "1.0.2"
  }
}
```

---

## Example: send a mesh message (Android)

```java
CircleMesh mesh = CircleMesh.getInstance(context);

MeshMessage msg = new MeshMessage.Builder()
    .setRecipientPubkey(recipientPublicKey)
    .setContent("Hello from offline!".getBytes(StandardCharsets.UTF_8))
    .setTtl(5)
    .build();

mesh.sendMessage(msg, new MeshMessage.SendCallback() {
    @Override
    public void onQueued(String messageId) {
        Log.d(TAG, "Message queued: " + messageId);
    }

    @Override
    public void onDelivered(String messageId) {
        Log.d(TAG, "Message delivered: " + messageId);
    }

    @Override
    public void onFailed(String messageId, int reason) {
        Log.e(TAG, "Message failed: " + reason);
    }
});
```

---

## Example: create a payment token (Android)

```java
TitaniumWallet wallet = TitaniumWallet.getInstance(context);

wallet.createPayment(
    /* amount μ₷ */ 50_000_000L,  // ₷50
    /* memo */ "Coffee",
    new TitaniumWallet.PaymentCallback() {
        @Override
        public void onTokenReady(SdpktToken token) {
            // Write token to NFC
            nfcAdapter.writeNdefMessage(token.toNdefMessage());
        }

        @Override
        public void onError(int errorCode) {
            Log.e(TAG, "Payment failed: " + errorCode);
        }
    }
);
```
