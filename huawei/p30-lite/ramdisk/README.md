# Boot-selector ramdisk

The `init` binary built here is what gets written into `mmcblk0p21` (the
`ramdisk` partition) on the Huawei P30 Lite. It runs as PID 1 and decides
which OS boots based on whether Volume Up is held.

## What it does

```
                      power-on
                          │
                  kernel loads itself
                          │
            kernel exec /init  ← that's this binary
                          │
              ┌───────────┴───────────┐
              │ Vol Up held at boot? │
              └───────────┬───────────┘
                     yes  │  no
                          │
              ┌───────────┴───────────┐
              ▼                       ▼
     boot CircleOS path        exec /init.huawei
     (mount + pivot_root)      (stock EMUI boots)
              │                       │
       circleos_system            EMUI starts
       AOSP init runs             Huawei normally
```

The default action — and the fall-through for any failure — is stock
Android. This is non-negotiable: a broken selector must never leave the
user unable to boot back into their phone.

## Build

```bash
make
make check
```

Produces a `~30–50 KB` statically-linked aarch64 ELF named `init`.

If `make` errors with *"No aarch64 cross-compiler found"*, install one:

```bash
# Quickest path on Ubuntu / Debian:
wget https://musl.cc/aarch64-linux-musl-cross.tgz
tar xf aarch64-linux-musl-cross.tgz
export PATH=$PWD/aarch64-linux-musl-cross/bin:$PATH
make
```

## Deploy (preview — full procedure lives in `INJECT.md`)

The built `init` is *one* file inside a CPIO archive that becomes the new
ramdisk. The build of the full image (and its flashing) is handled by the
injection scripts at `../INJECT.md`. In rough outline:

```
new_ramdisk.cpio.gz ← contents:
  /init                ← THIS binary (the selector)
  /init.huawei         ← the original Huawei /init, renamed
  /init.rc, /init.${ro.hardware}.rc, /file_contexts, /selinux_policy, ...
       (everything else from the original Huawei ramdisk, untouched)
```

When the selector decides "stock Android", it `execve()`s `/init.huawei`,
which is bit-identical to the OEM init — meaning stock EMUI boots as if
nothing was ever changed.

## Status

**v0.** The selector logic works (volume-key scan + stock-Android dispatch).
The CircleOS branch is stubbed — it logs to `dmesg` and falls through to
stock Android. This is intentional until `INJECT.md` is built out and the
`circleos_system` partition actually exists. We don't want a "tries to
boot CircleOS but silently fails" device.

## Why C, not shell

Chapter 6 of the spec allows either. C wins because:

- Smaller (~30 KB static, vs. busybox ~600 KB + the script).
- Faster startup (no shell interpreter).
- No dependency on `/bin/sh` existing in our minimal ramdisk.
- Predictable failure modes.

## What this binary does *not* do

- Mount or set up `/dev` / `/proc` / `/sys` — we rely on devtmpfs being
  auto-mounted by the kernel (the Huawei kernel config has `CONFIG_DEVTMPFS_MOUNT=y`,
  to be confirmed by `INJECT.md` when we extract the boot args).
- Implement SELinux policy loading — the original Huawei `/init` will do that on
  the stock path; the AOSP `/init` will do it on the CircleOS path.
- Network, splash screen, animations, anything else. Not its job.
