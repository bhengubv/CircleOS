# Amarula — Architecture

Starting point, not a cathedral. Iterate as we learn.

## Base
- **OS:** OpenHarmony 6.1 Release (Standard variant initially; Lite variant for $30 phone target later)
- **Target device:** rk3568 emulator first (board: hh_scdayu200). Physical devices follow.
- **Kernel:** Linux 5.10 (OH Standard)
- **UI:** ArkUI (declarative TypeScript-based)
- **App bundles:** `.hap`
- **Multi-device vision:** phone → watch → TV → IoT → vehicle via DSoftBus (all Phase 4+)

## Layout in this folder
```
amarula/
├── README.md                              # what this is
├── ARCHITECTURE.md                        # this file
├── productdefine/
│   └── amarula.json                       # OH product definition (dropped into OH tree at build time)
├── vendor/circle/amarula/
│   └── install_list.json                  # baked-in apps
├── vendor/circle/services/                # Circle system services (mesh, firewall, threat intel, inference) — TO BE PORTED
├── apps/                                  # ArkTS app sources (launcher, butler, messages, ...) — TO BE WRITTEN
└── build/                                 # build scripts — TO BE WRITTEN
```

## Reference specs (already written, not repeating)
- Vision / non-goals / privacy / mesh / firewall / malware jail / threat intel / brand → `../chapters/`
- Full OS toolset + app strategy → `../docs/CIRCLEOS_NEXT_TOOLSET.md`
- Philosophy / mission → `../CLAUDE.md`

## Source of truth
For anything covered in those docs — follow them. Don't duplicate. When something changes, update the original spec, not here.

## What lives here and nowhere else
- OH product definition (`productdefine/amarula.json`)
- Baked-in app list (`install_list.json`)
- Circle-specific components (to port from AOSP sources as reference)
- Build orchestration that integrates Circle pieces into OH source tree
- Amarula-release-specific release notes

## Build strategy (short)
1. **One-time**: WSL2 Ubuntu + OH toolchain + `repo sync` OH Standard (~45GB, overnight)
2. **Overlay**: drop `amarula/productdefine/amarula.json` into OH tree at `productdefine/common/products/`; overlay `amarula/vendor/circle/` onto OH `vendor/circle/`
3. **Build once**: `./build.sh --product-name amarula --ccache --no-prebuilt-sdk` — first build 4–8h
4. **Iterate**: `hb build <component>` rebuilds single Circle components in minutes

Details in `build/` scripts (to write).

## What's deliberately NOT here (yet)
- Service source code (porting from old `/frameworks/base/services/core/java/com/circleos/server/` AOSP Java → OH-native C++/ArkTS)
- App source code
- Android compat layer decision (Oniro vs Jolla) — separate spike
- Physical device ports beyond emulator

## Naming
- Release = **Amarula** (v1). Next releases follow fruits A–Z.
- Public product name stays **CircleOS**.
