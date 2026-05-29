# Huawei P30 Lite — hard-mode install path

This directory holds the **hard-mode reference** install path for CircleOS v2.0:
a Huawei P30 Lite (Kirin 710, EMUI 10) coexisting with the stock OS via a
custom boot-selector ramdisk and a non-destructive partition injection.

This is the **proving ground**, not the default install. The default for end
users is the DSU GSI install — see [`../../docs/INSTALL_PATHS.md`](../../docs/INSTALL_PATHS.md).

## Why this device

The P30 Lite is deliberately the hardest realistic target:

- **Bootloader permanently locked** (Huawei removed the unlock service in 2018).
- **dm-verity enforced** on every system partition.
- **A-only partition layout** (no easy A/B slot trick).
- **Cheap and widely available** in our target markets.

If CircleOS runs on *this*, it runs anywhere DSU is supported.

## Architecture in one paragraph

We use the [PotatoNV](https://github.com/mashed-potatoes/PotatoNV) hardware
exploit on the Kirin 710 boot ROM to enter download mode without an unlock
code. From there we shrink the `userdata` partition by ~4 GB, carve a new
`circleos_system` partition into the freed space, write CircleOS into it,
and replace the boot ramdisk at `mmcblk0p21` with our own. Our ramdisk runs
as PID 1; it reads `/dev/input/event*`, checks whether Volume Up is held,
and either pivots into `circleos_system` (Vol Up) or execs the original
Huawei `/init` (everything else). The stock partition table is never
rewritten; the kernel partition is never touched; dm-verity stays green.

## Files in this directory

| Path | What |
|---|---|
| `README.md` | This file. |
| `DEVICE_AUDIT.md` | Captured state of a real device — bootloader, partitions, sizes. |
| `ramdisk/init.c` | The boot-selector init. Statically-linked aarch64 C, ~200 lines. |
| `ramdisk/Makefile` | Cross-compile the init binary against musl. |
| `ramdisk/README.md` | How to build, what the binary does, deploy procedure. |
| `INJECT.md` *(TODO)* | Step-by-step partition injection recipe. |
| `POTATONV.md` *(TODO)* | PotatoNV hardware exploit procedure — test points, wire, timing. |

## Status

Scaffold + boot-selector ramdisk v0 only. **Not yet flashable.** The selector
boots stock Android cleanly; the CircleOS branch is a stub that kernel-panics
with a recognisable message (so we know the selector logic works before we
build out the rest of the chain).

## Safety contract

Every commit to this directory must preserve these invariants:

1. **The user must always be able to boot stock Android with one normal reboot.**
2. **The global partition table must not be rewritten** — only individual partitions and the end-of-userdata are touched.
3. **dm-verity must stay green on all original Huawei partitions** — we add alongside, we never modify.
4. **Every destructive step must have a documented reversal.**

Violations of any of these are non-mergeable.
