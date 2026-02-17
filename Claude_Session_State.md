# CircleOS — Claude Session State

Tracks implementation progress across sessions. Update after each session.

---

## Inference Service Spec Reference

Full spec: pasted by user 2026-02-17. Package: `za.co.circleos.inference`. Service name: `circle.inference`.

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

### 2. LLM/AI Core — Butler ✅ Complete

The Inference Service is the shared system backend. Butler is the primary user-facing app built on top of it. Phases 2–3 complete the engine; Phase 4 wires Butler and the broader Geek Network ecosystem into it.

#### Inference Service (`frameworks/base` + native)

| Phase | Description | Status |
|-------|-------------|--------|
| **Inf Phase 1** | Foundation — AIDL, Parcelables, CircleInferenceService, CapabilityDetector, ModelManager, LlamaCppBackend (JNI stub), SystemServer + Manifest | ✅ Done — commit `52217a0d` |
| | **Inf Phase 2** | Rust abstraction layer — `InferenceBackend` trait, JNI bridge Java→Rust, ResourceGovernor, ModelManager download support | ✅ Done — commit `ca39f5a6` |
| **Inf Phase 3** | BitNet integration — BitNetBackend, backend auto-selection logic, performance benchmarking | ✅ Done — commit `df19a59a` |
| **Inf Phase 4** | Ecosystem — Butler app integration, SDPKT + other Geek Network apps, third-party docs, model store | ✅ Done — frameworks/base `6d9768d3`, vendor/circle `6819446` |

---

### 3. OS Personality Engine ⬜ Not Started

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
| **PE Phase 4** | Lifestyle Modes — Tier 2 modes, download-on-activation flow, mode-specific app bundles | ⬜ Todo |
| **PE Phase 5** | Advanced — managed modes (parental/enterprise), auto-switch learning, Tier 3 specialist modes, community sharing | ⬜ Todo |

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

#### Dependencies

| Component | Required For |
|-----------|-------------|
| Inference Service | AI-assisted modes (all tiers) |
| Butler | Voice mode switching |
| SDPKT | Wallet features in Secure, Trader, Party, Entrepreneur |
| TheJobCenter | Job Candidate mode |
| Mesh Comms | Offline mode P2P |

---

## Phase 2 — Rust Abstraction Layer (Next)

**Goal:** Replace the Java JNI stub in `LlamaCppBackend.java` with a real Rust abstraction layer that bridges the Kotlin service to llama.cpp via FFI.

### Files to Create/Modify

| File | Description |
|------|-------------|
| `services/core/rust/circle_inference/src/lib.rs` | Crate root + JNI exports |
| `services/core/rust/circle_inference/src/backend.rs` | `InferenceBackend` trait definition |
| `services/core/rust/circle_inference/src/llama_backend.rs` | llama.cpp FFI wrapper implementing `InferenceBackend` |
| `services/core/rust/circle_inference/src/resource_governor.rs` | Memory budgeting, thermal response |
| `services/core/rust/circle_inference/src/model_manager.rs` | Bundled + downloaded model discovery, integrity verification |
| `services/core/rust/circle_inference/src/capability_detector.rs` | Runtime device profiling, tier classification |
| `services/core/rust/circle_inference/src/types.rs` | Shared types: ModelConfig, GenerateRequest, Token, StreamControl, etc. |
| `services/core/rust/circle_inference/Android.bp` | Soong build for Rust crate + llama.cpp linkage |
| `services/core/rust/circle_inference/Cargo.toml` | Rust crate manifest |
| `services/core/jni/circle_inference_jni.cpp` | Update: forward calls to Rust instead of stubs |
| `services/core/java/com/circleos/server/inference/LlamaCppBackend.java` | Update: align native method signatures with Rust JNI exports |

### Key Rust Types (from spec)

```rust
pub trait InferenceBackend: Send + Sync {
    fn load_model(&self, config: ModelConfig) -> Result<ModelHandle>;
    fn unload_model(&mut self, handle: ModelHandle) -> Result<()>;
    fn generate(&self, handle: ModelHandle, request: GenerateRequest) -> Result<GenerateResponse>;
    fn generate_stream(&self, handle: ModelHandle, request: GenerateRequest,
        callback: Box<dyn Fn(Token) -> StreamControl + Send>) -> Result<()>;
    fn capabilities(&self) -> BackendCapabilities;
    fn resource_usage(&self) -> ResourceMetrics;
}
```

---

## Phase 3 — BitNet Integration

**Goal:** Add BitNet.cpp as a second backend; implement auto-selection logic.

**Blocker:** BitNet.cpp mobile/Android support must be production-ready first. Monitor: https://github.com/microsoft/BitNet

### Files to Create

| File | Description |
|------|-------------|
| `services/core/rust/circle_inference/src/bitnet_backend.rs` | BitNet.cpp FFI wrapper implementing `InferenceBackend` |
| `services/core/rust/circle_inference/src/backend_selector.rs` | Auto-select: BitNet if available + beneficial, else llama.cpp |

---

## Phase 4 — Ecosystem

**Goal:** Wire the inference service into Butler and other Geek Network apps.

| App | AI Use Case |
|-----|-------------|
| Butler | General-purpose assistant, conversational UI |
| SDPKT | Transaction explanations, fraud detection prompts |
| BidBaas | Auto-generate bid descriptions, summarise tenders |
| TagMe | Smart tagging suggestions |
| TheJobCenter | CV summarisation, job matching |
| Bruh! | Unified super-app assistant |

**Note:** Butler integration plan to be detailed in a separate session.

---

## Key Paths

| Resource | Path |
|----------|------|
| AIDL + Parcelables | `frameworks/base/core/java/za/co/circleos/inference/` |
| Java service | `frameworks/base/services/core/java/com/circleos/server/inference/` |
| JNI stub (Phase 1) | `frameworks/base/services/core/jni/circle_inference_jni.cpp` |
| Rust layer (Phase 2) | `frameworks/base/services/core/rust/circle_inference/` |
| Model dirs | `/system/circle/models/` (bundled), `/data/circle/models/` (downloaded) |
| SystemServer | `frameworks/base/services/java/com/android/server/SystemServer.java` |
| Manifest | `frameworks/base/core/res/AndroidManifest.xml` |
| Inference branch | `circle-14.0-clean` on `circle` remote |

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

- All Circle services are Java (not Kotlin) — decision made in Inf Phase 1 to match existing 16 services
- Rust layer goes via Soong (platform-level), not NDK — per spec recommendation
- BitNet.cpp added in Phase 3, not Phase 2 — monitoring mobile readiness
- `libcircle_inference.so` is the shared library name loaded by `LlamaCppBackend.java`
