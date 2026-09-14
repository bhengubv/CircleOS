# Building and flashing Circle OS

Circle OS is a product built on [AOSPLite](https://github.com/bhengubv/aosplite).
The mechanics — syncing, checking, building, vbmeta, the flash order,
reading a boot log — are the same for any GSI and are documented once, in
[aosplite/docs/TUTORIAL.md](https://github.com/bhengubv/aosplite/blob/main/docs/TUTORIAL.md).

**This document covers only what is different because it is Circle OS.**
Read it alongside the tutorial, not instead of it.

---

## What "different" means here

An AOSPLite image is plain AOSP with the weight cut out. It has no
launcher, no house style, no bundled apps — `lite_arm64` is
form-factor-neutral and drops the handheld and telephony layers entirely.

Circle OS adds all of that back, as a product:

| | |
|---|---|
| Home screen | `CircleLauncher` (`com.circleos.launcher`), which `overrides` Launcher3 so no chooser appears |
| Alternate home | `CircleMetroLauncher` (`za.co.circleos.launcher`) — the flat Metro tile launcher, installed alongside |
| Theme | `CircleMetroOverlay` — a static RRO on `android` setting the Circle palette and square icon mask |
| Type | Selawik, five weights, per the skin design guide |
| Apps | 22 Circle applications, each with its own adaptive icon |
| Google | replaced by microG |
| Permissions | a privileged-permission allowlist for the Circle apps |

Everything in that table is a reason the build can fail in ways a bare
AOSPLite build cannot. That is what this document is for.

---

## 1. Sync

Follow [step 1 of the tutorial](https://github.com/bhengubv/aosplite/blob/main/docs/TUTORIAL.md#1-get-a-tree)
to get a pruned AOSP 16 tree, then add the Circle overlay manifest
alongside the prune tiers before syncing:

```bash
curl -o .repo/local_manifests/circle.xml \
     https://raw.githubusercontent.com/bhengubv/CircleOS/main/manifests/circle.xml
repo sync -c -j$(nproc) --no-clone-bundle --prune
```

Full inventory, including what is present but unused, is in
[WHERE_EVERYTHING_LIVES.md](WHERE_EVERYTHING_LIVES.md).

**Do not delete upstream `frameworks/base`.** Instructions in this
repository used to say to, so that `CircleOS_platform_frameworks_base`
could replace it. That fork is not in use; removing the upstream project
breaks the tree.

---

## 2. Build

```bash
aosplite/tools/check-product.sh ~/android circle_arm64
aosplite/tools/build.sh circle_arm64-bp4a-userdebug systemimage
```

Output: `out/target/product/generic_arm64/system.img` — `generic_arm64`
because `PRODUCT_DEVICE := generic_arm64`, not the product name.

`bp4a` is mandatory; `trunk_staging` produces an image a released device
refuses to boot. The tutorial explains why.

### What check-product will stop you doing

`build.sh` runs `check-product` itself on every build, so you cannot
forget it; running it first, as above, just gets you the answer in
seconds instead of after `envsetup`.

On a bare AOSPLite build it rarely finds anything, because there are no
bundled privileged apps to get wrong. **On Circle OS it finds things
regularly**, because there are 22 apps, several overlays and a permission
allowlist to keep in step.

Both faults it blocks on have been hit here, and both produce an image
that builds cleanly and reports success:

- **A privileged app missing an allowlist entry.** `system_server` throws
  `IllegalStateException` at `systemReady()` and the device loops on the
  boot animation with no other symptom. Adding the canonical launcher to
  the product introduced exactly this — it requests `BIND_APPWIDGET`,
  which is `signature|privileged`. Caught before flashing, not after.
- **Duplicated VNDK versions.** The system_ext VINTF manifest gets each
  `<version>` twice, `libvintf` rejects the whole file, servicemanager
  runs with no framework manifest, and the kernel panics through Trusty
  about four minutes into boot.

---

## 3. Flash

Identical to the tutorial from step 4 onward. Nothing about flashing is
Circle-specific.

---

## Circle-specific things that will bite you

### `CircleTheme` is not built, on purpose

`vendor/circle/overlay/CircleTheme` is a `runtime_resource_overlay`
targeting `android`, but every resource it defines is a *new* name —
`circle_accent`, `circle_surface_elev_1`, `circle_radius_card` and the
rest. **An RRO can only replace a resource the target already has**,
verified against `frameworks/base/core/res`. Even compiling cleanly, it
would install and do nothing.

It also cannot compile as it stands: the eight `colors_mode_*.xml` files
each redefine `circle_accent` for the same configuration, which aapt2
rejects.

`config/common.mk` carries this reasoning inline. If you add it back to
`PRODUCT_PACKAGES`, the build fails — that is the module telling you the
truth about itself.

### Only one launcher may claim HOME

`Launcher3QuickStep` arrives through `handheld_system_ext.mk`, which the
product inherits and cannot subtract from. With two apps answering HOME
and no preference recorded, Android shows a chooser on first boot.

`CircleLauncher` resolves this with `overrides: ["Launcher3",
"Launcher3QuickStep"]` in its `Android.bp`, so the stock launcher is
never installed. `CircleMetroLauncher` deliberately does **not** override
— two modules both claiming it makes the default ambiguous.

An `etc/preferred-apps` XML was tried first and had no effect.

### Adding an app means adding its permissions

Any package in `/system/priv-app` requesting a `signature|privileged`
permission needs an entry in
`vendor/circle/permissions/circle_privapp_permissions.xml`. Do not list
non-privileged permissions there; an allowlist entry for a permission
that is not privileged is itself an error.

---

## Known gaps, as of 2026-09-15

The image boots on a Pixel 7a — `sys.boot_completed=1`, 335 services, no
crashes. These are not yet true, and are written down so nobody
rediscovers them:

- **The system surfaces outside the launcher are still stock.** The
  framework-level overlay does apply — colours and shape tokens resolve
  from `CircleMetroOverlay.apk`, and `dialog_corner_radius` is `0.0dip` —
  but Quick Settings in Android 16 is Compose and does not read the
  legacy dimens an RRO can reach.
- **The OS boots in light mode** while the Metro identity is defined as
  true-black. Dark is not yet the product default.
- **`ro.circle.*` properties are unreadable to apps.** They are in
  `/system/build.prop`, but the SELinux label is not applied, so
  `getprop` returns empty and logcat shows
  `Access denied finding property "ro.circle.version"`. This blocks OTA,
  which reads `ro.circleos.update.url`.
- **`ro.build.display.id` is set and then overridden** by a later prop
  file during init.
- **Nothing is deployed at `ota.circleos.co.za`.**
- **`com.circleos.server.*` and `CircleHeyB` exist in no repository** —
  only on the `.201` build machine.
