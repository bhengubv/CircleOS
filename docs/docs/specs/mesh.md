# Mesh Protocol Specification

**Location:** `frameworks/base/services/core/java/com/circleos/server/mesh/`

---

## Overview

Circle OS devices form a peer-to-peer mesh network using WiFi Direct, Bluetooth LE, and mDNS. The mesh implements store-and-forward delivery with a 5-hop TTL.

---

## Frame format

```
┌──────────┬──────────┬──────────┬──────────┬──────────────────┬──────────┐
│  Magic   │  Version │   Type   │   TTL    │    Payload       │   HMAC   │
│ 2 bytes  │  1 byte  │  1 byte  │  1 byte  │  variable        │ 32 bytes │
└──────────┴──────────┴──────────┴──────────┴──────────────────┴──────────┘
```

| Field | Value |
|-------|-------|
| Magic | `0xC1 0x05` |
| Version | `0x01` |
| Type | `0x01` MSG, `0x02` ACK, `0x03` PING, `0x04` PEER_ANNOUNCE |
| TTL | 1–5 (decremented at each hop) |
| HMAC | HMAC-SHA256 over (magic + version + type + ttl + payload) |

---

## Cryptography

**Key generation:** Ed25519 (256-bit) per device. Stored in Android KeyStore (hardware-backed where available).

**Key exchange:** X25519 ECDH. Peers exchange public keys during `PEER_ANNOUNCE`. Shared secret used to derive ChaCha20-Poly1305 session key.

**Message encryption:**
```
ciphertext = ChaCha20-Poly1305(key=session_key, nonce=random_12_bytes, plaintext=payload)
```

**Replay protection:** 64-bit nonce counter per session, monotonically increasing.

---

## Transport layers

| Transport | Class | Range | Discovery |
|-----------|-------|-------|-----------|
| WiFi Direct | `WiFiDirectTransport` | ~100m | `WifiP2pManager` discovery |
| Bluetooth LE | `BluetoothLeTransport` | ~30m | GATT service UUID `00C1AAAA-…` |
| mDNS | `MdnsTransport` | LAN | `_circleos._tcp.local` |

Transports are tried in order: mDNS → WiFi Direct → BLE.

---

## Routing algorithm

1. On send, check local peer table for direct route to destination peer ID.
2. If found: send directly via fastest available transport.
3. If not found: broadcast to all known peers (flooding with TTL decrement).
4. Each relay node checks its delivery cache — if already seen this message ID, drop.
5. At TTL=0, drop the frame.

**Delivery cache:** LRU cache of 1000 message IDs, 1-hour TTL.

---

## Store-and-forward

Messages that cannot be delivered immediately are stored in SQLite:

```sql
CREATE TABLE mesh_messages (
    id           TEXT PRIMARY KEY,   -- UUID
    dest_peer_id TEXT NOT NULL,
    payload      BLOB NOT NULL,
    created_at   INTEGER NOT NULL,
    expire_at    INTEGER NOT NULL,   -- created_at + 7 days
    delivered    INTEGER DEFAULT 0
);
```

Stored messages are retried every 30 seconds when the destination peer is seen.

---

## OTA chunk distribution

When a device has an OTA update locally, it announces availability via `PEER_ANNOUNCE` with metadata:
```json
{ "type": "ota_chunk", "version": "1.0.4", "chunk_index": 3, "total_chunks": 47, "sha256": "..." }
```

Requesting peers fetch chunks directly via WiFi Direct. Integrity verified per-chunk via SHA-256.
