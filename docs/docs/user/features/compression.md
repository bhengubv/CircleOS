# Delta Compression & Storage

Circle OS reduces update sizes by up to 90% and keeps your storage efficient through several complementary technologies.

---

## Delta OTA Updates

Traditional OS updates require downloading the full system image every time — often 1–3 GB. Circle OS uses **binary delta patches** instead.

| Update type | Typical size |
|-------------|-------------|
| Full system image | 2.1 GB |
| Circle OS delta patch | ~180 MB |
| Reduction | ~91% |

### How deltas work

1. The update server computes a binary diff between your current version and the new version
2. Only the changed bytes are packaged — most of the OS stays identical between releases
3. Your phone downloads and verifies the delta, then applies it to reconstruct the new image
4. If verification fails, the download is retried; if application fails, the old version is preserved

### A/B updates (seamless)

Circle OS uses Android's A/B partition scheme:

- Your phone has two complete system slots (A and B)
- Updates are applied to the **inactive** slot while you keep using your phone normally
- On the next reboot, the phone switches to the updated slot
- If the new slot fails to boot, it automatically rolls back to your previous slot

This means you are **never stuck mid-update** with a broken phone.

---

## Mesh Update Distribution

When you are connected to a Circle OS mesh network, you can receive updates from nearby phones instead of the internet — and share updates you already have.

```
Phone A (has update) → Phone B (needs update)
           ↓ BLE / WiFi Direct
    Delta chunk transfer
           ↓
    Phone B applies delta
           ↓
    Phone B can now seed to Phone C
```

This is especially useful during:
- Load shedding (no internet)
- Expensive data environments
- Remote areas with poor connectivity

---

## Storage Management

Circle OS uses several techniques to keep your storage clean:

| Feature | What it does |
|---------|-------------|
| **App asset compression** | Compresses infrequently-used APK assets without quality loss |
| **Photo deduplication** | Identifies near-duplicate photos and lets you review/remove them |
| **Download cleanup** | Flags downloads older than 30 days for review |
| **Cache trim** | Automatically trims per-app caches when free space is below 1 GB |
| **Update cleanup** | Removes old delta packages after successful update |

### Storage dashboard

**Settings → Circle OS → Storage** shows:

- Total and free space
- Breakdown by category (apps, media, downloads, system, cached data)
- Estimated savings from compression
- "Clean up" shortcut

---

## Technical notes

- Delta algorithm: [bsdiff](http://www.daemonology.net/bsdiff/) applied to raw partition images
- Verification: SHA-256 of resulting partition before applying, SHA-256 of delta download
- Chunk size for mesh distribution: 64 KB (configurable in `circleos_update.mk`)
- A/B slot management: standard Android `update_engine` with Circle OS OTA client
