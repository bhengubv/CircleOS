# Mesh API (Android)

The Mesh API is an Android system API. It is not a REST API — it communicates with `CircleMeshService` via AIDL.

---

## Permissions

Add to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CIRCLE_MESH_SEND" />
<uses-permission android:name="android.permission.CIRCLE_MESH_RECEIVE" />
```

Mesh permissions are granted by default to apps with `signature` protection level (system apps). Third-party apps must be granted mesh access by the user in Settings.

---

## CircleMesh

```java
import android.circleos.mesh.CircleMesh;
import android.circleos.mesh.MeshMessage;
import android.circleos.mesh.PeerInfo;

CircleMesh mesh = CircleMesh.getInstance(context);
```

### Send a message

```java
MeshMessage msg = new MeshMessage.Builder()
    .setRecipientPubkey(recipientPubkeyBytes)  // Ed25519 public key, 32 bytes
    .setContent(contentBytes)                   // arbitrary bytes, max 60 KB
    .setTtl(5)                                  // max relay hops
    .setType(MeshMessage.TYPE_DATA)             // TYPE_DATA or TYPE_CONTROL
    .build();

mesh.sendMessage(msg, new CircleMesh.SendCallback() {
    @Override public void onQueued(String messageId) { }
    @Override public void onDelivered(String messageId) { }
    @Override public void onFailed(String messageId, int reason) { }
});
```

### Receive messages

```java
mesh.registerReceiver(new CircleMesh.MessageReceiver() {
    @Override
    public void onMessageReceived(MeshMessage message) {
        byte[] content = message.getContent();
        byte[] senderPubkey = message.getSenderPubkey();
        // process message
    }
}, /* filter */ null);

// Unregister when done
mesh.unregisterReceiver(receiver);
```

### Query peers

```java
List<PeerInfo> peers = mesh.getConnectedPeers();
for (PeerInfo peer : peers) {
    Log.d(TAG, "Peer: " + peer.getDisplayName()
        + " transport: " + peer.getTransport()
        + " rssi: " + peer.getRssi());
}
```

---

## MeshMessage

| Method | Description |
|--------|-------------|
| `getMessageId()` | Unique message ID (UUID) |
| `getSenderPubkey()` | Sender's Ed25519 public key (32 bytes) |
| `getRecipientPubkey()` | Recipient's public key |
| `getContent()` | Decrypted message content |
| `getTimestamp()` | Unix timestamp (ms) when message was created |
| `getTtl()` | Remaining relay hops |
| `getType()` | `TYPE_DATA` or `TYPE_CONTROL` |

---

## PeerInfo

| Method | Description |
|--------|-------------|
| `getNodeId()` | Truncated public key (8 bytes, hex) |
| `getDisplayName()` | Human-readable name set by peer |
| `getTransport()` | `TRANSPORT_BLE` / `TRANSPORT_WIFI_DIRECT` / `TRANSPORT_MDNS` |
| `getRssi()` | Signal strength (dBm) |
| `isRelay()` | Whether peer is acting as a relay |

---

## Error codes (onFailed)

| Code | Constant | Meaning |
|------|----------|---------|
| 1 | `REASON_NO_ROUTE` | No path to recipient within TTL hops |
| 2 | `REASON_TIMEOUT` | No delivery confirmation within 7 days |
| 3 | `REASON_CONTENT_TOO_LARGE` | Content exceeds 60 KB limit |
| 4 | `REASON_PERMISSION_DENIED` | App lacks mesh send permission |
| 5 | `REASON_MESH_DISABLED` | User has disabled mesh in settings |
