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

Both systems now cross-reference each other. Apps adapt system prompts based on the active mode.

| Item | Description | Commit |
|------|-------------|--------|
| `GET /api/personality/mode` | InferenceBridge endpoint — reads `circle.personality` via `ServiceManager`, returns `id`, `name`, `description`, `tier`, `isCustom` | vendor/circle `9c0c0ba` |
| `inference-service-integration.md` | "Personality Mode–Aware Inference" section — Java code for mode reading, `systemPromptForMode()` helper, `IPersonalityCallback` for live changes, mode ID reference table | vendor/circle `9c0c0ba` |
| `GetPersonalityModeAsync()` | .NET client method returning `PersonalityModeInfo` | TheGeekNetwork `eb36635` |
| .NET `README.md` | Mode-aware system prompt pattern (C# switch expression), polling example, mode ID reference table | TheGeekNetwork `eb36635` |

#### Inference Ecosystem — Geek Network Apps ⬜ Not Started

The Geek Network apps live in a separate repo at `/Users/admin/Code/Dev/TheGeekNetwork/`.
They will be integrated as native Android apps built into the CircleOS image.
Inference integration for each app is a separate future task.

| App | Repo Location | AI Use Case | Status |
|-----|--------------|-------------|--------|
| Butler | `vendor/circle/apps/Butler` | General-purpose assistant, conversational UI | ✅ Done (Phase 4) |
| SidePocket (SDPKT) | `TheGeekNetwork/Apps/SidePocket` | Transaction explanations, fraud detection | ⬜ Not Started |
| TagMe | `TheGeekNetwork/Apps/TagMe` | Smart tagging suggestions | ⬜ Not Started |
| igotplans | `TheGeekNetwork/Apps/igotplans` | Job matching, CV summarisation | ⬜ Not Started |
| MatchMaster | `TheGeekNetwork/Apps/MatchMaster` | TBD | ⬜ Not Started |
| BhenguBV | `TheGeekNetwork/Apps/BhenguBV` | TBD | ⬜ Not Started |

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

#### Critical Infrastructure (all phases)

| System | Purpose |
|--------|---------|
| Mode Manager | Atomic switching, state management, mode stack |
| Conflict Resolver | Priority hierarchy, override rules, merge option |
| Emergency Bypass | Starred contacts always ring, SOS bypasses all modes |
| Customisation Engine | Edit, clone, create, import/export modes |
| State Preservation | Draft/media/app continuity across mode switches |
| Notification Broker | Queue silenced notifications, catch-up summary |
| Transparency Layer | "This mode will..." summary, settings audit |
| Onboarding Flow | First-boot selector, tutorials, contextual discovery |
| Auto-Switch Intelligence | Context detection, learns from overrides, undo |
| App Management | Per-mode show/hide/disable, drawer filtering |
| Managed Modes | Parental controls, enterprise MDM, PIN-lock |
| Offline Resilience | Tier 1 cores always available, graceful degradation |

---

## Key Paths

| Resource | Path |
|----------|------|
| AIDL + Parcelables | `frameworks/base/core/java/za/co/circleos/inference/` |
| Java service | `frameworks/base/services/core/java/com/circleos/server/inference/` |
| JNI bridge | `frameworks/base/services/core/jni/circle_inference_jni.cpp` |
| Rust layer | `frameworks/base/services/core/rust/circle_inference/` |
| Model dirs | `/system/circle/models/` (bundled), `/data/circle/models/` (downloaded) |
| SystemServer | `frameworks/base/services/java/com/android/server/SystemServer.java` |
| Manifest | `frameworks/base/core/res/AndroidManifest.xml` |
| Butler app | `vendor/circle/apps/Butler/` |
| Inference client lib (Android) | `vendor/circle/libs/inference-client/` |
| InferenceBridge app | `vendor/circle/apps/InferenceBridge/` |
| InferenceBridge docs | `vendor/circle/docs/inference-service-integration.md` |
| .NET inference client | `TheGeekNetwork/code/Shared/TheGeekNetwork.Shared.CircleInference/` |
| Personality service | `frameworks/base/services/core/java/com/circleos/server/personality/` |
| PersonalityTile | `vendor/circle/apps/PersonalityTile/` |
| PersonalityEditor | `vendor/circle/apps/PersonalityEditor/` |
| Geek Network apps | `/Users/admin/Code/Dev/TheGeekNetwork/Apps/` |
| Security AIDL + Parcelables | `frameworks/base/core/java/za/co/circleos/security/` |
| File DMZ service | `frameworks/base/services/core/java/com/circleos/server/security/` |
| Traffic Lobby VPN | `vendor/circle/apps/TrafficLobby/` |
| Malware Jail / Quarantine | `frameworks/base/services/core/java/com/circleos/server/security/QuarantineManager.java` |
| Threat feeds DB | `/data/circle/security/feeds/` (runtime, populated by ThreatFeedUpdater) |
| CDR output | `/data/circle/security/cdr/` (runtime, session-scoped, auto-deleted) |
| Quarantine store | `/data/circle/security/quarantine/` (runtime, system-only access) |
| Compression AIDL + Parcelables | `frameworks/base/core/java/za/co/circleos/compression/` |
| Compression service | `frameworks/base/services/core/java/com/circleos/server/compression/` |
| Compression stats | `/data/circle/compression/stats.json` (monthly, auto-reset) |
| Compression sessions | `/data/circle/compression/sessions/` (runtime, auto-deleted after release) |
| CircleTheme overlay | `vendor/circle/overlay/CircleTheme/` |
| Design system docs | `vendor/circle/docs/design-system-accessibility-audit.md` |
| Prebuilt fonts | `vendor/circle/prebuilt/fonts/` (TTFs needed — see README) |
| .NET design tokens | `TheGeekNetwork/code/Shared/TheGeekNetwork.Shared.CircleDesign/` |

---

## 4. Circle OS Design System ✅ Complete

**Version:** 1.0 | **Owner:** The Geek (Pty) Ltd | **Base:** The Geek Network Design System v2.1
**Commits:** vendor/circle `79ab409` (50 files) · `05748f5` (font + A-01 fix) · TheGeekNetwork `f99ce93` (6 files)

### Implementation Status

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

### Colour Reference

| Token | Hex | Usage |
|-------|-----|-------|
| Primary Black | `#0A0A0A` | Text, dark backgrounds |
| Primary White | `#FFFFFF` | Text (dark), light backgrounds |
| Accent Blue | `#2196F3` | Interactive elements, brand |
| Success Green | `#4CAF50` | Confirmations |
| Warning Amber | `#FF9800` | Warnings |
| Error Red | `#F44336` | Errors, destructive actions |

**Mode accents:** Daily `#2196F3` · Work `#607D8B` · Secure `#B71C1C` · Sport `#FF5722` · Party `#E91E63` · Night `#5D4037` · Student `#009688` · Creator `#9C27B0`

**Dark mode is the default** (OLED battery savings).

### Theme File Paths

```
vendor/circle/overlay/CircleTheme/res/
├── values/
│   ├── colors.xml                 # Core palette + elevation surfaces
│   ├── colors_mode_*.xml          # 8 mode accent overrides (+ pressed/ripple/focus)
│   ├── dimens.xml                 # Spacing 2dp–48dp, touch targets, icon sizes, radii
│   ├── type.xml                   # Type scale Display Large 57sp → Label Small 11sp
│   ├── themes.xml                 # Base dark (default) + light + 17 mode-specific themes
│   ├── themes_mode_elder.xml      # Elder overrides (font scale, touch targets)
│   ├── themes_mode_night.xml      # Night overrides (warm accent, dim overlay)
│   ├── themes_mode_secure.xml     # Secure overrides (dark red, hidden notif content)
│   ├── styles.xml                 # Component styles (buttons, cards, QS tiles, notifs)
│   └── motion.xml                 # Duration scale constants (0–400ms)
├── font/
│   └── comfortaa.xml              # Font family (TTFs in prebuilt/fonts/ — see README)
├── drawable/
│   ├── ic_mode_*.xml              # 15 mode icons (outlined, 24dp, accent stroke)
│   └── bg_*.xml                   # 9 component drawables (buttons, cards, QS tiles)
└── anim/
    ├── mode_transition.xml        # Full 300ms crossfade set
    ├── mode_transition_fade_out.xml
    └── mode_transition_fade_in.xml
```

### .NET Design Token Library

`TheGeekNetwork/code/Shared/TheGeekNetwork.Shared.CircleDesign/` — added to `TheGeekNetwork.sln` Shared folder.

| Class | Contents |
|-------|----------|
| `CircleColors` | All colour constants (Color objects) matching `colors.xml` |
| `CircleSpacing` | Spacing scale, touch targets, icon sizes, radii, button/card dims |
| `CircleTypography` | Type scale sizes, font family constants, font scale multipliers, `Scale()` helper |
| `CircleModeTheme` | `AccentFor(modeId)`, `Pressed()`, `Ripple()`, `HasDimOverlay()`, `IsSecureMode()`, `IsElderMode()`, `BundleFor()` → `CircleModeThemeBundle` |

### All items resolved — commit `05748f5`

- [x] Comfortaa variable font downloaded (Google Fonts, OFL) — `prebuilt/fonts/comfortaa_variable.ttf` + weight-named copies; `res/font/comfortaa_variable.ttf` in overlay; `comfortaa.xml` updated to use `fontVariationSettings` (API 26+)
- [x] Accessibility A-01 fixed — `circle_text_secondary_dark` `#9E9E9E` → `#B8B8B8` (4.56:1 on card surface, 9.9:1 on background — WCAG AA ✅)

---

## 5. Circle OS Security Architecture ✅ Phases 1–3 Complete

**Version:** 1.0 DRAFT | **Owner:** The Geek (Pty) Ltd | **Classification:** Internal
**Philosophy:** Defense in depth — If it's man-made, we can beat it. Pegasus is useless if it can't phone home.

### Threat Model
Nation-state adversaries (Pegasus, Predator), zero-click exploits, supply chain compromise, physical access, network-level attacks.

### Security Stack — 5 Layers

| Layer | Name | Purpose |
|-------|------|---------|
| 1 | **File DMZ** | Intercept all incoming files — sandbox analysis, CDR sanitization, user approval gate |
| 2 | **Traffic Lobby** | Monitor all network connections — block/hold suspicious traffic, detect C2 beaconing |
| 3 | **Malware Jail** | Contain detected threats — observe behavior, extract intelligence |
| 4 | **Community Defense** | Opt-in threat sharing — collective immunity, privacy-preserving |
| 5 | **Data Acuity** | Aggregate intelligence — map threat infrastructure, protect ecosystem |

### Implementation Phases

#### Phase 1: Core Security ✅ Complete

**Commits:** frameworks/base `71ed576a` (12 files, 735 insertions) · vendor/circle `81faa3e` (12 files, 630 insertions)

| Task | Description | Status |
|------|-------------|--------|
| #55 | File DMZ service — `CircleFileDmzService` (`circle.file_dmz`), SHA-256 intake, feed hash check, CDR orchestration, session management, quarantine | ✅ Done |
| #56 | CDR for images and PDFs — `CdrProcessor`: image re-encode via Android Bitmap API (strips all metadata/exploits); PDF passthrough (structural CDR in Phase 2) | ✅ Done |
| #57 | Traffic Lobby VPN app — local VPN TUN `10.0.0.1/24`, `TrafficAnalyzer`, PARANOID/BALANCED/RELAXED modes, DGA entropy detection (Shannon >3.5), beaconing | ✅ Done |
| #58 | Threat feed integration — `ThreatFeedDatabase` (in-memory IP/domain/hash blocklists, flat file backed), `ThreatFeedUpdater` (24h stale-check, force-reload) | ✅ Done |
| #59 | Spyware behavior detection — `SpywareBehaviorDetector`: mic/camera/location sensor flags + suspicious upload correlation → `Listener.onSpywareDetected()` | ✅ Done |

#### Phase 2: Advanced Protection ✅ Complete

**Commit:** frameworks/base `6783d222` (11 files, 1,198 insertions)

| Task | Description | Status |
|------|-------------|--------|
| #60 | Full CDR — `CdrProcessor` extended: Office ZIP repack (strip VBA bin, sanitize macro refs), HTML (strip script/iframe/object/on*/javascript:), ZIP (recursive depth-3, drop executables), media passthrough | ✅ Done |
| #61 | Behavioral analysis sandbox — `BehavioralSandbox`: static analysis (PE/ELF magic, VBA macros, PowerShell, Base64 >200 chars, URL/IP extraction); scans up to 5 MB | ✅ Done |
| #62 | Malware Jail — `QuarantineManager` (`circle.quarantine`): encrypted dir `/data/circle/security/quarantine/<id>/`, files renamed `.quarantine`, flat-JSON index | ✅ Done |
| #63 | Community Defense opt-in — `CommunityDefenseService` (`circle.community_defense`): anonymized IOC sharing (hash/domain/IP only; never content/identity/location/filename/path/app); 6h batched ±30min jitter; max queue 1000 | ✅ Done |
| #64 | Data Acuity integration — `DataAcuityClient`: atomic feed download (`c2_ips.txt`, `c2_domains.txt`, `malware_hashes.txt`), Ed25519 verification placeholder, IOC batch POST to `/v1/community/iocs` | ✅ Done |

#### Phase 3: Intelligence ✅ Complete

**Commit:** frameworks/base `5f853a3c` (13 files, 1,135 insertions)

| Task | Description | Status |
|------|-------------|--------|
| #65 | Automated IOC extraction — `IocExtractor`: structured `ThreatIndicator` objects from DMZ results + quarantine records; STIX 2.1 `toStixIndicator()` per IOC; patterns: IPv4, domain, SHA-256, beacon | ✅ Done |
| #66 | Attack campaign correlation — `CampaignCorrelator`: clusters IOCs via /24 subnet, beacon interval ±5%, 72h temporal window, shared-IOC merge; MITRE ATT&CK TTP mapping (T1071, T1568, T1027, T1102) | ✅ Done |
| #67 | Threat infrastructure mapping — `InfrastructureMapper`: "Zombie Map" graph (subnet→IPs, NS→domains, co-campaign edges); predicts unconfirmed infra when ≥3 IPs in /24 or shared nameserver | ✅ Done |
| #68 | Data Acuity researcher API — `ResearcherApiService` (`circle.researcher_api`): `IDataAcuityResearcherApi` binder (campaign listing, IOC polling, infrastructure queries, STIX 2.1 bundle generation); wired into DMZ + QuarantineManager | ✅ Done |

### Key Defense Points

| Attack | Defense | Result |
|--------|---------|--------|
| FORCEDENTRY / JBIG2 (Pegasus) | CDR strips JBIG2 entirely from PDF | ✅ Payload eliminated |
| Zero-click via message parser | File DMZ + Quiet Mode — no auto-parsing | ✅ Parser never runs |
| C2 phone-home | Traffic Lobby detects beaconing | ✅ Detected + blocked |
| Data exfiltration | Traffic Lobby flags large uploads | ✅ Detected |
| Baseband attack | Below OS level | ⚠️ Cannot defend |

### Additional Hardening (non-phased)

- Quiet Mode messaging — hold encrypted blob, parse only on user action
- Remove legacy formats — no JBIG2, old TIFF codecs, legacy fonts
- Memory-safe parsers (Rust where possible)
- Auto-reboot after 18h idle (clears memory-only malware)
- Network permission required for ANY network access
- Scoped contacts (3, not whole address book)

---

## 6. Circle OS Compression ✅ Phase 1 Complete

**Version:** 1.0 DRAFT | **Owner:** The Geek (Pty) Ltd | **Classification:** Internal
**Commit:** frameworks/base `c910f488` (17 files, 1,629 insertions)

Intelligent on-device compression integrated directly into the DMZ pipeline. Every inbound file is automatically optimized after CDR. All processing is on-device — no cloud proxies.

**Pipeline (inbound):** scan → CDR → **compress** → clean+small file released to app
**Pipeline (outbound):** compress → scan → send *(Traffic Lobby hook — Phase 2)*

### Quality Tiers

| Tier | Name | Use Case | JPEG | WebP |
|------|------|----------|------|------|
| 1 | Lossless | Documents, code, professional | 95 | 95 |
| 2 | Visually Lossless *(default)* | Photos, casual sharing | 85 | 82 |
| 3 | Aggressive | Low-data / mesh emergency | 65 | 60 |

### Compression Engines

| Class | What it handles | Typical savings |
|-------|----------------|-----------------|
| `ImageCompressor` | JPEG/WebP quality re-encode; PNG lossless (Bitmap); GIF passthrough; EXIF fully stripped (GPS, device, author, timestamps) | 40–70% |
| `DocumentCompressor` | PDF XMP metadata strip; Office ZIP (DOCX/XLSX/PPTX/OD*) repack at DEFLATE-9; core.xml author/revision zeroed | 20–60% |
| `ArchiveCompressor` | ZIP repack at DEFLATE-9; drops `__MACOSX`, `.DS_Store`, `Thumbs.db`, OS extra fields; already-compressed entries stored as-is | 20–40% |
| `MetadataStripper` | JPEG/WebP ExifInterface strip; PNG tEXt/iTXt/zTXt/eXIf chunk removal; PDF inline Author/Creator/Producer/XMP strip | N/A — privacy |
| `CompressionStatsTracker` | Monthly inbound/outbound bytes saved, persisted to `/data/circle/compression/stats.json`, auto-resets on month rollover | N/A — dashboard |

### Future Phases

| Phase | Features |
|-------|----------|
| Phase 2 | ZSTD native backend; video transcoding (AV1/HEVC); audio (Opus voice / AAC music); Traffic Lobby outbound hook |
| Phase 3 | Inference Service AI decisions — face/text preservation, semantic compression, smart cropping |
| Phase 4 | Mesh deduplication, delta sync, progressive loading |

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
- BitNet.cpp added in Phase 3; `llama_native`/`bitnet_native` feature flags gate real FFI
- `libcircle_inference.so` is the shared library loaded by `LlamaCppBackend.java`
- Geek Network apps are mobile apps in a separate repo; CircleOS inference integration is a separate future task per app
- InferenceBridge is a platform-signed privileged app (`platform` cert); token lives in memory only — never persisted
- `.NET` client uses `Platforms/Android/` vs `Platforms/Default/` conditional compilation for token acquisition
- Inference ↔ Personality integration complete: `GET /api/personality/mode` returns active mode; `.NET` `GetPersonalityModeAsync()` wraps it
- Mode-aware system prompt pattern: read `mode.Id`, switch on `"work" | "trader" | "developer" | "secure" | ...`
- Design System is a `runtime_resource_overlay` (platform cert) targeting the `android` package — no code, resources only
- Comfortaa variable font (OFL) bundled — `prebuilt/fonts/comfortaa_variable.ttf`, uses `fontVariationSettings` for 400/500/700 weights (API 26+)
- `.NET` design tokens: `CircleModeTheme.BundleFor(mode.Id)` returns accent + pressed/ripple colours + Elder/Secure/Night flags in one call
- Accessibility audit doc at `docs/design-system-accessibility-audit.md` — all issues resolved; A-01 fixed (`#B8B8B8` secondary text, 4.56:1 on card surface)
- Security Phase 1: `CircleFileDmzService` (`circle.file_dmz`); permissions `ACCESS_FILE_DMZ` (normal) + `MANAGE_TRAFFIC_LOBBY` (signature)
- Security Phase 2: `QuarantineManager` (`circle.quarantine`) + `CommunityDefenseService` (`circle.community_defense`); permissions `ACCESS_QUARANTINE` (normal) + `MANAGE_QUARANTINE` (signature) + `COMMUNITY_DEFENSE_OPT_IN` (normal)
- Security Phase 3: `ResearcherApiService` (`circle.researcher_api`); permission `RESEARCHER_API` (signature|privileged); STIX 2.1 bundle output via `IocBundle.stixJson`
- Traffic Lobby is a privileged platform-signed app (local VPN only, no external routing); Phase 2 will add TLS DPI once certificate strategy is decided
- Threat feeds at `/data/circle/security/feeds/c2_ips.txt`, `c2_domains.txt`, `malware_hashes.txt`; `DataAcuityClient` fetches from `https://feeds.dataacuity.circleos.co.za`; Ed25519 signature verification is Phase 3 placeholder (always true in Phase 2)
- CDR Phase 1: images fully sanitized (Bitmap re-encode); Phase 2 extended: Office (strip VBA, sanitize macro refs), HTML (strip script/iframe/object/on*/javascript:), ZIP (recursive depth-3, drop executables), media passthrough
- `BehavioralSandbox` is static analysis (PE/ELF magic, VBA, PowerShell, Base64>200, URL/IP), not a micro-VM — full VM execution deferred to a future phase
- `CampaignCorrelator` uses /24 subnet match, beacon interval ±5% tolerance, 72h temporal window; MITRE ATT&CK TTP IDs mapped per IOC type (T1071/T1568/T1027/T1102)
- `InfrastructureMapper` predicts entire /24 subnet when ≥3 confirmed IPs observed (SUBNET_PREDICTION_THRESHOLD=3); nameserver clustering links related domains
- Compression service (`circle.compression`) integrated as Stage 4 of the DMZ inbound pipeline; compresses at TIER_VISUALLY_LOSSLESS by default; savings reported in `result.findings`
- Compression skip threshold: if compressed ≥ 95% of original, file returned unchanged (STATUS_SKIPPED)
- `MetadataStripper` strips EXIF GPS/device/author/timestamps (ExifInterface), PNG text chunks (tEXt/iTXt/zTXt/eXIf), PDF XMP + inline metadata; outbound only by default
- Compression Phase 2 planned: ZSTD native (libzstd JNI), video AV1/HEVC, audio Opus/AAC, Traffic Lobby outbound hook
- Compression Phase 3 planned: Inference Service AI quality decisions (face/text region preservation, semantic compression)
