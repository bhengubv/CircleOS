# `vendor/circle/` — Circle OS source tree

Everything that makes a vanilla AOSP build into Circle OS lives here.
The directory is rsynced into `aosp/vendor/circle/` at sync time by
`scripts/sync-vendor.sh`; upstream patches that touch `frameworks/base`
live separately under `patches/frameworks-base/`.

## Build integration

A device's `device.mk` adds Circle with a single line:

```make
$(call inherit-product, vendor/circle/circle.mk)
```

`circle.mk` is the single source of truth for which Circle modules ship
in an image. Adding a new module is two changes: drop its directory
here, then append its module name to `PRODUCT_PACKAGES` in `circle.mk`.

## Layout

```
vendor/circle/
├── README.md                  ← this file
├── circle.mk                  ← product makefile fragment
├── permissions/
│   └── privapp-permissions-circle.xml
│
├── privacy/                   ← Step 1 — IMPLEMENTED
│   ├── Android.bp             ← services.circleprivacy java_library
│   ├── aidl/za/co/circleos/privacy/ICirclePrivacyManager.aidl
│   ├── java/com/circleos/privacy/CirclePrivacyService.java
│   └── sepolicy/
│       ├── circle_privacy.te
│       └── service_contexts
│
├── inference/                 ← Step 2 — AIDL + service skeleton
│   ├── aidl/za/co/circleos/inference/
│   │   ├── ICircleInferenceManager.aidl
│   │   └── IInferenceTokenStream.aidl
│   └── java/com/circleos/inference/CircleInferenceService.java
│       (StubCompleter v0 — llama.cpp/BitNet JNI lands later)
│
├── personality/               ← Step 3 — IMPLEMENTED through catalogue
│   ├── aidl/za/co/circleos/personality/
│   │   ├── ICirclePersonalityManager.aidl
│   │   ├── PersonalityMode.aidl
│   │   └── IPersonalityChangeListener.aidl
│   ├── java/com/circleos/personality/
│   │   ├── PersonalityMode.java
│   │   └── CirclePersonalityService.java
│   └── data/modes.json        ← 14-mode catalogue, 3 tiers
│
├── mesh/                      ← Step 4 — AIDL + stub service
│   ├── aidl/za/co/circleos/mesh/
│   │   ├── ICircleMeshManager.aidl
│   │   ├── MeshNode.aidl / MeshHealth.aidl
│   │   └── IMeshInboxListener.aidl
│   └── java/com/circleos/mesh/
│       ├── MeshNode.java / MeshHealth.java
│       └── CircleMeshService.java
│       (StubMeshBackend v0 — Rust/JNI to aether-protocol lands later)
│
├── security/                  ← Step 5 — AIDL + Parcelables
│   ├── aidl/za/co/circleos/security/
│   │   ├── ICircleSecurityManager.aidl
│   │   ├── TrafficEvent.aidl
│   │   ├── QuarantinedFile.aidl
│   │   └── ThreatIndicator.aidl
│   └── java/com/circleos/security/
│       ├── TrafficEvent.java
│       ├── QuarantinedFile.java
│       └── ThreatIndicator.java
│
├── sdpkt/                     ← Step 6 — AIDL + Parcelables
│   ├── aidl/za/co/circleos/sdpkt/
│   │   ├── ICircleSdpktManager.aidl
│   │   ├── WalletInfo.aidl / OfflineTransaction.aidl / DeviceLink.aidl
│   │   └── IBalanceChangeListener.aidl
│   └── java/com/circleos/sdpkt/
│       ├── WalletInfo.java
│       ├── OfflineTransaction.java
│       └── DeviceLink.java
│
├── ota/                       ← Step 8 — AIDL + Parcelables
│   ├── aidl/za/co/circleos/ota/
│   │   ├── ICircleOtaManager.aidl
│   │   ├── BuildDescriptor.aidl / DownloadProgress.aidl
│   │   └── IOtaProgressListener.aidl
│   └── java/com/circleos/ota/
│       ├── BuildDescriptor.java
│       └── DownloadProgress.java
│
├── design/                    ← Step 9 — IMPLEMENTED (resources only)
│   └── res/
│       ├── values/{colors,dimens,strings,themes}.xml
│       ├── values-night/colors.xml
│       └── font/comfortaa.xml
│
└── apps/                      ← Step 7 — NOT STARTED
    (CircleMessages, Butler, CircleSettings, InferenceBridge,
     PersonalityTile, PersonalityEditor, SdpktTitanium, TrafficLobby)
```

## Status snapshot (matches commits on `main`)

| # | Step | AIDL | Service / data | Catalogue / res | In `circle.mk` | Built |
|---|------|------|-----------|--------|---------------|-------|
| 1 | Privacy | ✅ | ✅ | n/a | ✅ | in progress |
| 2 | Inference | ✅ | ✅ (stub Completer) | n/a | no | no |
| 3 | Personality | ✅ | ✅ (loads JSON) | ✅ 14 modes | no | no |
| 4 | Mesh | ✅ | ✅ (stub Backend) | n/a | no | no |
| 5 | Security | ✅ | data only | n/a | no | no |
| 6 | SDPKT | ✅ | data only | n/a | no | no |
| 7 | 8 apps | — | — | — | — | — |
| 8 | OTA | ✅ | data only | n/a | no | no |
| 9 | Design System | n/a | n/a | ✅ base res | no | no |

Step 1 is the only one currently in `circle.mk` because its build needs
to prove green before the other modules ride on the same module pattern.
Once `m services.circleprivacy` passes, the others are unblocked.

## Module pattern (followed by all services)

1. **AIDL contract** under `aidl/za/co/circleos/<area>/` — every method
   versioned via `getApiVersion()`. Parcelables get a one-line `.aidl`
   marshalling stub plus a hand-written `.java` impl.

2. **Service impl** in `java/com/circleos/<area>/` — extends
   `com.android.server.SystemService`. Binder enforces a
   `za.co.circleos.permission.<X>` per method. State persists via
   `AtomicFile` under `/data/system/`.

3. **Pluggable backend interface** where the real impl is heavyweight
   (Inference: `Completer`; Mesh: `MeshBackend`). v0 ships a stub
   backend so the binder path is fully testable on a device before the
   native code lands.

4. **SELinux** under `sepolicy/` — one `.te` file declaring the service
   manager type, one `service_contexts` line mapping the binder name to
   the SELinux type.

5. **Android.bp** declaring a `java_library` named
   `services.circle<area>`, included into `services.jar` via
   `PRODUCT_PACKAGES` in `circle.mk`.

6. **SystemServer registration patch** under
   `../patches/frameworks-base/` — uses the String overload so
   `SystemServer.java` doesn't import Circle classes (avoids upstream
   coupling).
