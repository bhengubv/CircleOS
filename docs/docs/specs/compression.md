# Compression & Delta OTA — Technical Specification

## Overview

Circle OS uses binary delta patching to reduce OTA update sizes by ~90% compared to full image downloads. Updates are distributed over HTTPS and optionally via the mesh network in content-addressed chunks.

---

## Delta Generation (server-side)

### Algorithm

Circle OS uses **bsdiff** (BSD-licensed binary diff) applied to raw partition images:

```
bsdiff <old_image.img> <new_image.img> <delta.patch>
```

The resulting patch file contains:
- A control block (what to copy from old + new data)
- A diff block (XOR differences)
- An extra block (new data not derivable from old)

Compressed with **bzip2** at level 9 for maximum size reduction.

### Manifest

Each release includes a manifest JSON describing available deltas:

```json
{
  "version": "1.0.4",
  "channel": "stable",
  "timestamp": 1740000000,
  "deltas": [
    {
      "from_version": "1.0.3",
      "to_version": "1.0.4",
      "partition": "system",
      "url": "https://ota.circleos.co.za/deltas/system-1.0.3-1.0.4.patch",
      "sha256": "abc123...",
      "size_bytes": 183500000,
      "full_sha256": "def456...",
      "full_size_bytes": 2100000000
    }
  ]
}
```

---

## Client-Side Application

### Download verification

Before applying any delta:

1. SHA-256 of downloaded patch file verified against manifest
2. If mismatch: re-download (up to 3 retries), then fall back to full image
3. Signature of manifest JSON verified against `CIRCLEOS_RELEASE_PUBLIC_KEY`

### Patch application

```
bspatch <current_slot_image> <new_image_temp> <delta.patch>
```

After patch application:
1. SHA-256 of resulting image verified against `full_sha256` in manifest
2. If mismatch: discard and fall back to full image download
3. If match: write to inactive A/B slot

### A/B slot mechanics

```
Slot A (active, running)    Slot B (inactive)
       ↓                          ↑
   User uses phone       Update written here
                                  ↓
                          SHA-256 verified
                                  ↓
                          next reboot → switch to B
                          (auto-rollback if B fails to boot)
```

The `update_engine` daemon (standard Android) manages slot switching. Circle OS adds:
- Custom OTA client (`CircleUpdateService`) that fetches from SleptOnAPI
- Staged rollout: device is only offered update if `hash(device_id) % 100 < rollout_percent`
- Mesh chunk reception (see below)

---

## Mesh Distribution

### Chunk format

Large updates are split into 64 KB chunks for mesh distribution:

```
Chunk header (16 bytes):
  magic:          0x43484E4B  ("CHNK")
  chunk_index:    uint32
  total_chunks:   uint32
  sha256_chunk:   first 4 bytes of chunk SHA-256 (quick integrity check)

Chunk body (up to 65536 bytes):
  raw bytes of delta patch slice
```

Full 32-byte SHA-256 of each chunk is verified after reassembly.

### Distribution protocol

```
1. Phone A has delta patch cached
2. Phone A broadcasts availability over BLE:
   "CIRCLEOS_OTA:version=1.0.4:from=1.0.3:chunks=2812:sha256=abc..."
3. Phone B (needs update) connects to Phone A over WiFi Direct
4. Phone B requests missing chunks by index
5. Phone A streams chunks
6. Phone B stores in SQLite chunk store until all received
7. Phone B reassembles, verifies full SHA-256, applies delta
```

The chunk store uses SQLite for durability:

```sql
CREATE TABLE ota_chunks (
    version     TEXT NOT NULL,
    chunk_index INTEGER NOT NULL,
    data        BLOB NOT NULL,
    sha256      TEXT NOT NULL,
    received_at INTEGER NOT NULL,
    PRIMARY KEY (version, chunk_index)
);
```

Partial downloads survive reboots. Expired incomplete downloads (>7 days) are purged.

---

## SleptOnAPI endpoints

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/os/releases/latest?channel={ch}&device={id}` | Check for update, get manifest URL |
| `GET` | `/os/releases/{id}` | Full release details (admin) |
| `GET` | `/os/releases/delta/{fromVersion}?channel={ch}` | Delta URL + SHA256 + size |
| `POST` | `/os/releases` | Publish new release (publisher key) |
| `PATCH` | `/os/releases/{id}` | Adjust rollout percent, activate/deactivate |

See [OTA specification](ota.md) for the full API contract.

---

## Size benchmarks

| Release | Full image | Delta from previous | Reduction |
|---------|-----------|---------------------|-----------|
| 1.0.0 → 1.0.1 | 2.1 GB | 98 MB | 95% |
| 1.0.1 → 1.0.2 | 2.1 GB | 210 MB | 90% |
| 1.0.2 → 1.0.3 | 2.1 GB | 145 MB | 93% |
| 1.0.3 → 1.0.4 | 2.1 GB | 183 MB | 91% |

Benchmarks on Samsung Galaxy A52 with system + vendor partitions.
