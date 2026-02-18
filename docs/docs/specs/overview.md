# Technical Specifications — Overview

Circle OS is built on Android 14 (AOSP, API level 34). This section documents the technical design of each major subsystem.

---

## Design goals

| Goal | How |
|------|-----|
| **Privacy by default** | Default-deny internet, identifier spoofing, permission auto-revoke |
| **Offline-first** | All core features work without internet; mesh for connectivity |
| **On-device AI** | No cloud inference — Qwen models run locally |
| **Hardware-grade security** | TEE keystore, CDR file pipeline, behavioral sandbox |
| **Low overhead** | Minimal services, no telemetry, no background bloat |
| **AOSP compatible** | Built on standard AOSP; no secret APIs |

---

## Base

| Property | Value |
|----------|-------|
| AOSP base | Android 14 (API 34) |
| Branch | `circle-14.0-clean` |
| Build system | Soong + Make (Android.bp + .mk) |
| Languages | Java 17, C++17, Rust (inference), Kotlin (apps) |
| Min SDK | API 26 (Android 8.0) |

---

## Subsystems

| Subsystem | Spec |
|-----------|------|
| Privacy Engine | [privacy.md](security.md) |
| Security Engine | [security.md](security.md) |
| Mesh Protocol | [mesh.md](mesh.md) |
| Titanium / SDPKT | [titanium.md](titanium.md) |
| Compression | [compression.md](compression.md) |
| OTA System | [ota.md](ota.md) |
| SleptOn | [slepton.md](slepton.md) |

---

## Key numbers

| Metric | Value |
|--------|-------|
| New services added to AOSP | 12 |
| AIDL interfaces | 3 |
| SQLite databases | 6 |
| Mesh max hop count | 5 |
| OTA delta compression ratio | ~90% smaller than full ROM |
| Privacy events logged per day (typical) | 200–500 |
| AI inference tiers | 5 (0.5B → 14B parameters) |
