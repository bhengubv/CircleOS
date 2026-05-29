# P30 Lite — device audit

Captured 2026-05-29 from a real device (serial `UTKDU19919000815`) via
`adb shell` over USB. Read-only commands; the device was not modified.

## Identity

| Property | Value |
|---|---|
| Manufacturer / brand | HUAWEI / HUAWEI |
| Model | `MAR-LX1M` (international / Latin America variant) |
| Codename | `HWMAR` |
| Build fingerprint | `HUAWEI/MAR-LX1M/HWMAR:10/HUAWEIMAR-L01MEA/10.0.0.273C316:user/release-keys` |
| Display ID | `MAR-L01MEA 10.0.0.273(C316E7R1P3)` |
| SoC | HiSilicon Kirin 710 |
| ABI | `arm64-v8a` |
| Android version | 10 (API 29) |
| Security patch | **2020-08-01** (~6 years stale — expected; Huawei dropped global updates) |

## Kernel

| Property | Value |
|---|---|
| Version | Linux 4.14.116 (aarch64) |
| Toolchain | Android Clang 9.0.3 (LLVM 9.0.3svn) |
| Built | 2022-05-17 (CST) |

`/proc/cmdline` is read-restricted under stock `adb shell` user (Android 10
hardening). We can pick it up over fastboot or from the kernel ring buffer
later if we need the boot arguments verbatim.

## Bootloader state

| Property | Value | Meaning |
|---|---|---|
| `ro.boot.flash.locked` | `1` | **Bootloader is LOCKED.** No `fastboot oem unlock`. PotatoNV exploit required. |
| `ro.boot.verifiedbootstate` | `green` | The bootloader currently considers the boot chain verified-and-signed. |
| `ro.boot.veritymode` | `enforcing` | dm-verity is enforced — we cannot modify system/vendor/etc. at runtime. |
| `ro.crypto.state` | `encrypted` | userdata is FBE-encrypted. Standard. Does not block us. |
| `ro.boot.slot_suffix` | (empty) | **A-only device, no A/B slots.** Chapter 6 §3.2 applies. |

## Partition layout

`/proc/partitions` is restricted, but `/dev/block/by-name/` gives the
relevant mapping. The eMMC is `mmcblk0`; numbered partitions are
`mmcblk0pN`. Dynamic logical partitions inside the `super` partition surface
as `dm-N`.

### Key physical partitions

| Name | Block | Notes |
|---|---|---|
| `kernel` | `mmcblk0p48` | Active kernel. **Untouched by our design** — we keep Huawei's kernel. |
| `ramdisk` | `mmcblk0p21` | **The boot ramdisk we replace** with our selector. |
| `dtb` (`dts`) | `mmcblk0p52` | Device tree. Untouched. |
| `dtbo` (`dto`) | `mmcblk0p53` | DT overlay. Untouched. |
| `vbmeta` | `mmcblk0p61` | Verified-boot metadata (top-level). Untouched. |
| `super` | `mmcblk0p68` | Holds system/vendor/odm/cust/hw_product/preload/preas/version as `dm-*` logical partitions. Untouched. |
| `userdata` | `mmcblk0p71` | **108 GB total, 66 GB used, 42 GB free** — *our injection target* (shrink end by ~4 GB → `circleos_system`). |
| `cache` | `mmcblk0p65` | **93 MB total, 84 KB used** (99.9 % empty). Too small for the GSI but useful for staging. |
| `misc` | `mmcblk0p29` | Bootloader control block. Read only; we leave it alone. |
| `erecovery_*` | `mmcblk0p45, p46, p47, p60` | Emergency recovery slots. Potential secondary hijack target. |
| `recovery_*` | `mmcblk0p50, p51, p59` | Stock recovery. Leave alone — user needs it for OTA rollback if they ever decide to. |

### Mounts (live)

| Mount | Size | Notes |
|---|---|---|
| `/` | 1.8 GB | dm-6 — overlay rootfs. |
| `/system/...` | 694 MB | dm-14 (preas). |
| `/vendor` | 394 MB | dm-11. |
| `/hw_product` | 1.5 GB | dm-8. |
| `/odm` | 129 MB | dm-9. |
| `/cust` | 41 MB | dm-7. |
| `/preload` | 195 MB | dm-10. |
| `/data` | 108 GB / 66 GB used / 42 GB free | mmcblk0p71. |
| `/cache` | 93 MB / 84 KB used | mmcblk0p65. |
| `/storage/3565-6336` | 15 GB / 13 GB used | SD card present. |

## What this means for the install design

1. **PotatoNV is mandatory.** No software unlock exists for this generation
   of Huawei devices. Confirmed by `flash.locked=1` + `verifiedbootstate=green`.

2. **A-only layout** → we *cannot* use the A/B trick. We must carve a new
   partition or hijack an existing one.

3. **Injection target = end of `userdata`.** It has 42 GB free, more than
   enough to surrender ~4 GB. The shrink is "non-destructive" because we
   only reduce the partition's declared end, we do not touch existing data
   blocks within the new boundary.

4. **Ramdisk replacement target = `mmcblk0p21`.** Our boot-selector binary
   replaces the Huawei `/init` here. We preserve the rest of the original
   Huawei ramdisk contents inside the new image, with their `/init` renamed
   to `/init.huawei` so we can `execve()` into it on the stock-Android path.

5. **dm-verity stays green** because we are *not* writing to the verified
   partitions (system, vendor, odm, cust, hw_product). We add `circleos_system`
   alongside them.

6. **Kernel partition is never touched.** The Huawei kernel boots; our
   ramdisk is a userspace-only intervention.

## Reversal posture

To return the device to fully stock at any time:
1. PotatoNV back into download mode.
2. Restore the original `mmcblk0p21` ramdisk image (saved during install).
3. Grow `userdata` back to its original end-block.
4. Reboot.

The `circleos_system` partition data may stay on disk harmlessly; the
bootloader and stock init won't reference it.

## Open questions to answer before flashing

- [ ] Exact size of `mmcblk0p21` (`ramdisk`) in bytes — needed to size the
      injected image. Get via `blockdev --getsize64` once we have a root shell.
- [ ] Exact size of the unused tail of `mmcblk0p71` (`userdata`) — for the
      shrink + carve math.
- [ ] Does `vbmeta` block our chosen `circleos_system` mount if we don't
      register it there? *Likely yes — we'll need a `disable-verity` chained
      vbmeta image or just bypass verity for our partition.*
- [ ] Behaviour of `ro.boot.verifiedbootstate` after the ramdisk swap — does
      it drop to `orange` or remain `green`? Affects whether the user sees a
      bootloader warning screen.
