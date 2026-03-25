# CircleOS Next — Complete OS Toolset

## Context

Every OS needs tools. CircleOS Next (OpenHarmony-based, Africa-first) needs system utilities, productivity apps, and developer tools. The Geek Network already covers most user-facing apps (17 web apps + 36 APIs). The gaps are system-level utilities and developer tooling.

Key constraint: support existing IDEs (VSCode, JetBrains Community) — don't force developers into a proprietary IDE.

---

## What's Already Covered by Geek Network Apps

These ship as Blazor WebView apps on day one (no rewrite needed):

| OS Need | Geek Network App | API Backend |
|---|---|---|
| Messaging | TxTMe | MessagingAPI (5142) |
| Social feed | Bruh | Multiple APIs |
| App store + Music | SleptOn | SleptOnAPI (5147) |
| Wallet / Payments | SDPKT | SdpktAPI (5146), LedgerAPI (5141) |
| Shopping | KiffStore | KiffStoreAPI (5100) |
| Maps / Navigation | TagMe + Maps | MapsAPI (5024), MapsDataAPI (5025) |
| Emergency SOS | Panik | PanikAPI (5027) |
| Jobs | TheJobCenter | TheJobCenterAPI (5149) |
| Travel | Takemehome | TakemehomeAPI (5154) |
| Identity / Notary | TrustSeal | TrustSealAPI (5151) |
| Auctions | BidBaas | BidBaasAPI (5148) |
| Fashion | SortedClothing | SortedClothingAPI (5164) |
| Rankings | TheHotList | TheHotListAPI (5152) |
| Stories | WhatWeWant | WhatWeWantAPI (5155) |
| Personal finance | ShhMoney | ShhMoneyAPI (5168) |
| Airtime / Data | (via GlocellAPI) | GlocellAPI (5145) |
| AI Assistant | Butler | CircleInference (on-device) |
| Notifications | (system-level) | NotificationAPI (5163) |
| Auth / SSO | (system-level) | AuthAPI (5140) |
| Localization | (system-level) | LocalizationAPI (5022) |

**That's 20+ user apps already built.** No other mobile OS launches with this many first-party apps.

---

## What Needs to Be Built (Gaps)

### Tier 1: System Utilities (Must Ship — No OS Works Without These)

| Tool | Status | Build vs Adapt | Notes |
|---|---|---|---|
| **Launcher / Home Screen** | Build new | ArkTS native | OpenHarmony has reference launcher — fork and theme with Circle design system |
| **Dialer / Phone** | Build new | ArkTS native | Standard telephony, integrate with TxTMe contacts |
| **Contacts** | Build new | ArkTS native | Unified contact store synced across TxTMe, SDPKT, Panik |
| **Camera** | Adapt | Fork OpenHarmony camera | Add Circle compression (already built), privacy watermark |
| **Gallery / Photos** | Adapt | Fork OpenHarmony gallery | Add offline AI (Butler) for photo search, MediaAPI upload |
| **File Manager** | Adapt | Fork OpenHarmony files | Add mesh sharing (Aether), encrypted vault |
| **Browser** | Adapt | Chromium WebView or Firefox | Privacy-hardened, Traffic Lobby integration |
| **Calculator** | Adapt | Fork OpenHarmony calc | Minimal effort |
| **Clock / Alarm** | Adapt | Fork OpenHarmony clock | Add load shedding awareness |
| **Calendar** | Build new | ArkTS native | Offline-first, sync via mesh, load shedding schedule overlay |
| **Settings** | Exists | CircleSettings | Already built — privacy, modes, OTA |
| **Keyboard / IME** | Adapt | Fork OpenBoard | Add Zulu, Xhosa, Sotho, Swahili, Yoruba, Amharic predictions |
| **SystemUI** | Build new | ArkTS native | Status bar, notification shade, quick settings |
| **Screen Lock** | Build new | ArkTS native | PIN/pattern/biometric, personality mode badge |
| **Downloads Manager** | Build new | ArkTS native | Integrate with mesh for P2P downloads |

### Tier 2: Africa-Specific (Critical for Target Market)

| Tool | Status | Notes |
|---|---|---|
| **USSD Dialer** | Build new | Menu-based *123# interface. 40% of Sub-Saharan Africa uses USSD for mobile money. Works without data. Critical during load shedding. |
| **Airtime Manager** | Build new | Carrier integration (Vodacom, MTN, Cell C, Telkom). Balance tracking, auto-recharge. Backed by GlocellAPI. |
| **Load Shedding Schedule** | Build new | Location-aware (municipal ward), push notifications for upcoming blackouts. SA, Nigeria, Kenya support. |
| **Mobile Money Bridge** | Build new | USSD-based M-Pesa, MoMo, Airtel Money integration. Bridges SDPKT wallet to existing mobile money networks. |
| **Offline Maps Pack Manager** | Adapt | Download SA/regional map tiles from .106 maps platform for offline use. Already have south-africa.pmtiles (446MB). |

### Tier 3: Productivity (Expected by Users)

| Tool | Status | Build vs Adapt |
|---|---|---|
| **Notes** | Build new | Simple ArkTS app, encrypted local storage, mesh sync |
| **Email Client** | Adapt | Fork K-9 Mail (FOSS) or build minimal IMAP/SMTP client |
| **PDF Viewer** | Adapt | Fork MuPDF (FOSS, C library, tiny) |
| **Office Viewer** | Adapt | Embed LibreOffice Viewer or OnlyOffice (FOSS) |
| **QR Scanner** | Build new | Camera + ZXing library, integrate with SDPKT payments |
| **Voice Recorder** | Build new | Simple ArkTS app, Circle compression for audio |
| **Screen Recorder** | Build new | System-level capture, privacy-aware (blur notifications) |
| **Weather** | Adapt | Open-Meteo API (free, no key), offline cache |
| **Flashlight** | Trivial | 10 lines of code |
| **Compass** | Trivial | Sensor API, 50 lines |
| **Health / Fitness** | Build new | Step counter, heart rate (if hardware), sync with mesh |

---

## Developer Tools

### Philosophy
- **Don't force a proprietary IDE** — support VSCode, JetBrains Community, terminal workflows
- **DevEco Studio available** but not required (it's IntelliJ-based, familiar to JetBrains users)
- **CLI-first** — everything achievable from command line
- **Web docs** — no app needed to read documentation

### SDK Components

| Component | What | Notes |
|---|---|---|
| **circle-sdk** | Core SDK package | ArkTS types, APIs, components, Circle design tokens |
| **circle-cli** | Command-line tools | Project scaffolding, build, test, deploy, emulate |
| **circle-emulator** | Device emulator | QEMU-based, multiple device profiles ($30 phone → flagship) |
| **circle-debugger** | Debugging | HDC (OpenHarmony Device Connector) + Chrome DevTools for ArkUI |
| **circle-profiler** | Performance | CPU, memory, network, battery profiling |
| **circle-linter** | Code quality | ArkTS linting rules, privacy API usage warnings |

### IDE Support

| IDE | Support Level | How |
|---|---|---|
| **VSCode** | First-class | Official extension: ArkTS language server (based on Volar), project templates, build/run/debug, emulator launch, Circle design system snippets |
| **JetBrains (IntelliJ/WebStorm)** | First-class | Plugin: ArkTS support (TypeScript-based so WebStorm works natively), project integration, run configs |
| **DevEco Studio** | Full (Huawei's IDE) | Works out of box — it IS IntelliJ with OpenHarmony plugins |
| **Vim/Neovim** | CLI | circle-cli + LSP for ArkTS (tsserver with ArkTS declarations) |
| **Terminal** | Full | circle-cli handles everything: `circle create`, `circle build`, `circle run`, `circle test` |

### circle-cli Design

```
circle create my-app              # Scaffold new app (ArkTS + ArkUI)
circle create my-app --template wallet    # Use template (wallet, social, commerce, etc.)
circle build                       # Build .hap bundle
circle run                         # Deploy to emulator or connected device
circle run --device                # Deploy to physical device via USB
circle test                        # Run unit + UI tests
circle lint                        # Check code quality + privacy compliance
circle publish                     # Package for Circle Store (SleptOn)
circle emulate                     # Launch emulator
circle emulate --profile low-cost  # Emulate $30 phone (512MB RAM, small screen)
circle emulate --profile mid-range # Emulate mid-range (4GB RAM)
circle mesh-sim                    # Simulate mesh network with multiple emulator instances
circle docs                        # Open documentation in browser
```

### Templates (circle create --template)

| Template | What it scaffolds |
|---|---|
| `blank` | Minimal ArkTS app |
| `wallet` | SDPKT-integrated payment app |
| `social` | Feed + profiles + messaging (Bruh-style) |
| `commerce` | Product listing + cart + checkout (KiffStore-style) |
| `maps` | Location-aware app with offline maps |
| `mesh` | Aether mesh-enabled app (P2P messaging/sharing) |
| `ai` | Butler inference-integrated app |
| `iot` | IoT device controller (mini/small system) |

### Documentation

| Resource | Format | Location |
|---|---|---|
| Getting Started | Web + offline | docs.circleos.org |
| API Reference | Web + offline | Generated from SDK types |
| Design Guidelines | Web | Circle Design System spec |
| Sample Apps | Git repo | 8+ templates with full source |
| Video Tutorials | Web | YouTube/PeerTube (data-frugal versions) |
| Offline Docs App | System app | Ships with OS for developers |

---

## Implementation Priority

### Wave 1 — Launch Day (ship with OS)
```
System: Launcher, Dialer, Contacts, Camera, Gallery, File Manager,
        Browser, Calculator, Clock, Settings, SystemUI, Screen Lock,
        Keyboard (with African languages), Downloads Manager

Africa: USSD Dialer, Airtime Manager, Load Shedding Schedule

Geek Network (WebView): TxTMe, SDPKT, Bruh, SleptOn, KiffStore,
                         TagMe, Panik, TheJobCenter, ShhMoney

Built-in: Butler AI, CircleMessages (mesh), CircleSettings,
          Aether mesh networking
```

### Wave 2 — Week 2-4 (OTA update)
```
Productivity: Notes, Email, PDF Viewer, QR Scanner, Voice Recorder,
              Calendar (with load shedding), Weather

Africa: Mobile Money Bridge, Offline Maps Pack Manager

Developer: circle-cli v1, VSCode extension, Getting Started docs
```

### Wave 3 — Month 2-3 (ecosystem)
```
Productivity: Office Viewer, Screen Recorder, Health/Fitness

Developer: circle-sdk full release, emulator profiles,
           mesh-sim, 8 templates, API reference, sample apps

Geek Network native rewrites: Start converting top 3 WebView apps
to native ArkTS (SDPKT, TxTMe, Bruh)
```

---

## Open Source Strategy

| Component | License | Why |
|---|---|---|
| CircleOS core | Apache 2.0 (OpenHarmony) | Maximum adoption, no copyleft friction |
| Circle apps (system) | Apache 2.0 | Encourage community ports |
| Aether protocol | MIT | Already open, 8 language implementations |
| circle-cli | MIT | Developer adoption |
| circle-sdk | Apache 2.0 | Match OS license |
| Data Acuity (threat intel) | AGPL v3 | Server-side, protects community data |
| Geek Network apps | Proprietary | Revenue stream — free to use, not free to fork |

---

## Verification

- **System utilities**: Boot emulator → every app launches → performs core function
- **Africa tools**: USSD dialer sends test code, airtime manager shows balance, load shedding shows schedule
- **Developer tools**: `circle create test-app && circle build && circle run` works end-to-end in under 5 minutes
- **VSCode**: Install extension → open project → autocomplete works → F5 launches emulator
- **Geek Network WebView**: Each of 10+ apps loads in WebView and can sign in
