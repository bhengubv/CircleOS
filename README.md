# Circle OS Specification

> **"You're NOT the product. Trust!"**

Complete specification for Circle OS — a privacy-first, age-adaptive mobile operating system designed to run on existing devices (dual boot with Android) and Circle native hardware.

**v2.0 adds:** Mesh networking, Traffic Lobby firewall, Malware Jail, Community Defense telemetry, Data Acuity threat intelligence platform, and complete brand/design system.

---

## Quick Start

**For Claude Code / AI Development:**
- Start with `CLAUDE.md` — the shorthand brain (~500 lines)
- Pull specific chapters as needed from `/chapters/`

**For Human Reading:**
- Start with `chapters/01_vision.txt` for philosophy
- Read `chapters/02_non_goals.txt` for boundaries
- Dive into specific topics as needed

---

## Document Structure

```
CircleOS/
├── CLAUDE.md, MASTER_PLAN.md, Claude_Session_State.md   Planning docs
├── README.md, CONTRIBUTING.md                            Repo overview
├── .devcontainer/    Reproducible AOSP build container (Clang, Rust, NDK, SDK)
├── manifests/        circle.xml — repo overlay manifest pulling every
│                     CircleOS_* GitHub repo into its AOSP tree path
├── scripts/          setup.sh, sync.sh, build.sh — GSI baseline pipeline
├── huawei/p30-lite/  Hard-mode reference: boot-selector ramdisk +
│                     device audit + injection notes
├── fixtures/         Static binaries for offline validation
├── docs/             Architecture notes — including REPO_MANIFEST.md,
│                     INSTALL_PATHS.md, CIRCLEOS_NEXT_TOOLSET.md
├── aether-protocol/  Submodule — universal mesh network layer (OSS)
├── amarula/          (legacy) OpenHarmony v1 — superseded
├── sites/            Static site assets (public website)
└── chapters/         23 spec chapters
    ├── 01_vision.txt              Philosophy & principles
    ├── 02_non_goals.txt           What we refuse to do
    ├── 03_security.txt            GrapheneOS-level security model
    ├── 04_privacy.txt             Permission model & dashboard
    ├── 05_hardware.txt            Target devices & specs
    ├── 06_boot.txt                Dual boot architecture
    ├── 07_system.txt              System architecture
    ├── 08_android_compat.txt      Android app compatibility
    ├── 09_data_continuity.txt     Data migration & sharing
    ├── 10_updates_recovery.txt    OTA & recovery
    ├── 11_onboarding.txt          Setup wizard & first boot
    ├── 12_age_modes.txt           Standard, Kid, Elder modes
    ├── 13_accessibility.txt       Full accessibility support
    ├── 14_offline_lowres.txt      Offline & low-resource
    ├── 15_circle_store.txt        App ecosystem
    ├── 16_developer_guide.txt     Building & contributing
    ├── 17_device_porting.txt      Community device ports
    ├── 18_mesh_networking.txt     P2P mesh communication
    ├── 19_firewall_lobby.txt      Firewall & traffic quarantine
    ├── 20_malware_jail.txt        Malware containment & intel
    ├── 21_threat_telemetry.txt    Community defense system
    ├── 22_data_acuity_platform.txt Backend threat intel
    └── 23_brand_design_system.txt  Brand & UI design
```

---

## Core Concepts

### Privacy is Sovereignty, Not Isolation
We protect individual privacy so people can CHOOSE to participate in community.
Circle OS never prevents sharing — it ensures sharing is intentional.

### Coexist, Don't Conquer
Dual boot alongside Android. User's existing data accessible. Can always go back.

### Apps Welcome, Snooping Isn't
Android apps run natively via ART. But every app runs under Circle's privacy rules:
- Network access requires explicit permission
- Storage and contacts are scoped
- All access is logged and visible

### Security Tiers — Be Honest
| Tier | Hardware | Level |
|------|----------|-------|
| 1 | Circle native, Pixel | Full verified boot, attestation |
| 2 | Treble devices | Software hardening, no hardware trust |
| 3 | P30 Lite (exploit boot) | Best effort, documented limitations |

### Ages 8 to 80
Three modes: Standard (full features), Kid (parental controls), Elder (simplified UI).
Full accessibility. If it's not accessible, it's not done.

---

## Reference Devices

**Primary Reference (Hard Mode):** Huawei P30 Lite
- If it works here, it works anywhere
- 4GB RAM tests low-resource optimization
- Locked bootloader tests coexistence approach

**Target Reference (Optimal):** Circle Native Hardware
- RISC-V processor, NearLink connectivity
- Modular design, secure element
- Full Tier 1 security

---

## Key Differentiators from Stock Android

1. **Network Permission Required** — Apps can't phone home without asking
2. **Scoped Contacts** — Share 3 contacts, not 300
3. **Scoped Storage** — Apps see only files you share
4. **Privacy Dashboard** — See everything every app does
5. **No Google by Default** — Optional, sandboxed if installed
6. **Honest Security** — We tell you your actual security level
7. **Mesh Networking** — Phone-to-phone communication without internet
8. **Traffic Lobby** — Suspicious connections quarantined for review
9. **Malware Jail** — Contain threats, gather intelligence, protect community
10. **Community Defense** — Opt-in threat sharing protects everyone

---

## Ecosystem

```
CIRCLE OS          →  Mobile operating system (privacy-first)
DATA ACUITY        →  Threat intelligence platform (backend)
THE GEEK NETWORK   →  Parent ecosystem
├── SDPKT          →  Payments, relay rewards
├── SleptOn        →  App distribution
└── Bruh!          →  Consumer super app
```

**Business Model:**
- Circle OS is free and open source (GPL v3)
- Opt-in threat telemetry feeds Data Acuity
- Data Acuity monetizes threat intelligence (API subscriptions)
- Revenue funds Circle OS development
- Users are protected, not products

---

## Development Approach

```
Slow is smooth.
Smooth is fast.
```

- Every feature specified before coded
- Security and privacy never compromised for schedule
- Accessibility required, not optional
- If we can't do it right, we don't ship it

---

## Getting Started (Development)

There are two valid build paths from this repo:

### 1. Circle OS proper (the system image)

Pulls every `CircleOS_*` GitHub repo (`vendor/circle`, `frameworks/base`
fork, `build/circle`, the three device trees, `CircleSettings`,
`CircleLauncher`) into a synced AOSP 15 tree via the repo manifest at
[`manifests/circle.xml`](manifests/circle.xml) and produces
`out/target/product/circle_arm64/system.img`.

Full instructions: [`docs/REPO_MANIFEST.md`](docs/REPO_MANIFEST.md).

```bash
# Path A — fresh tree (~250 GB free, 16+ GB RAM)
mkdir ~/circle-tree && cd ~/circle-tree
repo init -u https://android.googlesource.com/platform/manifest -b android-15.0.0_r20 \
          --partial-clone --clone-filter=blob:limit=10M
mkdir -p .repo/local_manifests
curl -o .repo/local_manifests/circle.xml \
     https://raw.githubusercontent.com/bhengubv/CircleOS/main/manifests/circle.xml
repo sync -c -j"$(nproc)" --fail-fast --no-clone-bundle
source build/envsetup.sh
lunch circle_arm64-userdebug
m -j"$(nproc)" systemimage
```

### 2. Stock-AOSP GSI baseline (sanity check / DSU fall-back)

A vanilla AOSP 15 GSI that ignores `vendor/circle` entirely — useful as
a known-good baseline when you want to confirm the build host itself is
healthy before pointing at the Circle overlays. Three-step pipeline:

```bash
sudo ./scripts/setup.sh    # AOSP build deps (~5 min)
./scripts/sync.sh          # repo init + sync upstream AOSP only
./scripts/build.sh         # Build → out/target/product/generic_arm64/system.img
```

Output is a Treble-compliant GSI installable via Settings → Developer
options → DSU Loader → Local image. If anything goes wrong, the next
normal reboot returns to stock Android — no risk, brick-proof.

See [`docs/INSTALL_PATHS.md`](docs/INSTALL_PATHS.md) for the dual-path
user-install architecture: DSU as the default user install, P30 Lite +
PotatoNV + partition hijack ([`huawei/p30-lite/`](huawei/p30-lite/)) as
the hard-mode reference target.

---

## Contact

- **Foundation:** info@circlefoundation.org
- **Engineering:** engineering@circlefoundation.org
- **Partnerships:** partnerships@circlefoundation.org

---

## License

- **Circle OS:** GPL v3 (copyleft — modifications must be shared)
- **Data Acuity:** AGPL v3 (server-side copyleft)
- **Kernel:** GPL v2 (Linux requirement)
- **Hardware (Circle native):** CERN OHL v2
- **Documentation:** CC BY-SA 4.0

---

*Circle OS Specification v2.0 — January 2026*
*Circle Foundation (OS) · The Geek (Pty) Ltd (Data Acuity)*
