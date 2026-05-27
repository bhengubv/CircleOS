# Install paths

CircleOS v2.0 ships through two install paths, by design — different
audiences, different mechanisms, same OS image at the end.

## 1. DSU soft migration — *this repo*

**Audience:** anyone with an Android 10+ device.
**Risk:** zero. Brick-proof by construction.

### How it works

Android's Dynamic System Updates (DSU) is a native AOSP feature since
Android 10. It boots a guest system image (GSI) from a virtual partition
allocated inside `/data` — without touching the stock `/system`, `/vendor`,
or `/boot`, and without unlocking the bootloader.

- Boot into stock Android as normal.
- User opens the CircleOS installer (or DSU Loader app) and selects the
  GSI image.
- DSU allocates space in `/data`, copies the image, and the next reboot
  brings up CircleOS as a guest.
- The user can exit DSU at any time — the next reboot returns to stock
  Android, untouched.

### Failsafe

If CircleOS crashes, freezes, hits a kernel panic, or the device just
loses power mid-session, the next normal boot returns to stock Android.
There is no recovery dance, no flashing, no risk of bricking.

### Output of *this repo*

`out/target/product/generic_arm64/system.img` — a Treble-compliant GSI
built from AOSP, configurable for CircleOS's privacy / age-modes /
Aether / firewall layers as those components land.

## 2. Hard-mode reference — *separate repo (TBD)*

**Target:** Huawei P30 Lite (HiSilicon Kirin 710).
**Audience:** developers proving CircleOS on hostile, locked hardware.
**Risk:** real. Hardware test-point shorting is required to unlock.

### How it works

1. **Bootloader bypass** via PotatoNV / Kirin 710 boot-ROM exploit
   (test-point shorting on the SoC's USB or NV line).
2. **Non-destructive partition injection** — shrink the end of `userdata`
   or hijack underused blocks (`/cache`, secondary recovery). Do *not*
   wipe the global partition table.
3. **Custom `initramfs`** in raw C or shell, mounted as the very first
   stage. Reads `/dev/input/event*`:
   - **Volume Up held** → `switch_root` into the CircleOS partition.
   - Else → exec `/system/bin/init` and boot stock Android.

"Coexist, don't conquer."

This is the *proving ground*. If the OS image runs cleanly under partition
hijack on a locked Huawei device, it runs anywhere DSU is supported.

## Relationship between the two

- The *same* AOSP-built GSI image runs in both paths.
- DSU is the default user install — sized for grandmothers and 7-year-olds.
- The hard-mode path exists to prove CircleOS works without DSU, on
  hardware where the OEM does not want anything else booting.
- Both paths must verify the user can always return to stock Android
  with one normal reboot. That is non-negotiable.
