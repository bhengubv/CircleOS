# Canonical architecture — what goes where, by what name

Pulled together from `docs/docs/dev/architecture.md`, `docs/docs/dev/apis/{butler,mesh,titanium}-api.md`, the existing module names in the `CircleOS_vendor_circle` `circle_base.mk` `PRODUCT_PACKAGES`, the AIDL references inside `CircleSettingsActivity.java`, and the SELinux policy in `vendor/circle/sepolicy/`. This is the contract every new piece of code has to honour.

This document fixes one thing for me explicitly: I spent an evening building services under the wrong package / class / permission names before discovering this. If you are reading this and writing Circle code, **match the names here, don't invent new ones.**

---

## Package namespaces

| Layer | Namespace |
|---|---|
| Client-facing API (AIDL interfaces + manager classes) | `android.circleos.<area>` |
| Server-side service implementation (system_server) | `com.circleos.server.<area>` |
| System apps (Settings, Launcher, Butler, …) | `com.circleos.<app>` for `packages/apps/*`, `za.co.circleos.<area>` for `vendor/circle/apps/*` |
| AIDL **never** lives under `za.co.circleos.*` — that's app-private code only. |

## Permission names

User-facing dangerous / signature permissions are namespaced `android.permission.CIRCLE_<AREA>_<VERB>`:

| Permission | Used by |
|---|---|
| `android.permission.CIRCLE_BUTLER_CHAT` | Apps invoking `ButlerAI.ask()` |
| `android.permission.CIRCLE_MESH_SEND` | `CircleMesh.sendMessage()` |
| `android.permission.CIRCLE_MESH_RECEIVE` | `CircleMesh.registerReceiver()` |
| `android.permission.CIRCLE_WALLET_READ` | `TitaniumWallet.getBalance()`, history |
| `android.permission.CIRCLE_WALLET_PAY` | `TitaniumWallet` payment-token APIs (dangerous, requires user grant — model after `BIND_ACCESSIBILITY_SERVICE`) |

Anything new must follow the same `CIRCLE_<AREA>_<VERB>` pattern.

## Client-facing manager classes + AIDL interfaces

Living at `frameworks/base/core/java/android/circleos/<area>/`. Each `I<X>Service.aidl` is the binder contract; the matching `<X>.java` manager class is the static-getter facade apps use (`Foo.getInstance(context)` style, never raw `ServiceManager.getService("…")`).

| AIDL (in `frameworks/base/core/java/android/circleos/…`) | Manager class | Spec |
|---|---|---|
| `privacy/ICirclePrivacyManagerService.aidl` | (no public manager — Settings binds directly) | `docs/docs/dev/architecture.md`, `vendor/circle/apps/CircleSettings/.../CircleSettingsActivity.java` |
| `mesh/ICircleMeshService.aidl` | `CircleMesh` + `MeshMessage` + `PeerInfo` | `docs/docs/dev/apis/mesh-api.md` |
| `update/ICircleUpdateService.aidl` | `CircleUpdate` *(implied)* | `docs/docs/dev/architecture.md` |
| `butler/IButlerService.aidl` *(implied)* | `ButlerAI` + `ButlerSession` + `ButlerMessage` | `docs/docs/dev/apis/butler-api.md` |
| `wallet/ITitaniumWalletService.aidl` *(implied)* | `TitaniumWallet` + `SdpktToken` + `WalletBalance` | `docs/docs/dev/apis/titanium-api.md` |

## Server-side services (run inside `system_server`)

Living at `frameworks/base/services/core/java/com/circleos/server/<area>/`. Each is started by `SystemServer.java` patches inside the `CircleOS_platform_frameworks_base` fork and registered with `ServiceManager` under a fixed binder name. Spec sources: `docs/docs/dev/architecture.md`, `vendor/circle/sepolicy/circle_*.te`.

### Privacy Engine — `com.circleos.server.privacy`

| Class | Function |
|---|---|
| `CirclePrivacyManagerService` | Umbrella service — binder face of the engine, owns the state file under `/data/circle/privacy/`. Bound by `CircleSettingsActivity` for the Privacy Dashboard. **Module name in `PRODUCT_PACKAGES`.** |
| `CirclePermissionService` | Permission orchestrator — auto-revoke scheduling, runtime permission grant log. **Module name in `PRODUCT_PACKAGES`.** |
| `NetworkPermissionEnforcer` | Routes per-app outbound network through INetd `DOZABLE` chain to enforce deny-by-default. |
| `FakeResponseProvider` | Returns synthetic identifiers per-UID when an app reads denied data, so legacy apps don't crash on denial. |
| `PrivacyLogger` | JSONL audit log at `/data/circle/privacy/log.jsonl`. |

### Security Engine — `com.circleos.server.security`

| Class | Function |
|---|---|
| `BehavioralSandbox` | Watches syscalls + network + `/proc` for anomaly patterns. |
| `DataAcuityClient` | WebSocket feed from the Data Acuity threat-intel backend. |
| `FileDmzService` | CDR pipeline — quarantines downloads, disarms active content, releases the sanitised copy. |
| `QuarantineManager` | JSONL quarantine store under `/data/circle/security/`. |

### Update Service — `com.circleos.server.update`

| Class | Function |
|---|---|
| `CircleUpdateService` | OTA state machine — check / download / verify / install / reboot, A/B aware. |
| `DeviceEnrollment` | Registers the device with SleptOnAPI for entitlement. |
| `CrashReporter` | Anonymised crash collection + upload. |

### Mesh Service — `com.circleos.server.mesh`

| Class | Function |
|---|---|
| `CircleMeshService` | System service entry point; publishes `circle_mesh` binder. |
| `MeshRouter` | Store-and-forward routing, 5-hop TTL. |
| `MeshProtocol` | Frame encoding / decoding, HMAC verification on every frame. |
| `MeshCrypto` | Ed25519 key management, ECDH key exchange. |
| `PeerManager` | Peer table backed by SQLite under `/data/circle/mesh/peers.db`. |
| `BluetoothLeTransport` | BLE GATT transport — wraps `aether-protocol/android/blue`. |
| `WiFiDirectTransport` | WiFi Direct transport — wraps `aether-protocol/android/green`. |

### Butler Engine — `com.circleos.server.butler` *(implied)*

| Class | Function |
|---|---|
| `LlamaCppBackend` | On-device LLM via llama.cpp JNI. |
| `PersonalityManager` | Mode-based system-prompt selection and conversation memory. |
| `ContextDetector` | Pulls user-permitted context (calendar, contacts, location) into a turn's prompt. |

### Titanium Service — `com.circleos.server.wallet` *(implied)*

| Class | Function |
|---|---|
| `SdpktTitanium` | TEE-backed wallet, ed25519 signing inside Keymaster/StrongBox. |
| `SettlementQueue` | Offline transaction log; settled against the central ledger when network returns. |

## System apps

Two parallel families ship — this is intentional per the spec's layered design — but they need distinct Soong module names to coexist in `PRODUCT_PACKAGES`. **Known collision:** both `packages/apps/CircleSettings/Android.bp` and `vendor/circle/apps/CircleSettings/Android.bp` declare `name: "CircleSettings"` today. The vendor copy should be renamed (proposal: `CircleSettingsCompanion`) — open task.

| Path | Package | Role |
|---|---|---|
| `packages/apps/CircleSettings` | `com.circleos.settings` | The full Settings shell — Privacy Dashboard, AppPrivacyDetail, MeshSettings, UpdateSettings, SetupWizard, ThreatIntelUpdater. |
| `packages/apps/CircleLauncher` | `com.circleos.launcher` | Home launcher with privacy status widget. |
| `vendor/circle/apps/Butler` | `za.co.circleos.butler` | Chat + call screening + Wallet skill. |
| `vendor/circle/apps/CircleMessages` | `za.co.circleos.messages` | Mesh-only messaging. |
| `vendor/circle/apps/CircleSettings` | `za.co.circleos.settings` | **TODO: rename.** Companion settings panel (different namespace, narrower scope). |
| `vendor/circle/apps/InferenceBridge` | `za.co.circleos.inferencebridge` | Ollama-compatible HTTP front door on `127.0.0.1:11434`. |
| `vendor/circle/apps/PersonalityEditor` | `za.co.circleos.personalityeditor` | Mode editor + community + learning suggestions. |
| `vendor/circle/apps/PersonalityTile` | `za.co.circleos.personalitytile` | Quick Settings tile for mode switching. |
| `vendor/circle/apps/SdpktTitanium` | `za.co.circleos.sdpkt.app` | Wallet UI + NFC HCE service + lock-screen quick-pay tile. |
| `vendor/circle/apps/TrafficLobby` | `za.co.circleos.trafficlobby` | The local VPN that does DPI / DGA detection / threat matching. |

## /data layout

| Path | Owner | Contents |
|---|---|---|
| `/data/circle/privacy/grants.db` | `CirclePrivacyManagerService` | Per-app network + sensor grant decisions |
| `/data/circle/privacy/log.jsonl` | `PrivacyLogger` | Audit log of every grant decision and reveal |
| `/data/circle/security/quarantine/` | `FileDmzService` | Files held pending CDR scan |
| `/data/circle/security/threat_intel.db` | `DataAcuityClient` | Local cache of the threat feed |
| `/data/circle/mesh/peers.db` | `PeerManager` | SQLite peer table |
| `/data/circle/mesh/inbox/` | `CircleMeshService` | Mesh-store messages awaiting delivery |
| `/data/circle/inference/` | `LlamaCppBackend` | Active gguf model + KV cache |
| `/data/circle/update/manifest.json` | `CircleUpdateService` | Cached OTA manifest |

## What is *not* implemented yet (the actual gap)

`PRODUCT_PACKAGES` in `build/circle/target/product/circle_base.mk` lists `CirclePrivacyManagerService` and `CirclePermissionService` — neither of those module names exists as a Soong `java_library` anywhere in the synced canonical repos. The same applies to `CircleMeshService`, `CircleUpdateService`, `FileDmzService`, `LlamaCppBackend`, `SdpktTitanium` (the *server*, not the app), and friends. The architecture is documented; the Java is not yet written.

This means the canonical build cannot succeed today — a fresh `lunch circle_arm64-userdebug && m systemimage` will fail at Soong analysis with missing-module errors for every entry in the table above.

The path forward is to land those `frameworks/base/services/core/java/com/circleos/server/<area>/` directories one service at a time, each with:

  1. Soong module: `java_library_static` named exactly as the `PRODUCT_PACKAGES` entry, included by `services/Android.bp`.
  2. SystemService skeleton: `public final class <Name>Service extends SystemService` with `onStart()` publishing a binder and `onBootPhase()` hydrating state.
  3. AIDL: `frameworks/base/core/java/android/circleos/<area>/I<X>Service.aidl` matching the spec contract.
  4. SystemServer registration: a `services/java/com/android/server/SystemServer.java` patch that calls `mSystemServiceManager.startService(<Name>Service.class)` inside `startOtherServices`.
  5. SELinux: the existing `vendor/circle/sepolicy/circle_*.te` files already declare the service-manager types — service `.te` is only needed if the service runs in its own process (which most do not — they ride `system_server`).

Suggested implementation order (each step unblocks the next):

  1. `CirclePrivacyManagerService` + `CirclePermissionService` — the umbrella that everything else binds to for grant decisions
  2. `NetworkPermissionEnforcer` — wires INetd, makes the deny-by-default real
  3. `FakeResponseProvider` — keeps legacy apps from crashing
  4. `CircleMeshService` (+ MeshRouter + MeshProtocol + transports) — wraps the existing `aether-protocol/android/*` Kotlin code via JNI
  5. `CircleUpdateService` — A/B OTA, depends on Mesh for P2P chunk delivery
  6. `BehavioralSandbox` + `FileDmzService` + `DataAcuityClient` — the security stack
  7. Butler + Titanium server-side engines
