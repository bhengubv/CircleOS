# Canonical architecture — what goes where, by what name

> **State: verified against the working tree on 2026-09-15, Android 16
> (`android-16.0.0_r4`).** The previous version was verified against `.201` on 2026-06-26,
> when the base was Android 14. It said 9 server services, ~3,200 lines, and that security
> and wallet were *not* server services. All three statements are now out of date — there
> are 13, 5,525 lines, and both security and wallet are server services. Corrected below.
>
> The naming conventions remain the contract for any NEW code: **match the names here.**
>
> **Base moved 14 → 16.** These services were written against Android 14 and have not yet
> been compiled against 16. Where the doc says a thing works, it means it worked on 14.

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

**13 SystemServices, 5,525 lines across 21 files.** Counted on 2026-09-15.

| Service | Binder name | Lines | sepolicy entry |
|---|---|---|---|
| `privacy.CirclePrivacyManagerService` | `circle.privacy` | 238 | yes |
| `permission.CirclePermissionService` | `circle.permission` | 374 | yes |
| `update.CircleUpdateService` | `circle.update` | 372 | yes |
| `mesh.CircleMeshService` | `circle.mesh` | 797 | yes |
| `analytics.CircleAnalyticsService` | `circle.analytics` | 195 | yes |
| `camera.CircleCameraPrivacyService` | `circle.camera_privacy` | 149 | yes |
| `clipboard.CircleClipboardPrivacyService` | `circle.clipboard_privacy` | 152 | yes |
| `notification.CircleNotificationPrivacyService` | `circle.notification_privacy` | 156 | yes |
| `backup.CircleBackupService` | `circle.backup` | 336 | yes |
| `security.CircleSecurityService` | `circle.quarantine` | 223 | **MISSING** |
| `wallet.ShongololoWalletService` | `circle.sdpkt` | 912 | **MISSING** |
| `update.CrashReporter` | *(publishes no binder)* | 124 | n/a |
| `update.DeviceEnrollment` | *(publishes no binder)* | 127 | n/a |

**Two gaps, found 2026-09-15 and not yet fixed.** `circle.quarantine` and `circle.sdpkt`
publish binders that have no entry in `vendor/circle/sepolicy/service_contexts` — step 5 of
the contract below. Registration will be denied by SELinux.

`CrashReporter` and `DeviceEnrollment` extend `SystemService` but publish nothing. They are
lifecycle hooks, not services; do not go looking for their binder names.

Privacy starts FIRST (before THIRD_PARTY_APPS_CAN_START); Mesh last. Helper classes
(not SystemServices): `NetworkPermissionEnforcer` (258), `PrivacyDatabase` (255, SQLite),
`CircleAutoRevokeScheduler` (57), `MeshRouter` (163), `MeshLinkPrivacy` (155),
`WalletFrame` (57), `WalletMath` (78), `CircleSystemPreferences` (347).

`ScopedContactsProvider` (235) was listed here as a privacy helper. On 2026-09-15 it was
moved to `vendor/circle/apps/CircleSettings/src/com/circleos/server/privacy/` because
CircleSettings' manifest declares it as a `<provider>`, and Android instantiates a declared
provider in the *app* process — with the class in `services.jar` the app died at startup with
`RuntimeException: Unable to get provider ... at ActivityThread.installProvider`. Whether that
is the right home on Android 16 is **unverified**; it is recorded here as a change, not a
ruling.

**Now present, contradicting the 2026-06-26 version of this doc:**
- **Security** — `com/circleos/server/security/CircleSecurityService.java` exists and implements
  `ICircleQuarantine`. The named classes (`BehavioralSandbox`, `DataAcuityClient`,
  `FileDmzService`, `QuarantineManager`) still do not. The `vendor/circle/apps/TrafficLobby`
  app (local VPN + DPI/DGA detection) covers part of this surface.
- **Wallet** — `com/circleos/server/wallet/ShongololoWalletService.java`, 912 lines, the largest
  single file in the tree. It holds keystore material inside `system_server`; that is a security
  decision worth making deliberately rather than inheriting.
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