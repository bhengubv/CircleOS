# Where everything lives

A map for someone who has just been handed this repository and does not
know what any of it is. It says where each piece is, what it does, and —
where it matters — what is *not* true despite appearances.

Last verified against a working tree and a booting device on
**2026-09-15**.

---

## The two core repositories

Circle OS has **two** repositories at its centre, not one. They answer
different questions and neither contains the other.

| | [`CircleOS`](https://github.com/bhengubv/CircleOS) | [`aosplite`](https://github.com/bhengubv/aosplite) |
|---|---|---|
| Answers | *What is Circle OS, and why* | *How do you get an image out, and how do you know it is good* |
| Holds | the specification, the chapters, design guides, the repo manifest | the AOSP prune tiers, the build and flash pipeline, the preflight checks |
| Contains buildable OS source? | no | no |
| Read it when | you want to understand the product | you want to build, check or flash one |

**Neither holds the OS source.** That lives in the `CircleOS_*`
repositories listed below, which are assembled into an AOSP tree.

### CircleOS — the specification

The front door. No compilable OS code; it is the product definition and
the reasoning behind it.

| Path | What it is |
|---|---|
| `README.md` | the entry point |
| `MASTER_PLAN.md` | the plan of record |
| `chapters/` | the long-form specification |
| `docs/CircleOS_Skin_Design_Guide.md` | **the design authority for the Metro look** — §1 is the Metro discipline inherited, §2 is what makes it Circle OS rather than Windows Phone |
| `docs/CircleOS_Theme_Skins_Scout.md` | licence-verified list of what can legally be shipped in a skin |
| `docs/CircleOS_WP-Inspired_Backlog.md` | 80 Windows Phone ideas, `WP-01`…`WP-80`, stable IDs to cite in commits |
| `docs/BUILD_AND_FLASH.md` | **how to build and flash Circle OS** — only what differs from a plain GSI; the mechanics live in aosplite's tutorial |
| `docs/REPO_MANIFEST.md` | how to assemble a tree from the `CircleOS_*` repos |
| `manifests/circle.xml` | the repo overlay that does it |
| `amarula/` | a separate OpenHarmony line of work — **not** part of the Android GSI |
| `huawei/p30-lite/` | a hard-mode device path that does not follow the AOSP device-tree pattern |

### aosplite — the base and the pipeline

A maintained debloat of AOSP, plus everything used to build, check and
flash an image. Usable on its own by people who have never heard of
Circle OS, which is why it is a separate repository and not a directory
here.

| Path | What it is |
|---|---|
| `manifests/` | five prune tiers — what is removed from AOSP and why |
| `docs/TUTORIAL.md` | **the end-to-end walk-through** — clone, sync, check, build, flash, confirm the boot, read the log when there is none |
| `tools/build.sh` | the build wrapper; fixes the environment in a file rather than in someone's shell history |
| `tools/check-product.sh` | **build preflight** — four faults that a build reports as success and a device reports as a boot loop |
| `tools/flash-preflight.sh` | **flash preflight** — image and device checks before anything is written |
| `tools/flash.sh` | the flash pipeline; preflight always runs, and a blocking result means nothing is written |
| `tools/rescue-log.sh` | recovering a boot log from a device that did not boot |
| `patches/` | changes to AOSP projects that have no repo of their own to hold them |
| `docs/RATIONALE.md` | what was cut and why |
| `SETUP.md` | building AOSP from nothing |

---

## The OS source

These are the repositories that actually compile into the image. Each is
synced to a fixed path in an AOSP tree by `manifests/circle.xml`.

| Repo | Tree path | State |
|---|---|---|
| [`CircleOS_vendor_circle`](https://github.com/bhengubv/CircleOS_vendor_circle) | `vendor/circle` | active — apps, overlays, permissions, fonts, microG, SELinux |
| [`CircleOS_build`](https://github.com/bhengubv/CircleOS_build) | `build/circle` | active — product configs and lunch targets |
| [`CircleOS_packages_apps_CircleLauncher`](https://github.com/bhengubv/CircleOS_packages_apps_CircleLauncher) | `packages/apps/CircleLauncher` | active — the default home screen |
| [`CircleOS_device_circle_common`](https://github.com/bhengubv/CircleOS_device_circle_common) | `device/circle/common` | present, untouched since 2026-05 |
| [`CircleOS_device_circle_pixel6`](https://github.com/bhengubv/CircleOS_device_circle_pixel6) | `device/circle/pixel6` | present, untouched since 2026-06 |
| [`CircleOS_device_circle_redmi_note12`](https://github.com/bhengubv/CircleOS_device_circle_redmi_note12) | `device/circle/redmi_note12` | present, untouched since 2026-06 |
| [`CircleOS_packages_apps_CircleSettings`](https://github.com/bhengubv/CircleOS_packages_apps_CircleSettings) | `packages/apps/CircleSettings` | **not synced into the working tree** — see below |

### Things that are not what they look like

**`CircleOS_platform_frameworks_base` is not in use.** The README and the
older manifest describe it as a fork of `frameworks/base` carrying Circle
privacy and mesh system services, replacing upstream. The tree that
currently builds and boots uses **upstream AOSP `frameworks/base`**, and
the checked-out `frameworks/base` has no Circle remote and no Circle
commits — its HEAD is an ordinary AOSP cherry-pick merge. Nothing in the
booting image depends on the fork. Do not delete the repo; do not assume
the image contains it.

**There are two launchers, and they are different things.**

- `packages/apps/CircleLauncher` — package `com.circleos.launcher`. The
  brand design: rounded cards, privacy widget. This is the default home
  screen and it `overrides` Launcher3, so no chooser appears at first
  boot.
- `vendor/circle/apps/CircleLauncher` — module `CircleMetroLauncher`,
  package `za.co.circleos.launcher`. The flat Metro tile launcher built
  to the skin guide. Installed alongside; does **not** override
  Launcher3, because only one app may.

**`CircleSettings` exists twice.** The canonical repo is
`CircleOS_packages_apps_CircleSettings`, but the tree that builds uses
`vendor/circle/apps/CircleSettings` instead, and the canonical one is not
synced. Reconciling the two is an open task.

**Some code exists in no repository at all.** The
`com.circleos.server.*` privacy system services, and the `CircleHeyB`
assistant app, exist on the `.201` build machine and are referenced by
code in `vendor/circle`, but are not in any repo here. Recovering them is
an open task. Until then, anything depending on them will not build.

---

## Current state, honestly

**Verified 2026-09-14/15 on a Google Pixel 7a (`lynx`, CP1A.260405.005):**

- Base: **AOSP `android-16.0.0_r4`**, not 15.
- Lunch target: **`circle_arm64-bp4a-userdebug`**. The release config
  matters — `trunk_staging` produces an image that reports itself as a
  pre-release build and does not boot on this device.
- Output: `out/target/product/**generic_arm64**/system.img`. Not
  `circle_arm64` — the product builds `generic_arm64` because
  `PRODUCT_DEVICE := generic_arm64`.
- The image boots: `sys.boot_completed=1`, 335 services, no crash-buffer
  entries.
- `tools/check-product.sh` reports 0 blocking, 0 advisory against the
  tree that produced it.

**Not yet true:**

- The system surfaces outside the launcher are still stock Android. The
  framework-level overlay applies (colours and shape tokens resolve from
  `CircleMetroOverlay.apk`), but Quick Settings in Android 16 is Compose
  and does not read the legacy dimens an RRO can reach.
- The OS boots in **light** mode; the Metro identity is defined as
  true-black. Dark is not yet the product default.
- `ro.circle.*` properties are in `/system/build.prop` but unreadable to
  apps — the SELinux label is not applied. This blocks OTA, which reads
  `ro.circleos.update.url`.
- Nothing is deployed at `ota.circleos.co.za`.

---

## Domains

`circleos.co.za` is ours. **`circleos.com` is not.** Any document naming
`circleos.com`, or `updates.circleos.org`, is wrong and should be
corrected to `circleos.co.za` when found.

---

## If you are about to build

1. Read `aosplite/SETUP.md` if you have never built AOSP.
2. Sync per `docs/REPO_MANIFEST.md`.
3. `aosplite/tools/check-product.sh ~/android circle_arm64` **before**
   the build — it catches faults that otherwise cost a full build, or a
   build plus a flash plus a boot loop.
4. `aosplite/tools/build.sh circle_arm64-bp4a-userdebug systemimage`.
5. `aosplite/tools/flash.sh` to flash. Preflight runs whether you want it
   to or not; if it blocks, nothing is written to the device.
