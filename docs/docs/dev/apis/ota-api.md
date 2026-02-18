# OTA Release API

Base URL: `https://api.slepton.co.za`

All endpoints follow the [API overview](index.md) auth conventions.

---

## POST /os/releases

Publish a new OS release.

**Auth:** `X-Api-Key` with scope `os:publish`
**Content-Type:** `multipart/form-data`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | Yes | Semver: `1.0.4` |
| `channel` | string | Yes | `stable` / `beta` / `nightly` |
| `rollout_percent` | int | Yes | 1–100 |
| `release_notes` | string | No | Markdown release notes |
| `min_version` | string | No | Minimum version that can receive this update |
| `signature_b64` | string | Yes | Base64 Ed25519 signature of manifest JSON |
| `file` | file | Yes | OTA zip (max 2 GB) |

**Response 201:**
```json
{
  "id": 42,
  "version": "1.0.4",
  "channel": "stable",
  "rollout_percent": 5,
  "manifest_url": "https://cdn.slepton.co.za/ota/circeos-1.0.4.zip",
  "is_active": true,
  "created_at": "2026-02-18T10:00:00Z"
}
```

---

## GET /os/releases/latest

Check if an update is available.

**Auth:** None (device polling endpoint)

**Query params:**
- `channel` — `stable` / `beta` / `nightly`
- `current_version` — device's current version (optional)
- `device_id` — anonymised device ID for rollout bucketing (optional)

**Response 200:**
```json
{
  "has_update": true,
  "release": {
    "version": "1.0.4",
    "manifest_url": "https://cdn.slepton.co.za/ota/circeos-1.0.4.zip",
    "rollout_percent": 100,
    "min_version": "1.0.2"
  }
}
```

---

## GET /os/releases/{id}

Get full release details.

**Auth:** `X-Api-Key` with scope `os:admin`

---

## PATCH /os/releases/{id}

Update rollout percent or active status.

**Auth:** `X-Api-Key` with scope `os:admin`

```json
{
  "rollout_percent": 25,
  "is_active": true
}
```

---

## GET /os/releases/delta/{fromVersion}

Get the delta patch URL for upgrading from a specific version.

**Auth:** None (device polling endpoint)

**Query params:**
- `channel` — release channel

**Response 200:**
```json
{
  "delta_url": "https://cdn.slepton.co.za/ota/deltas/1.0.3-to-1.0.4.patch",
  "sha256": "abc123...",
  "size_bytes": 183500000
}
```

**Response 404:** No delta available for this version pair.
