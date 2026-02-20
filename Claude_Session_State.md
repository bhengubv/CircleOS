# CircleOS — Claude Session State

Tracks implementation progress across sessions. Update after each session.

---

## Implementation Status

---

### 1. OS Core — `frameworks/base` ✅ Complete

| Phase | Description | Status |
|-------|-------------|--------|
| OS Phase 1+2 | Privacy framework — ICirclePrivacyManager, ICirclePermissionService, PrivacyRulesEngine, NetworkPermissionEnforcer | ✅ Done |
| OS Phase 3 | Fake response provider, VPN domain filter | ✅ Done |
| OS Phase 4 | OTA update service, network monitor | ✅ Done |
| OS Phase 5 | Notification/clipboard/camera privacy, analytics, backup, DoH | ✅ Done |

#### Post-Phase Privacy Additions

| Commit | Description |
|--------|-------------|
| `c786d831` | T2-05 — `INotificationPrivacyManager` AIDL + `NotificationPrivacyService` (`android/circleos/`) |
| `2a19cc5a` | T1-07/08 — `checkSensorPermission` real implementation; `revokeUnusedPermissions` 30-day scan |

---

### 2. Inference Service ✅ Complete

Package: `za.co.circleos.inference`. Service name: `circle.inference`.

#### `frameworks/base`

| Phase | Description | Status |
|-------|-------------|--------|
| **Inf Phase 1** | Foundation — AIDL, Parcelables, CircleInferenceService, CapabilityDetector, ModelManager, LlamaCppBackend (JNI stub), SystemServer + Manifest | ✅ Done — `52217a0d` |
| **Inf Phase 2** | Rust abstraction layer — `InferenceBackend` trait, JNI bridge Java→Rust, ResourceGovernor, ModelManager download support | ✅ Done — `ca39f5a6` |
| **Inf Phase 3** | BitNet integration — BitNetBackend, backend auto-selection logic, performance benchmarking | ✅ Done — `df19a59a` |
| **Inf Phase 4** | Model store — `getDownloadableModels()`, `downloadModel()` AIDL, service v4 | ✅ Done — `6d9768d3` |

#### Post-Phase Inference Improvements

| Commit | Description |
|--------|-------------|
| `513f3c9a` | T1-01 — Replace JNI stub with real llama.cpp generation loop in `llama_backend.rs` |
| `61858bdb` | T2-09 — Populate `parameterCount` from remote model store manifest |

#### `vendor/circle`

| Phase | Description | Status |
|-------|-------------|--------|
| **Inf Phase 4** | Butler chat app, `CircleInferenceClient` helper library, developer integration docs | ✅ Done — `6819446` |
| **InferenceBridge** | Privileged foreground service exposing `circle.inference` as an Ollama-compatible HTTP REST+SSE API on `127.0.0.1:11434`. 128-bit session token via `ACCESS_INFERENCE`-gated ContentProvider. Endpoints: `GET /api/status\|tags\|capabilities\|personality/mode`, `POST /api/generate\|chat`. Auto-starts at boot. | ✅ Done — `55b5da0`, personality endpoint added `9c0c0ba` |

#### TheGeekNetwork `.NET` Cross-Platform Client Library

Repo: `/Users/admin/Code/Dev/TheGeekNetwork/` — `code/Shared/TheGeekNetwork.Shared.CircleInference/`

| Item | Description | Status |
|------|-------------|--------|
| `CircleInferenceClient.cs` | `GenerateAsync`, `StreamAsync` (IAsyncEnumerable SSE), `ChatAsync` (OpenAI-style), `ListModelsAsync`, `GetCapabilitiesAsync`, `IsAvailableAsync`, `GenerateTextAsync`, **`GetPersonalityModeAsync`** | ✅ Done |
| `Models/` | `InferenceRequest`, `InferenceResponse`, `StreamToken`, `ModelInfo`, `DeviceCapabilities`, **`PersonalityModeInfo`** | ✅ Done |
| `Streaming/SseParser.cs` | SSE → `IAsyncEnumerable<StreamToken>` | ✅ Done |
| `Platforms/Android/` | `BridgeTokenHelper` — ContentProvider token acquisition | ✅ Done |
| `Platforms/Default/` | `BridgeTokenHelper` — env var fallback | ✅ Done |
| `Exceptions/InferenceException.cs` | 13 error code constants | ✅ Done |
| `README.md` | Full usage docs including Personality Mode integration | ✅ Done |
| Solution file | Added to `TheGeekNetwork.sln` Shared folder | ✅ Done — `066d1ac` |
| Commits | Initial library: `244f349` · Solution: `066d1ac` · README: `8c72a34` · Personality: `eb36635` | |

#### Inference ↔ Personality Mode Integration ✅ Done

| Item | Description | Commit |
|------|-------------|--------|
| `GET /api/personality/mode` | InferenceBridge endpoint — reads `circle.personality` via `ServiceManager`, returns `id`, `name`, `description`, `tier`, `isCustom` | vendor/circle `9c0c0ba` |
| `inference-service-integration.md` | "Personality Mode–Aware Inference" section — Java code for mode reading, `systemPromptForMode()` helper, `IPersonalityCallback` for live changes, mode ID reference table | vendor/circle `9c0c0ba` |
| `GetPersonalityModeAsync()` | .NET client method returning `PersonalityModeInfo` | TheGeekNetwork `eb36635` |
| .NET `README.md` | Mode-aware system prompt pattern (C# switch expression), polling example, mode ID reference table | TheGeekNetwork `eb36635` |

#### Inference Ecosystem — Geek Network Apps ✅ Partial Complete

The Geek Network apps live in a separate repo at `/Users/admin/Code/Dev/TheGeekNetwork/`.
Inference integration for each app is a separate future task.

| App | Repo Location | AI Use Case | Status |
|-----|--------------|-------------|--------|
| Butler | `vendor/circle/apps/Butler` | General-purpose assistant, conversational UI | ✅ Done (Phase 4) |
| SidePocket (SDPKT) | `TheGeekNetwork/Apps/SidePocket` | Budget analysis, transaction categorisation, streaming Q&A | ✅ Done — `c886b3a` |
| TagMe | `TheGeekNetwork/Apps/TagMe` | Nearby POI/event recommendations, location assistant | ✅ Done — `c886b3a` |
| TheJobCenter | `TheGeekNetwork/Apps/TheJobCenter` | Job summary, skill gap, profile improvement, SA market context | ✅ Done — `c886b3a` |
| MatchMaster | `TheGeekNetwork/Apps/MatchMaster` | TBD | ⬜ Not Started |
| BhenguBV | `TheGeekNetwork/Apps/BhenguBV` | TBD | ⬜ Not Started |

**Commit `c886b3a` (TheGeekNetwork):** Each app received: `CircleInference` project reference in `.csproj`, `com.circleos.permission.ACCESS_INFERENCE` in `AndroidManifest.xml`, `CircleInferenceClient` singleton + scoped `I<Domain>AssistantService`/`<Domain>AssistantService` in `MauiProgram.cs`, and `Services/I<Domain>AssistantService.cs` + `Services/<Domain>AssistantService.cs` with SA-context system prompts and streaming `AskAsync(IAsyncEnumerable<string>)` methods.

---

### 3. OS Personality Engine ✅ Complete

Enables users to activate curated "modes" that configure features, apps, and settings for specific contexts.

#### Modes by Tier

| Tier | Ships | Modes |
|------|-------|-------|
| Tier 1 | With OS | Minimal, Daily, Work, Job Candidate, Student, Secure, Offline |
| Tier 2 | Download on activation | Sport, Creator, Driver, Party, Parent, Elder, Gaming |
| Tier 3 | Download on activation | Trader, Developer, Health, Travel, Entrepreneur, Night |

#### Implementation Phases

| Phase | Description | Status |
|-------|-------------|--------|
| **PE Phase 1** | Foundation — Mode Manager, manual switching, Tier 1 modes, basic notification rules, quick settings integration | ✅ Done — frameworks/base `cfd1883e`, vendor/circle `b378c30` |
| **PE Phase 2** | Intelligence — auto-switch triggers, conflict resolver, emergency bypass, state preservation, notification broker | ✅ Done — frameworks/base `e231fe4e` |
| **PE Phase 3** | Customisation — mode editor, custom mode creation, per-mode app management, import/export | ✅ Done — frameworks/base `a04d6254`, vendor/circle `f312394` |
| **PE Phase 4** | Lifestyle Modes — Tier 2 modes, download-on-activation flow, mode-specific app bundles | ✅ Done — frameworks/base `6b0269a9`, vendor/circle `61f6291` |
| **PE Phase 5** | Advanced — managed modes (parental/enterprise), auto-switch learning, Tier 3 specialist modes, community sharing | ✅ Done — frameworks/base `9ddd3546`, vendor/circle `2476f96` |

#### Post-Phase Bug Fixes & UX Additions (vendor/circle)

| Commit | Description |
|--------|-------------|
| `f1d62ec4` | frameworks/base — BundleDownloadManager: register Tier-3 bundles alongside Tier-2 |
| `d77d309` | ModeChooserActivity: Tier-3 bundle download support + cancel button |
| `7e9072d` | PersonalityEditor: Tier-2/3 bundle download flow in PersonalityMainActivity |
| `301d331` | CommunityActivity: fix broken community import + Tier-2/3 bundle download flow |
| `c9c314c` | PersonalityTile: Phase 5 managed-mode PIN unlock dialog in ModeChooserActivity |

---

### 4. Circle OS Design System ✅ Complete

**Version:** 1.0 | **Owner:** The Geek (Pty) Ltd | **Base:** The Geek Network Design System v2.1
**Commits:** vendor/circle `79ab409` (50 files) · `05748f5` (font + A-01 fix) · TheGeekNetwork `f99ce93` (6 files)

| # | Area | Description | Status |
|---|------|-------------|--------|
| 1 | Theme architecture scaffolding | `Android.bp`, `AndroidManifest.xml`, `colors.xml`, `dimens.xml`, `type.xml`, `themes.xml`, `styles.xml`, `motion.xml` | ✅ Done |
| 2 | Mode colour overlays | 8 `colors_mode_*.xml` — Daily, Work, Secure, Sport, Party, Night, Student, Creator | ✅ Done |
| 3 | Typography integration | `type.xml` (15-step Display→Label scale), `font/comfortaa.xml` (400/500/700), font scale constants (0.85x–1.30x) | ✅ Done |
| 4 | Mode icons — vector drawables | 15 `ic_mode_*.xml` — outlined, 24dp, 2dp stroke, accent colour | ✅ Done |
| 5 | Component styles | Primary/Secondary/Text buttons, Cards, QS tiles (active/inactive), Notification cards, Mode badge, Focus indicator — 9 `bg_*.xml` drawables | ✅ Done |
| 6 | Motion — mode transition animation | `mode_transition.xml` (300ms crossfade), `mode_transition_fade_out/in.xml`, `motion.xml` duration scale (0–400ms), reduced-motion support | ✅ Done |
| 7 | Elder Mode overrides | `themes_mode_elder.xml` — 1.3x font scale, 56dp targets, enhanced contrast, 1.25x spacing multiplier | ✅ Done |
| 8 | Night Mode overrides | `themes_mode_night.xml` — warm brown accent (#5D4037), dim overlay (#80000000), reduced contrast | ✅ Done |
| 9 | Secure Mode overrides | `themes_mode_secure.xml` + `bg_notification_card_secure.xml` — dark red accent (#B71C1C), accent border on notification cards | ✅ Done |
| 10 | Accessibility audit | `docs/design-system-accessibility-audit.md` — WCAG 2.1 AA contrast ratios, touch target table, focus indicator spec, reduced-motion, known issues | ✅ Done |
| 11 | .NET / MAUI design token port | `CircleColors`, `CircleSpacing`, `CircleTypography`, `CircleModeTheme` + `CircleModeThemeBundle` in `TheGeekNetwork.Shared.CircleDesign` | ✅ Done |

**Mode accents:** Daily `#2196F3` · Work `#607D8B` · Secure `#B71C1C` · Sport `#FF5722` · Party `#E91E63` · Night `#5D4037` · Student `#009688` · Creator `#9C27B0`

---

### 5. Circle OS Security Architecture ✅ Phases 1–3 + Post-Phase Complete

**Philosophy:** Defense in depth — If it's man-made, we can beat it. Pegasus is useless if it can't phone home.

#### Phase 1: Core Security ✅ — `71ed576a` · vendor/circle `81faa3e`

| Task | Description |
|------|-------------|
| #55 | File DMZ service — `CircleFileDmzService` (`circle.file_dmz`), SHA-256 intake, feed hash check, CDR orchestration, session management, quarantine |
| #56 | CDR for images and PDFs — `CdrProcessor`: image re-encode (strips metadata/exploits); PDF passthrough |
| #57 | Traffic Lobby VPN app — local VPN TUN `10.0.0.1/24`, `TrafficAnalyzer`, PARANOID/BALANCED/RELAXED modes, DGA entropy (Shannon >3.5), beaconing |
| #58 | Threat feed integration — `ThreatFeedDatabase` (in-memory IP/domain/hash blocklists), `ThreatFeedUpdater` (24h stale-check) |
| #59 | Spyware behavior detection — `SpywareBehaviorDetector`: mic/camera/location flags + upload correlation |

#### Phase 2: Advanced Protection ✅ — `6783d222`

| Task | Description |
|------|-------------|
| #60 | Full CDR — Office ZIP (strip VBA), HTML (strip script/iframe/on*), ZIP (recursive depth-3, drop executables), media passthrough |
| #61 | Behavioral analysis sandbox — `BehavioralSandbox`: PE/ELF magic, VBA macros, PowerShell, Base64 >200, URL/IP extraction (up to 5 MB) |
| #62 | Malware Jail — `QuarantineManager` (`circle.quarantine`): encrypted dir, files renamed `.quarantine`, flat-JSON index |
| #63 | Community Defense opt-in — `CommunityDefenseService`: anonymized IOC sharing (hash/domain/IP only); 6h batched ±30min jitter |
| #64 | Data Acuity integration — `DataAcuityClient`: atomic feed download, Ed25519 verification placeholder, IOC batch POST |

#### Phase 3: Intelligence ✅ — `5f853a3c`

| Task | Description |
|------|-------------|
| #65 | `IocExtractor` — STIX 2.1 `toStixIndicator()` per IOC; patterns: IPv4, domain, SHA-256, beacon |
| #66 | `CampaignCorrelator` — /24 subnet, beacon interval ±5%, 72h window; MITRE ATT&CK TTP mapping (T1071/T1568/T1027/T1102) |
| #67 | `InfrastructureMapper` — "Zombie Map" graph; predicts /24 when ≥3 IPs confirmed (SUBNET_PREDICTION_THRESHOLD=3) |
| #68 | `ResearcherApiService` (`circle.researcher_api`) — STIX 2.1 bundle output via `IocBundle.stixJson` |

#### Post-Phase Security Improvements

| Commit | Description |
|--------|-------------|
| `2450002d` | Community Defense correlation + Researcher API + Ed25519 sigs |
| `995b16b6` | QuarantineManager JSONL persistence (flat-JSON → append-only log) |
| `67ab42c0` | ResearcherApiService: replace in-memory IOC list with SQLite |
| `d753ef08` | InfrastructureMapper: populate KNOWN_BAD_ASNS seed set |
| `249aa4ce` | T2-02 — Replace Data Acuity placeholder Ed25519 key with real key |
| `77e72459` | T2-03 — DataAcuityClient: WebSocket real-time threat push |
| `a1e59fa1` | T2-04 — BehavioralSandbox: namespace isolation |
| `729b3e5d` | Fix DataAcuityClient key override, BehavioralSandbox IPv6, netd retry |

#### Traffic Lobby Post-Phase Improvements (vendor/circle)

| Commit | Description |
|--------|-------------|
| `ab1085a` | T1-04 — Real IPv4 DPI packet loop + spyware alerting in `TrafficLobbyVpnService` |
| `996154f` | Exclude Circle Mesh subnets from VPN tunnel (prevents mesh traffic interception) |

---

### 6. Circle OS Compression ✅ Phase 1 Complete, Phase 2 Partial

**Commit:** frameworks/base `c910f488` (17 files, 1,629 insertions)

**Pipeline (inbound):** scan → CDR → **compress** → clean+small file released to app

| Engine | What it handles | Savings |
|--------|----------------|---------|
| `ImageCompressor` | JPEG/WebP quality re-encode; PNG lossless; GIF passthrough; EXIF fully stripped | 40–70% |
| `DocumentCompressor` | PDF XMP strip; Office ZIP repack at DEFLATE-9; core.xml author/revision zeroed | 20–60% |
| `ArchiveCompressor` | ZIP repack DEFLATE-9; drops `__MACOSX`, `.DS_Store`, OS extra fields | 20–40% |
| `MetadataStripper` | JPEG/WebP ExifInterface; PNG tEXt/iTXt/zTXt/eXIf chunks; PDF inline metadata | privacy |
| `CompressionStatsTracker` | Monthly inbound/outbound bytes saved → `/data/circle/compression/stats.json` | dashboard |

#### Phase 2 Partial Work

| Commit | Description |
|--------|-------------|
| `94d8800a` | Phase 2 PDF image recompression in `DocumentCompressor` |
| `63378ef8` | Video/audio metadata stripping in `CdrProcessor` |

#### Phase 2 — ✅ Complete

| Commit | Description |
|--------|-------------|
| `5059ac15` | C2-01 — `VideoCompressor.java` (HEVC via MediaCodec, 2Mbps/1Mbps targets, audio passthrough); `AudioCompressor.java` (AAC-LC 96kbps/64kbps via MediaCodec); `ZstdCompressor.java` (JNI-based ZSTD with DEFLATE-9 fallback; loads `libcircle_zstd_jni.so`); `CircleCompressionService`: registered with `LocalServices`, added `isVideo()`/`isAudio()` dispatch, `compressOutbound()` Traffic Lobby hook, extended `guessMime()` for video/audio |

#### Remaining Phase 2 Items

| Feature | Notes |
|---------|-------|
| ZSTD JNI native library | `ZstdCompressor.java` loads `libcircle_zstd_jni.so`; JNI C file needs `cc_library_shared` in Android.bp and `external/zstd` dep |

---

### 7. Circle OS Mesh Networking ✅ Core Complete

Service: `circle.mesh` | `frameworks/base/services/core/java/com/circleos/server/mesh/`

#### Implementation

| Commit | Description |
|--------|-------------|
| `4c968fc8` | Phase B — BLE GATT server + client in `BluetoothLeTransport.java` for WiFi-IP bootstrap; `CircleMeshService` integration |
| `8575c45f` | T1-02 — Real BLE GATT client in `PeerDiscovery` |
| `d6a0947f` | T2-08 — Fix BLE service UUID to match `BluetoothLeTransport` |
| `2a19cc5a` | T1-03 — Full `TYPE_MSG_*` / `TYPE_TX_*` / `TYPE_FILE_*` switch dispatch in `CircleMeshService`; `routeTxFrame()` → `SdpktTitaniumService.onMeshTxFrame()` |

#### Sepolicy (vendor/circle `9998138`)
- `sepolicy/circle_mesh.te`, `circle_service.te`, `file_contexts`, `property_contexts`

#### Post-Phase Improvements

| Commit | Description |
|--------|-------------|
| `66c70966` | M1-01 — `WifiDirectTransport.setLocalIp()`: includes local IPv4 in DNS-SD TXT "ip" field; discovery callback extracts "ip" from TXT record instead of using MAC address (which broke TCP); `CircleMeshService` feeds local IP to both BLE GATT + WiFi Direct DNS-SD; `broadcastTextMessage()` also delivers to `za.co.circleos.messages` |

#### Remaining

| Feature | Notes |
|---------|-------|
| Store-and-forward | Architecture in place; full message queue deferred |
| CircleBeacon app | Not started |

---

### 8. Circle OS OTA Update System ✅ Phases 1–9 Complete

Service: `circle.update` → `CircleUpdateService` | `frameworks/base/services/core/java/com/circleos/server/update/`

#### Implementation Phases

| Phase | Commit | Description |
|-------|--------|-------------|
| Ph 1–3 | (OS Phase 4) | Basic OTA check, download, apply; build properties |
| Ph 4 | `92bb1190` | Mesh P2P OTA chunk delivery — `MeshOtaDownloader` |
| Ph 5 | `a342e1ec` | A/B delta OTA delivery — `AbSlotManager`, `DeltaChecker`, `MeshOtaDownloader` |
| Ph 6 | `779f47c0` | OS control plane — `OtaPolicyManager`, `UpdateTelemetry` |
| Ph 7 | `f127f73a` | Remote command execution — `RemoteCommandProcessor` |
| Ph 8 | `a1e99f55` | Maintenance windows + boot verification — `MaintenanceWindowChecker`, `BootVerifier` |
| Ph 9 | `47a532b5` | Device enrollment + crash/ANR telemetry — `DeviceEnrollment`, `CrashReporter` |

#### Build Config (vendor/circle)

| Commit | Description |
|--------|-------------|
| `325470d` | `config/circleos_update.mk` — build-time OTA config |
| `9998138` | SEPolicy for update + mesh services |

---

### 9. SDPKT Titanium ✅ Phases 1–6 Complete

**Version:** 1.0 | **Service name:** `circle.sdpkt` | **Currency:** Shongololo (₷)

#### Implementation Phases

| Phase | Description | Commits |
|-------|-------------|---------|
| **Ph 1** | Core Wallet: TEE keys, NFC P2P, signing/verification, balance management, basic UI | frameworks/base `4d50b366`, vendor/circle `e6d80e4` |
| **Ph 2** | Offline: transaction log, settlement queue, double-spend detection, sync protocol | frameworks/base `26b28a9d`, vendor/circle `aba9497` |
| **Ph 3** | Protection Engine: location rules + learning, stress detection (accelerometer + watch) | frameworks/base `2e7d996b`, vendor/circle `101161b` |
| **Ph 4** | Integration: Butler voice, Personality modes, lock screen quick pay, mesh settlement | frameworks/base `df717722`, vendor/circle `4fff2b4` |
| **Ph 5** | Polish: calibration UX, analytics, export/backup, protection log | frameworks/base `68673054`, vendor/circle `7d530ea` |
| **Ph 6** | Multi-device: NFC tap-to-pair, WearLinkManager, wearable stress data, device persistence | frameworks/base `ff469b8f` + `9fc0ff49` |

#### Post-Phase Improvements

| Commit | Description |
|--------|-------------|
| `2a19cc5a` | T1-03 — Mesh TX frame routing → `SdpktTitaniumService.onMeshTxFrame()` |
| `a536b260` | T2-01 — HTTP settlement POST to `sleptonapi.thegeeknetwork.co.za/api/sdpkt/settle` |
| `cbbfb6d3` | T6-01 — Secondary device spending limit enforcement in `ProtectionEngine` + `NfcTransferRequest.senderDeviceId` |

#### Remaining (Phase 7+)

| Item | Notes |
|------|-------|
| Wear OS DataLayer API | WearLinkManager uses broadcasts now; full DataLayer sync deferred |
| Settlement backend validation | Test HTTP POST in staging; confirm 200/409 handling |

---

### 10. CircleMessages App ✅ Complete

**Location:** `vendor/circle/apps/CircleMessages/` | **Commit:** vendor/circle `27f0426`

Platform-signed privileged Android app (`za.co.circleos.messages`) — dedicated mesh P2P messaging UI, built with CircleOS Design System colors.

| Component | Description |
|-----------|-------------|
| `MessageDatabase.java` | SQLite: `messages(id, peer_id, direction, body, timestamp_ms, read)`; `getConversations()` summary; `getMessages(peerId)` thread; `markRead(peerId)` |
| `MeshMessageReceiver.java` | BroadcastReceiver for `ACTION_MESSAGE_RECEIVED`; stores to DB + posts notification with PendingIntent to ConversationActivity |
| `MainActivity.java` | Conversation list from DB; peer count via `ICircleMeshService.getPeerCount()`; tap → ConversationActivity |
| `ConversationActivity.java` | Chat thread; sends via `ICircleMeshService.sendMessage()` (msgType `0x10` = TYPE_MSG_TEXT); left/right bubble alignment |
| Layouts | `activity_main.xml`, `activity_conversation.xml`, `item_conversation.xml`, `item_message.xml` |
| Drawables | `bg_bubble_inbound.xml` (grey rounded), `bg_bubble_outbound.xml` (Circle Deep `#1A1F36`), `bg_unread_badge.xml` (Circle Gold oval), `ic_messages.xml` |

`CircleMeshService.broadcastTextMessage()` updated to deliver to `za.co.circleos.messages` (alongside `za.co.circleos.butler`).

---

### 12. Butler App ✅ Enhanced

**Location:** `vendor/circle/apps/Butler/`

| Commit | Description |
|--------|-------------|
| `6819446` | Phase 4 — initial Butler chat app + inference client library |
| `a1093b5` | Circle Mesh P2P chat — `MeshActivity` + manifest updates |
| `f075a45` | AI call screening service — `ButlerCallScreeningService` |

---

### 13. CircleSettings App ✅ Complete

**Location:** `vendor/circle/apps/CircleSettings/`

| Commit | Description |
|--------|-------------|
| `7aadec3` | T2-06 — Initial APK with `Android.bp`, manifest, `AutoRevokeJobService` |
| `cffc105` | Full UI — OTA status, channel switcher, privacy summary, auto-revoke trigger |

---

## Build System

### Boot Jar Allow List Fix
- **File:** `build/soong/scripts/check_boot_jars/package_allowed_list.txt`
- **Commit:** `37cc7eb` (build/soong repo)
- **Fix:** Added `za\.co\.circleos` and `za\.co\.circleos\..*` — required for all CircleOS packages in `framework.jar`

### macOS Build Fix
- **File:** `external/cronet/third_party/libc++abi/src/src/cxa_thread_atexit.cpp`
- **Fix:** `#ifndef __APPLE__` guards around `__cxa_thread_atexit_impl` weak symbol declaration and runtime check — resolves `ld64.lld: undefined symbol` on macOS

### Current Build
- **Target:** `circle_emulator-ap2a-userdebug` (x86_64 emulator image)
- **Command:** `make droidcore -j` (note: macOS uses `sysctl -n hw.ncpu`, not `nproc`)
- **Status:** Running — Soong analysis phase (soong_build at ~500% CPU); compilation will follow
- **Log:** `/tmp/circle_droidcore.log`
- **Build task:** background task `b65a4fe`

---

## Key Paths

| Resource | Path |
|----------|------|
| AIDL + Parcelables (inference) | `frameworks/base/core/java/za/co/circleos/inference/` |
| AIDL + Parcelables (sdpkt) | `frameworks/base/core/java/za/co/circleos/sdpkt/` |
| AIDL + Parcelables (security) | `frameworks/base/core/java/za/co/circleos/security/` |
| AIDL + Parcelables (compression) | `frameworks/base/core/java/za/co/circleos/compression/` |
| AIDL + Parcelables (mesh) | `frameworks/base/core/java/za/co/circleos/mesh/` |
| Java services | `frameworks/base/services/core/java/com/circleos/server/` |
| JNI bridge | `frameworks/base/services/core/jni/circle_inference_jni.cpp` |
| Rust layer | `frameworks/base/services/core/rust/circle_inference/` |
| SystemServer | `frameworks/base/services/java/com/android/server/SystemServer.java` |
| Manifest | `frameworks/base/core/res/AndroidManifest.xml` |
| CircleMessages app | `vendor/circle/apps/CircleMessages/` |
| Butler app | `vendor/circle/apps/Butler/` |
| CircleSettings app | `vendor/circle/apps/CircleSettings/` |
| InferenceBridge app | `vendor/circle/apps/InferenceBridge/` |
| PersonalityTile app | `vendor/circle/apps/PersonalityTile/` |
| PersonalityEditor app | `vendor/circle/apps/PersonalityEditor/` |
| SdpktTitanium app | `vendor/circle/apps/SdpktTitanium/` |
| TrafficLobby VPN app | `vendor/circle/apps/TrafficLobby/` |
| CircleTheme overlay | `vendor/circle/overlay/CircleTheme/` |
| Inference client lib (Android) | `vendor/circle/libs/inference-client/` |
| InferenceBridge docs | `vendor/circle/docs/inference-service-integration.md` |
| .NET inference client | `TheGeekNetwork/code/Shared/TheGeekNetwork.Shared.CircleInference/` |
| .NET design tokens | `TheGeekNetwork/code/Shared/TheGeekNetwork.Shared.CircleDesign/` |
| Geek Network apps | `/Users/admin/Code/Dev/TheGeekNetwork/Apps/` |
| Model dirs | `/system/circle/models/` (bundled), `/data/circle/models/` (downloaded) |
| Threat feeds | `/data/circle/security/feeds/` |
| SDPKT transaction log | `/data/circle/sdpkt/pending.jsonl` |
| Compression stats | `/data/circle/compression/stats.json` |

---

## Device Tier Reference

| Tier | RAM | Backend | Model |
|------|-----|---------|-------|
| 1 | 2–3 GB | llama.cpp Q4 | Qwen 0.5B |
| 2 | 4–6 GB | llama.cpp Q4 | Qwen 1.5B / BitNet 2B |
| 3 | 6–8 GB | BitNet.cpp | BitNet 2B-4T |
| 4 | 8–12 GB | BitNet.cpp | BitNet 7B (future) |
| 5 | 12 GB+ | BitNet.cpp | BitNet 14B+ (future) |

---

## Notes

- All Circle services are Java (not Kotlin) — matches existing 16 services
- Rust layer goes via Soong (platform-level), not NDK
- BitNet.cpp added in Phase 3; `llama_native`/`bitnet_native` feature flags gate real FFI; T1-01 replaced the JNI stub with a real llama.cpp generation loop
- `libcircle_inference.so` is the shared library loaded by `LlamaCppBackend.java`
- InferenceBridge is a platform-signed privileged app (`platform` cert); token lives in memory only — never persisted
- `.NET` client uses `Platforms/Android/` vs `Platforms/Default/` conditional compilation for token acquisition
- Inference ↔ Personality integration complete: `GET /api/personality/mode` returns active mode; `.NET` `GetPersonalityModeAsync()` wraps it
- Design System is a `runtime_resource_overlay` (platform cert) targeting the `android` package — no code, resources only
- Comfortaa variable font (OFL) bundled — `prebuilt/fonts/comfortaa_variable.ttf`, uses `fontVariationSettings` for 400/500/700 weights (API 26+)
- Security Phase 1: `CircleFileDmzService` (`circle.file_dmz`); permissions `ACCESS_FILE_DMZ` (normal) + `MANAGE_TRAFFIC_LOBBY` (signature)
- Security Phase 2: `QuarantineManager` (`circle.quarantine`) + `CommunityDefenseService` (`circle.community_defense`)
- Security Phase 3: `ResearcherApiService` (`circle.researcher_api`); permission `RESEARCHER_API` (signature|privileged); STIX 2.1 via `IocBundle.stixJson`
- Traffic Lobby is a privileged platform-signed app (local VPN only); T1-04 added real IPv4 DPI packet loop; mesh subnets excluded from tunnel
- `BehavioralSandbox` is static analysis (not a micro-VM); T2-04 added namespace isolation
- `DataAcuityClient` fetches from `https://feeds.dataacuity.circleos.co.za`; T2-02 replaced placeholder Ed25519 key; T2-03 added WebSocket real-time push
- `CampaignCorrelator`: /24 subnet, beacon interval ±5%, 72h window; MITRE ATT&CK TTP IDs (T1071/T1568/T1027/T1102)
- `InfrastructureMapper`: predicts /24 when ≥3 IPs confirmed; KNOWN_BAD_ASNS seed set populated (T-commit)
- Compression: TIER_VISUALLY_LOSSLESS by default; skip if compressed ≥95% of original; Phase 2 PDF image recompression + video/audio metadata stripping done
- SDPKT: `NfcTransferRequest.senderDeviceId` feeds `ProtectionEngine` step 2.5 for per-device limit enforcement; settlement HTTP POST to sleptonapi
- OTA Phases 4-9 are an enterprise fleet management layer built on top of the base OTA service — mesh chunk delivery, A/B slots, remote commands, device enrollment, crash reporting
- CircleSettings: `AutoRevokeJobService` runs the 30-day idle permission scan from `CirclePrivacyManagerService.revokeUnusedPermissions()`
- SEPolicy covers: circle_mesh domain, circle_service domain, file_contexts for `/data/circle/`, property_contexts for `circle.*`
