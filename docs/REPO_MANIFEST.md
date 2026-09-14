# Building Circle OS from canonical sources

The end-to-end recipe for assembling an AOSP tree plus every `CircleOS_*`
repo, in the right places, and getting a system image out the other end.

> **Base is AOSP 16 (`android-16.0.0_r4`), not 15.** This document
> described a 15 tree until 2026-09-15. The tree that currently builds and
> boots on a Pixel 7a is 16. Where a command below differs from what you
> remember, the 16 form is the one that has been run.

For a map of which repositories are active, which are not, and what lives
where, see [WHERE_EVERYTHING_LIVES.md](WHERE_EVERYTHING_LIVES.md).

## Inventory — what gets pulled where

| Repo (`github.com/bhengubv/...`)         | AOSP tree path                       |
|------------------------------------------|--------------------------------------|
| ~~`CircleOS_platform_frameworks_base`~~    | **not used** — upstream AOSP `frameworks/base` is what builds and boots |
| `CircleOS_vendor_circle`                  | `vendor/circle`                      |
| `CircleOS_build`                          | `build/circle`                       |
| `CircleOS_device_circle_common`           | `device/circle/common`               |
| `CircleOS_device_circle_redmi_note12`     | `device/circle/redmi_note12`         |
| `CircleOS_device_circle_pixel6`           | `device/circle/pixel6`               |
| `CircleOS_packages_apps_CircleSettings`   | `packages/apps/CircleSettings`       |
| `CircleOS_packages_apps_CircleLauncher`   | `packages/apps/CircleLauncher`       |

Manifest source: [`manifests/circle.xml`](../manifests/circle.xml).
Base AOSP tag: **`android-16.0.0_r4`**.

`CircleOS_packages_apps_CircleSettings` is in the table because it is the
canonical repo, but the working tree does not sync it — it builds
`vendor/circle/apps/CircleSettings` instead. Reconciling the two is open.

## Path A — bootstrap a fresh tree

Use this on a clean machine. ~250 GB free disk and 16 GB RAM minimum
recommended; 32 GB RAM ideal.

```bash
# 1. Tools
sudo apt-get install -y curl git python3 python3-setuptools openjdk-21-jdk-headless ccache \
                       build-essential bc bison flex libssl-dev libxml2-utils
mkdir -p ~/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod +x ~/bin/repo
export PATH=$HOME/bin:$PATH

# 2. AOSP base
mkdir -p ~/circle-tree && cd ~/circle-tree
repo init -u https://android.googlesource.com/platform/manifest \
          -b android-16.0.0_r4 \
          --partial-clone --clone-filter=blob:limit=10M

# 3. Drop the Circle overlay manifest
mkdir -p .repo/local_manifests
curl -o .repo/local_manifests/circle.xml \
     https://raw.githubusercontent.com/bhengubv/CircleOS/main/manifests/circle.xml

# 4. Sync everything (first time: 1–3 h depending on network)
repo sync -c -j"$(nproc)" --fail-fast --no-clone-bundle

# 5. ccache + swap (recommended for low-RAM hosts)
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
ccache -M 50G

# 6. Build
source build/envsetup.sh
lunch circle_arm64-bp4a-userdebug
m -j"$(nproc)" systemimage      # ~3–6 h cold; ~8–20 min incremental
```

**`bp4a` is not optional.** It is the released release-config. Building
`trunk_staging` produces an image that declares itself pre-release
(`ro.build.version.codename=Baklava`, `preview_sdk=1`) and will not boot on
a released device. Patching those properties in a finished image does not
help — the libraries underneath are still staging builds.

The resulting GSI lands in
**`out/target/product/generic_arm64/system.img`** — `generic_arm64`, not
`circle_arm64`, because the product sets `PRODUCT_DEVICE := generic_arm64`.

Before spending the build, and before flashing what it produced, use the
checks in [`aosplite`](https://github.com/bhengubv/aosplite):

```bash
tools/check-product.sh ~/android circle_arm64   # catches boot-loop faults
tools/flash.sh --img out/target/product/generic_arm64/system.img \
               --vbmeta <vbmeta with flags=2 in the FILE> --serial <serial>
```

`flash.sh` always runs flash preflight and writes nothing to the device if
it reports a blocking problem.

## Path B — add the Circle overlay to an already-synced AOSP tree

Use this on `.201` (and any other machine where `repo init` of upstream
AOSP has already finished). Saves redownloading the base tree.

```bash
cd ~/aosp                                # or wherever the AOSP tree lives

# 1. Add overlay manifest
mkdir -p .repo/local_manifests
curl -o .repo/local_manifests/circle.xml \
     https://raw.githubusercontent.com/bhengubv/CircleOS/main/manifests/circle.xml

# 2. Pull in the Circle projects.
#    Do NOT delete upstream frameworks/base. An earlier version of this
#    document replaced it with CircleOS_platform_frameworks_base; that fork
#    is not in use, and removing the upstream project breaks the tree.
repo sync -c -j"$(nproc)" --no-clone-bundle \
          vendor/circle build/circle \
          device/circle/common device/circle/redmi_note12 device/circle/pixel6 \
          packages/apps/CircleLauncher

# 3. Build (same as Path A step 6)
source build/envsetup.sh
lunch circle_arm64-bp4a-userdebug
m -j"$(nproc)" systemimage
```

## Verification

After `repo sync` completes, every path in the [Inventory](#inventory--what-gets-pulled-where) table should exist as a populated git checkout:

```bash
for p in vendor/circle build/circle \
         device/circle/{common,redmi_note12,pixel6} \
         packages/apps/CircleLauncher; do
    if [ -d "$p" ] && [ -n "$(ls -A "$p")" ]; then
        echo "ok   $p"
    else
        echo "FAIL $p"
    fi
done
```

A successful `lunch circle_arm64-bp4a-userdebug` followed by `m nothing`
proves the Soong analysis phase parses every Android.bp in the tree —
this is the fastest way to catch a missing module or sepolicy mismatch
before committing to a full system image build.

## Adding new device targets

A new device gets its own `CircleOS_device_circle_<codename>` repo plus
one line in [`manifests/circle.xml`](../manifests/circle.xml). The
Huawei P30 Lite hard-mode reference path lives separately under
[`huawei/p30-lite/`](../huawei/p30-lite/) of this repo because it
doesn't follow the upstream AOSP device-tree pattern — it injects a
custom ramdisk into a stock Huawei kernel and uses the PotatoNV exploit
to enter download mode. See [`huawei/p30-lite/README.md`](../huawei/p30-lite/README.md).

## Pinning for releases

`circle.xml` currently tracks `main` on every Circle project. For an
alpha or release cut, replace every `revision="main"` with a 40-char
commit SHA so the sync is reproducible. The release scripts under
`vendor/circle/release/` will use the pinned manifest as the
release-artifact source of truth.
