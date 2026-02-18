# Architecture

Circle OS is built on Android 14 (AOSP). Most additions are in `frameworks/base` as new system services, with a thin vendor overlay layer in `vendor/circle`.

---

## System diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Applications                              │
│   SleptOn Store │ CircleSettings │ Titanium │ Butler UI          │
└────────────────────────┬────────────────────────────────────────┘
                         │ Binder IPC (AIDL)
┌────────────────────────▼────────────────────────────────────────┐
│                    Circle OS System Services                      │
│                                                                   │
│  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────┐  │
│  │  Privacy Engine  │  │  Security Engine  │  │  Update Service│  │
│  │                 │  │                  │  │                │  │
│  │ CirclePermission│  │ BehavioralSandbox│  │ CircleUpdate   │  │
│  │ NetworkEnforcer │  │ DataAcuityClient │  │ DeviceRegistry │  │
│  │ FakeResponseProv│  │ FileDmzService   │  │ CrashReporter  │  │
│  └─────────────────┘  └──────────────────┘  └────────────────┘  │
│                                                                   │
│  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────┐  │
│  │  Mesh Service   │  │   Butler Engine   │  │Titanium Service│  │
│  │                 │  │                  │  │                │  │
│  │ CircleMeshSvc   │  │ LlamaCppBackend  │  │ SdpktTitanium  │  │
│  │ MeshRouter      │  │ PersonalityMgr   │  │ WalletActivity │  │
│  │ PeerDiscovery   │  │ ContextDetector  │  │ SettlementQueue│  │
│  └─────────────────┘  └──────────────────┘  └────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                     Android 14 AOSP Base                         │
│   Binder │ PackageManager │ ActivityManager │ INetd │ JobScheduler│
└─────────────────────────────────────────────────────────────────┘
```

---

## Key services

### Privacy Engine (`com.circleos.server.privacy`)

| Class | Function |
|-------|---------|
| `CirclePermissionService` | Permission orchestrator — auto-revoke, schedules jobs |
| `NetworkPermissionEnforcer` | Default-deny internet via INetd DOZABLE chain |
| `FakeResponseProvider` | Returns spoofed identifiers per UID |
| `PrivacyLogger` | JSONL audit log at `/data/circle/privacy/log.jsonl` |

### Security Engine (`com.circleos.server.security`)

| Class | Function |
|-------|---------|
| `BehavioralSandbox` | Monitors syscalls, network, proc tables for anomalies |
| `DataAcuityClient` | WebSocket threat intelligence feed |
| `FileDmzService` | CDR pipeline — quarantine, disarm, release |
| `QuarantineManager` | JSONL quarantine store |

### Update Service (`com.circleos.server.update`)

| Class | Function |
|-------|---------|
| `CircleUpdateService` | OTA state machine — check, download, install, A/B |
| `DeviceEnrollment` | Registers device with SleptOnAPI |
| `CrashReporter` | Collects and uploads anonymised crash reports |

### Mesh Service (`com.circleos.server.mesh`)

| Class | Function |
|-------|---------|
| `CircleMeshService` | System service entry point |
| `MeshRouter` | Store-and-forward routing, 5-hop TTL |
| `MeshProtocol` | Frame encoding/decoding, HMAC verification |
| `MeshCrypto` | Ed25519 key management, ECDH key exchange |
| `PeerManager` | Peer table with SQLite persistence |
| `BluetoothLeTransport` | BLE GATT transport |
| `WiFiDirectTransport` | WiFi Direct transport |

---

## AIDL interfaces

Located in `frameworks/base/core/java/android/circleos/`:

- `ICirclePrivacyManagerService.aidl`
- `ICircleUpdateService.aidl`
- `ICircleMeshService.aidl`

---

## Data storage

| Path | Contents |
|------|---------|
| `/data/circle/privacy/` | Network grants DB, permission log |
| `/data/circle/mesh/` | Peer table, message store |
| `/data/circle/inference/` | Active AI model |
| `/data/circle/update/` | OTA manifest cache |
