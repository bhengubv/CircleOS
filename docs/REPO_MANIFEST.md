# Building Circle OS from canonical sources

This is the end-to-end recipe for assembling an AOSP 15 tree plus every
`CircleOS_*` repo, in the right places, and getting a system image out
the other end. It supersedes the from-scratch `vendor/circle/`
scaffold that briefly lived in this repo on 2026-05-30 — that work has
been reverted and replaced with the manifest-driven approach documented
here.

## Inventory — what gets pulled where

| Repo (`github.com/bhengubv/...`)         | AOSP tree path                       |
|------------------------------------------|--------------------------------------|
| `CircleOS_platform_frameworks_base`       | `frameworks/base` *(replaces upstream)* |
| `CircleOS_vendor_circle`                  | `vendor/circle`                      |
| `CircleOS_build`                          | `build/circle`                       |
| `CircleOS_device_circle_common`           | `device/circle/common`               |
| `CircleOS_device_circle_redmi_note12`     | `device/circle/redmi_note12`         |
| `CircleOS_device_circle_pixel6`           | `device/circle/pixel6`               |
| `CircleOS_packages_apps_CircleSettings`   | `packages/apps/CircleSettings`       |
| `CircleOS_packages_apps_CircleLauncher`   | `packages/apps/CircleLauncher`       |

Manifest source: [`manifests/circle.xml`](../manifests/circle.xml).
Base AOSP tag: `android-15.0.0_r20`.

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
          -b android-15.0.0_r20 \
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
lunch circle_arm64-userdebug   # or circle_arm64-trunk_staging-userdebug
m -j"$(nproc)" systemimage      # ~3–6 h cold; ~10–30 min hot via ccache
```

The resulting GSI lands in `out/target/product/circle_arm64/system.img`.

## Path B — add the Circle overlay to an already-synced AOSP tree

Use this on `.201` (and any other machine where `repo init` of upstream
AOSP has already finished). Saves redownloading the base tree.

```bash
cd ~/aosp                                # or wherever the AOSP tree lives

# 1. Add overlay manifest
mkdir -p .repo/local_manifests
curl -o .repo/local_manifests/circle.xml \
     https://raw.githubusercontent.com/bhengubv/CircleOS/main/manifests/circle.xml

# 2. Drop the upstream frameworks/base so the Circle fork can take its place
rm -rf frameworks/base .repo/projects/frameworks/base.git \
       .repo/project-objects/platform/frameworks/base.git

# 3. Pull in the Circle projects
repo sync -c -j"$(nproc)" --no-clone-bundle \
          vendor/circle build/circle frameworks/base \
          device/circle/common device/circle/redmi_note12 device/circle/pixel6 \
          packages/apps/CircleSettings packages/apps/CircleLauncher

# 4. Build (same as Path A step 6)
source build/envsetup.sh
lunch circle_arm64-userdebug
m -j"$(nproc)" systemimage
```

## Verification

After `repo sync` completes, every path in the [Inventory](#inventory--what-gets-pulled-where) table should exist as a populated git checkout:

```bash
for p in vendor/circle build/circle frameworks/base \
         device/circle/{common,redmi_note12,pixel6} \
         packages/apps/{CircleSettings,CircleLauncher}; do
    if [ -d "$p" ] && [ -n "$(ls -A "$p")" ]; then
        echo "ok   $p"
    else
        echo "FAIL $p"
    fi
done
```

A successful `lunch circle_arm64-userdebug` followed by `m nothing`
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
