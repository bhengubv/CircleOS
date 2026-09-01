# Circle OS — Clean-Build Spec
*Grounded in `bhengubv/CircleOS@origin/main`, read from .201 on 2026-09-01.*

## Bottom line
A fresh Ubuntu box **can** build a Circle **AOSP-15 GSI** today (dual-boot via DSU, no wipe). But "clone and run the scripts" is **not** enough yet — two confirmed reasons:

1. **`scripts/sync.sh` omits the Circle overlay drop.** It only `repo init`s + syncs *upstream* AOSP. Run the 3 convenience scripts as-is → you get **stock AOSP**, not Circle. The correct recipe lives in `docs/REPO_MANIFEST.md` ("Path A"), which adds the `.repo/local_manifests/circle.xml` step.
2. **Framework-level Circle services aren't in the image.** The `frameworks/base` fork is *deliberately excluded* from the manifest (stale upstream + Soong break); the privacy/mesh services are meant to apply as `patches/frameworks-base/` post-sync — and **no script applies them yet**. Today's overlay = vendor apps + launcher + settings + device trees on upstream frameworks/base.

So: **buildable = yes** (a Circle-overlay GSI). **Fully-Circle + reproducible = a few known gaps to close** (below).

## Verified reality (origin/main)
- **Front door:** `bhengubv/CircleOS` — docs/spec/manifest/scripts; buildable source in the `CircleOS_*` repos.
- **Base:** upstream AOSP `android-15.0.0_r20`, partial clone (`blob:limit=10M`).
- **Overlay manifest** `manifests/circle.xml` (belongs in `.repo/local_manifests/`), all projects `revision="main"` (floating, not SHA-pinned — by design, pre-alpha):
  `vendor/circle` · `build/circle` · `device/circle/{common,redmi_note12,pixel6}` · `packages/apps/{CircleSettings,CircleLauncher}`
- **frameworks/base:** fork **excluded on purpose** (manifest note: fork is stale upstream, breaks Soong `api.go`; Circle services ship as `patches/frameworks-base/` applied post-sync).
- **Submodule:** `aether-protocol` only (`aether-media`, `CircleAI` are named in the README but not wired into the tree).
- **Devices:** Redmi Note 12 (`sky`, "minimum supported") · Pixel 6 (`oriole`). GSI target `circle_arm64`. lunch combos present: `circle_arm64 / circle_base / circle_common / circle_pixel6 / circle_redmi_note12`.
- **Output:** `out/target/product/generic_arm64/system.img` → `adb push` + DSU Loader (dual-boot, no wipe).

## The clean build — corrected recipe (fresh Ubuntu 22.04/24.04)
Host: ≥16 GB RAM (32 ideal), **≥400 GB SSD** (≈150 source + ≈150 out + 50 ccache), fast link. All repos are public — **no token needed**.

```bash
git clone https://github.com/bhengubv/CircleOS && cd CircleOS
git submodule update --init --recursive          # aether-protocol
sudo ./scripts/setup.sh                           # JDK21, clang/lld, python3-setuptools, repo, ccache 50G

mkdir -p ~/aosp && cd ~/aosp
repo init -u https://android.googlesource.com/platform/manifest \
     -b android-15.0.0_r20 --partial-clone --clone-filter=blob:limit=10M
mkdir -p .repo/local_manifests
curl -o .repo/local_manifests/circle.xml \
     https://raw.githubusercontent.com/bhengubv/CircleOS/main/manifests/circle.xml   # <-- the step scripts/sync.sh omits
repo sync -c -j"$(nproc)" --fail-fast --no-clone-bundle

export USE_CCACHE=1 CCACHE_EXEC=/usr/bin/ccache
source build/envsetup.sh                          # NOTE: no `set -u` — envsetup breaks under nounset
lunch circle_arm64-trunk_staging-userdebug        # <-- Circle product, NOT the scripts' default aosp_arm64
m -j"$(nproc)" systemimage
# -> out/target/product/generic_arm64/system.img
# DSU install: adb push out/.../system.img /sdcard/Download/  →  Settings ▸ Developer ▸ DSU Loader ▸ Local image
```

## Gaps to close for a *real, reproducible* Circle build
1. **⛔ Fix `scripts/sync.sh`** — drop `manifests/circle.xml` into `.repo/local_manifests/` before `repo sync` (currently syncs stock AOSP only). Make the 3 scripts match `docs/REPO_MANIFEST.md` Path A.
2. **Default lunch → `circle_arm64`** in `scripts/build.sh` (currently `aosp_arm64-trunk_staging-userdebug` = stock AOSP).
3. **Apply `patches/frameworks-base/`** post-sync (Circle privacy/mesh services) — add an `apply-patches` step, gated per `AOSP_BUILD_DISCIPLINE.md` (dry-run gate; compressed-JNI-libs gotcha). Without it the framework-level Circle features are absent from the image.
4. **Pin SHAs.** Cut a release tag and revise `circle.xml` from `main` → per-project SHAs for bit-reproducibility.
5. **Reconcile docs vs reality:** `docs/REPO_MANIFEST.md` still lists `frameworks/base` as "replaces upstream" (it's excluded); README says "Android 15" while the base-fork branch is `circle-15/16`. Align them.

## Definition of done
- Fresh box → the recipe above → green `system.img` that **boots via DSU** on a Redmi Note 12 or Pixel 6 (or the `device/circle/common` emulator product) to the Circle launcher.
- Gaps 1–3 folded into `scripts/` so `setup → sync → build` alone yields a *Circle* image; gap 4 tagged.
- Then "a new machine builds it" is a **proven YES**, not a maybe.
