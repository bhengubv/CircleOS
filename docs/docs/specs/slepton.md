# SleptOn App Store — Technical Specification

## Overview

SleptOn is the Circle OS native app store. It operates as a system service (`SleptOnService`) that handles app discovery, installation, payment processing via Titanium Wallet, and peer-to-peer APK distribution over the Circle OS mesh network.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  SleptOn App (Android)                              │
│    SleptOnActivity → ISleptOnService (AIDL)         │
├─────────────────────────────────────────────────────┤
│  SleptOnService (system service)                    │
│    AppCatalogManager  — fetch + cache app listings  │
│    InstallManager     — APK download + verification │
│    PaymentBridge      — Titanium Wallet integration │
│    MeshDistributor    — peer-to-peer APK sharing    │
│    SandboxRunner      — pre-install behavioural scan│
└─────────────────────────────────────────────────────┘
         ↓ HTTPS                        ↓ BLE/WiFi Direct
┌──────────────────┐         ┌─────────────────────────┐
│  SleptOnAPI      │         │  Peer Circle OS devices │
│  (cloud backend) │         │  (mesh APK distribution)│
└──────────────────┘         └─────────────────────────┘
```

---

## App Catalogue

### API endpoints (SleptOnAPI)

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/apps` | List apps (paginated, filterable) |
| `GET` | `/api/apps/{id}` | Full app details |
| `GET` | `/api/apps/search?q={query}` | Search |
| `GET` | `/api/apps/{id}/versions` | Version history |
| `POST` | `/api/apps/{id}/install-event` | Record install (anonymised) |

### App listing response

```json
{
  "id": 42,
  "package_name": "co.za.example.app",
  "name": "Example App",
  "developer": "Example Dev",
  "category": "utilities",
  "description": "...",
  "icon_url": "https://cdn.slepton.co.za/icons/example.png",
  "screenshot_urls": ["..."],
  "version": "2.1.0",
  "version_code": 210,
  "apk_url": "https://cdn.slepton.co.za/apks/example-2.1.0.apk",
  "apk_sha256": "abc123...",
  "size_bytes": 8500000,
  "price_sdpkt": 0,
  "rating": 4.7,
  "install_count": 12400,
  "permissions": ["android.permission.INTERNET", "android.permission.CAMERA"],
  "privacy_score": 82,
  "last_updated": "2026-01-15T10:00:00Z"
}
```

### Privacy score

Each app receives a **privacy score** (0–100) computed by SleptOnAPI's scanner:

| Factor | Max points |
|--------|-----------|
| Requests no dangerous permissions | 30 |
| No tracker SDKs detected | 25 |
| No network access requested | 15 |
| Open source | 15 |
| No ads | 10 |
| No analytics | 5 |

---

## Installation Flow

```
1. User taps "Install" in SleptOnActivity
2. SleptOnService.requestInstall(appId) called via AIDL
3. InstallManager checks local APK cache (by SHA-256)
   a. Cache hit → skip download
   b. Cache miss → check mesh peers first, then download from CDN
4. APK SHA-256 verified
5. APK passed to BehavioralSandbox.analyzeApk()
   - Decompile + scan for known-bad patterns
   - Run in isolated process for 30 seconds, observe syscalls
   - Return SandboxReport (risk_level: LOW/MEDIUM/HIGH)
6. If risk_level HIGH → block install, show report to user
7. If risk_level MEDIUM → show report, require user confirmation
8. If risk_level LOW → install via PackageManager.installPackage()
9. Record install event (no user ID, no device ID — only country, category, version)
```

---

## Payment Flow (paid apps)

```
1. User taps "Buy for ₷X"
2. SleptOnService.initiatePayment(appId, amount) called
3. PaymentBridge calls TitaniumWallet.createPayment(amount, memo="SleptOn:appId")
4. TitaniumWallet generates SDPKT token, deducts from local balance
5. Token submitted to SleptOnAPI:
   POST /api/payments/app-purchase
   { app_id, sdpkt_token_b64 }
6. SleptOnAPI verifies token + credits developer account
7. Returns purchase receipt with download token
8. InstallManager uses download token to fetch APK from CDN (one-time URL)
9. Install proceeds as above
```

---

## Mesh APK Distribution

### Availability broadcast (BLE)

```
BLE service UUID: 0000SLPT-0000-1000-8000-00805F9B34FB
Characteristic:   READ — JSON payload:
{
  "node_id": "<truncated pubkey>",
  "apps": [
    { "pkg": "co.za.example", "ver": "2.1.0", "sha256": "abc..." },
    ...
  ]
}
```

### Chunk transfer (WiFi Direct)

Same 64 KB chunk protocol as OTA (see [Compression spec](compression.md)), applied to APK files.

Chunk store:
```sql
CREATE TABLE apk_chunks (
    package_name TEXT NOT NULL,
    version_code INTEGER NOT NULL,
    chunk_index  INTEGER NOT NULL,
    data         BLOB NOT NULL,
    sha256       TEXT NOT NULL,
    received_at  INTEGER NOT NULL,
    PRIMARY KEY (package_name, version_code, chunk_index)
);
```

---

## Developer Publishing

### Submission API (authenticated)

```
POST /api/developer/apps
Authorization: Bearer <dev_token>
Content-Type: multipart/form-data

Fields:
  apk        (file)
  icon       (file, PNG 512x512)
  screenshots[] (files, PNG 1280x720)
  name        (string)
  description (string)
  category    (string)
  price_sdpkt (int, 0 = free)
  source_url  (string, optional)
```

### Automated checks

1. APK signature verification (valid certificate)
2. Package name uniqueness
3. Permission manifest review (flag dangerous permissions)
4. Known malware signature scan (SHA-256 against blocklist)
5. Tracker SDK detection (classname matching)
6. Privacy score computation

### Review SLA

| Risk level | Review time |
|-----------|------------|
| Low (no dangerous perms, open source) | Automated — published instantly |
| Medium (limited dangerous perms) | Human review within 48 hours |
| High (many dangerous perms or trackers detected) | Human review within 7 days |

---

## Related code

| File | Purpose |
|------|---------|
| `vendor/circle/apps/SleptOn/` | SleptOn Android APK source |
| `frameworks/base/core/java/android/circleos/SleptOnService.java` | System service entry point |
| `SleptOnAPI/Endpoints/AppEndpoints.cs` | REST API for catalogue |
| `SleptOnAPI/Endpoints/DeveloperEndpoints.cs` | Publisher API |
| `SleptOnAPI/Services/AppScannerService.cs` | Privacy score + tracker detection |
