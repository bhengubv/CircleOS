# Canonical architecture — what goes where, by what name

> **State: verified against the live `.201` tree on 2026-06-26.** An earlier version of this
> doc claimed the server services were "not yet written" — that was wrong, and is corrected
> below. The naming conventions remain the contract for any NEW code: **match the names here.**

---

## Package namespaces

| Layer | Namespace |
|---|---|
| Client-facing API (AIDL + manager classes) | `android.circleos.<area>` (ships as the `android.circleos-java` lib) |
| Server-side service impl (system_server) | `com.circleos.server.<area>` |
| System apps | `com.circleos.<app>` for `packages/apps/*`, `za.co.circleos.<area>` for `vendor/circle/apps/*` |

AIDL **never** lives under `za.co.circleos.*` (app-private only).

## Permission names

`android.permission.CIRCLE_<AREA>_<VERB>` — e.g. `CIRCLE_BUTLER_CHAT`, `CIRCLE_MESH_SEND`,
`CIRCLE_MESH_RECEIVE`, `CIRCLE_WALLET_READ`, `CIRCLE_WALLET_PAY` (last is dangerous, user-granted).

## Server-side services — VERIFIED (com.circleos.server.*)

All live in `frameworks/base/services/core/java/com/circleos/server/<area>/`, compile **inside
`services.jar`** (`services.core` globs `java/**/*.java` — they are NOT standalone Soong modules
and must NOT be in `PRODUCT_PACKAGES`), and are started from `SystemServer.java`. Binder names
come from `vendor/circle/sepolicy/service_contexts`.

**Implemented + wired — 9 SystemServices (no stubs, ~3,200 lines total):**

| Service | Binder name | Lines |
|---|---|---|
| `privacy.CirclePrivacyManagerService` | `circle.privacy` (+ `circle_privacy`) | 238 |
| `permission.CirclePermissionService` | `circle.permission` | 364 |
| `update.CircleUpdateService` | `circle.update` | 358 |
| `mesh.CircleMeshService` | `circle.mesh` | 494 |
| `analytics.CircleAnalyticsService` | `circle.analytics` | 191 |
| `camera.CircleCameraPrivacyService` | `circle.camera_privacy` | 145 |
| `clipboard.CircleClipboardPrivacyService` | `circle.clipboard_privacy` | 142 |
| `notification.CircleNotificationPrivacyService` | `circle.notification_privacy` | 148 |
| `backup.CircleBackupService` | `circle.backup` | 327 |

Privacy starts FIRST (before THIRD_PARTY_APPS_CAN_START); Mesh last. Privacy helper classes
(not SystemServices): `NetworkPermissionEnforcer` (256), `PrivacyDatabase` (252, SQLite),
`ScopedContactsProvider` (233), `CircleAutoRevokeScheduler` (57).

**NOT present as server services (despite earlier docs):**
- **Security engine** (`BehavioralSandbox`, `DataAcuityClient`, `FileDmzService`, `QuarantineManager`)
  — no `com/circleos/server/security/` dir. The `vendor/circle/apps/TrafficLobby` app (local VPN +
  DPI/DGA detection) covers part of this surface.
- **Butler server engine** (`LlamaCppBackend`, `PersonalityManager`, `ContextDetector`) — Butler
  ships as a **vendor app** (`vendor/circle/apps/Butler`), not a system_server service.
- **Titanium/Wallet server** (`SdpktTitanium` server, `SettlementQueue`) — ships as a **vendor app**
  (`vendor/circle/apps/SdpktTitanium`), not a system_server service.

## System apps — VERIFIED

- `packages/apps/`: **CircleLauncher** (`com.circleos.launcher`), **CircleSettings** (`com.circleos.settings`).
- `vendor/circle/apps/` — **21 apps:** AetherHandler, BidBaas, Bruh, Butler, CircleMaps, CircleMessages,
  CircleSettings, CircleSetupWizard, HomeCinema, InferenceBridge, Panik, PersonalityEditor, PersonalityTile,
  SdpktTitanium, SleptOn, TagMe, Takemehome, TheJobCenter, TrafficLobby, TrustSeal, WhatWeWant.
- **Module-name collision (open task):** both `packages/apps/CircleSettings` and
  `vendor/circle/apps/CircleSettings` declare `name: "CircleSettings"` — rename the vendor copy
  (proposal `CircleSettingsCompanion`).

## /data layout — VERIFIED paths in use

`/data/system/circle/`, `/data/system_de/circle/privacy.db`, `/data/circle/backup/`.
(Earlier per-area `/data/circle/<area>/…` paths were aspirational, not what the code uses.)

## Build status — VERIFIED 2026-06-26

A valid **`system.img` was built 2026-06-14** (1.77 GB, `out/target/product/generic_arm64/`).

**The one real build break (task #4 "build_jars"):** `build/circle/target/product/circle_base.mk`
`PRODUCT_PACKAGES` (lines 45-46) lists `CirclePrivacyManagerService` and `CirclePermissionService`
as installable modules — but they are framework code inside `services.jar`, and **no Soong module
by those names exists**, so a fresh `m systemimage` fails resolving them. **Fix: remove those two
`PRODUCT_PACKAGES` lines.** The Jun-14 image predates their addition.

## Signing

`PRODUCT_DEFAULT_DEV_CERTIFICATE := vendor/circle/release/security/releasekey` — real release keys
(releasekey/platform/shared/media/networkstack) live there, `.pk8` files mode 600 + gitignored.

## Adding a NEW server service (the contract)
1. `frameworks/base/services/core/java/com/circleos/server/<area>/` — it rides in `services.jar`
   (no separate Soong module, no `PRODUCT_PACKAGES` entry).
2. `public final class <Name>Service extends SystemService` with `onStart()` publishing a binder.
3. AIDL under `android.circleos.<area>` (in the `android.circleos-java` lib).
4. Register in `SystemServer.java` `startOtherServices`.
5. Add the binder name to `vendor/circle/sepolicy/service_contexts`.