# OTA Update System Specification

---

## Overview

Circle OS uses A/B (seamless) partitions with delta updates distributed via SleptOnAPI and optionally via mesh. Updates are staged — rolled out to a percentage of devices before full release.

---

## Update flow

```
Device (CircleUpdateService)
    │
    │  GET /os/releases/latest?channel=stable&version=1.0.3&deviceId=xxx
    ▼
SleptOnAPI (OsReleaseService)
    │
    │  { has_update: true, release: { version: "1.0.4", manifest_url: "...", rollout_percent: 25 } }
    ▼
Device
    │
    │  Rollout check: abs(deviceId.hashCode()) % 100 < rollout_percent?
    │  Yes → download manifest + verify signature
    │  No  → skip (try again next poll)
    ▼
Download (delta or full)
    │
    ├─ Try mesh first: request chunks from nearby peers
    └─ Fall back: HTTPS from CDN (Cloudflare R2 via MediaAPI)
    │
    ▼
Verify (SHA-256 per chunk, RSA-4096 on manifest)
    │
    ▼
Apply to inactive slot (A/B)
    │
    ▼
User notification: "Update ready — tap to reboot"
```

---

## Staged rollout

Releases progress through three automatic stages:

| Stage | Rollout % | Min reports | Max failure rate | Min time |
|-------|-----------|-------------|-----------------|---------|
| initial | 5% | 100 | < 2% | 12 hours |
| quarter | 25% | 500 | < 3% | 24 hours |
| full | 100% | — | — | — |

`RolloutAutomationBackgroundService` evaluates all active releases every 30 minutes. Auto-advances if thresholds met. Auto-pauses if failure rate exceeded.

---

## Delta updates

Delta generation uses `bsdiff` on consecutive OTA packages. Typical delta size: 10–15% of full ROM.

```
delta = bspatch(current_slot_image, delta_file)
result = full_image_for_new_version
```

Full OTA available as fallback for devices upgrading from older versions without a delta path.

---

## SleptOnAPI endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/os/releases/latest` | None | Device polling |
| POST | `/os/releases` | `os:publish` | Publish new release |
| GET | `/os/releases/{id}` | `os:admin` | Release detail |
| PATCH | `/os/releases/{id}` | `os:admin` | Update rollout |
| GET | `/os/releases/delta/{from}` | None | Delta info |
| GET | `/api/os/rollout` | `os:admin` | All rollout statuses |
| POST | `/api/os/rollout/{id}/advance` | `os:admin` | Manual advance |
| POST | `/api/os/rollout/{id}/pause` | `os:admin` | Pause rollout |

---

## Device registry

Devices register at first boot via `DeviceEnrollment`:

```json
POST /api/os/devices/enroll
{
  "device_id": "sha256_of_android_id",
  "model": "SM-A525F",
  "channel": "stable",
  "current_version": "1.0.3"
}
```

Boot events, crash reports, and ANRs are uploaded anonymously for rollout health monitoring.
