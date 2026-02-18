# Nokia G21 (TA-1418)

!!! info "Clean install only"
    The Nokia G21 does not support dual-boot. Circle OS replaces the stock Android ROM.
    You can restore stock at any time using the instructions at the bottom.

## Specifications

| Property | Value |
|----------|-------|
| **Chipset** | Unisoc T606 |
| **RAM** | 4 GB / 6 GB |
| **Android base** | Android 14 |
| **Circle OS build** | `circeos-1.0-nokiag21-stable` |
| **Bootloader unlock** | Supported (fastboot) |
| **Status** | Supported ✅ |

---

## What you need

- Nokia G21 with at least 60% battery
- USB-A to USB-C cable
- [ADB + fastboot](https://developer.android.com/tools/releases/platform-tools) on your PC
- [Circle OS Nokia G21 package](https://ota.circleos.co.za/os/releases/latest?channel=stable&device=nokiag21)

---

## Step 1 — Enable developer options

1. **Settings → About phone → Build number** — tap 7 times
2. Enter PIN when prompted
3. **Settings → System → Developer options** now visible

---

## Step 2 — Enable USB debugging

1. **Developer options → USB debugging** → ON
2. Connect USB cable to PC
3. Accept the "Allow USB debugging" prompt on the phone

Verify:
```bash
adb devices
# Should show your device serial
```

---

## Step 3 — Unlock bootloader

!!! warning "Data wipe"
    This erases all data on the phone.

```bash
# Reboot to bootloader
adb reboot bootloader

# Unlock
fastboot oem unlock

# Confirm on-device prompt with Volume Up
```

The phone will wipe and reboot into stock Android. Skip the setup wizard.

---

## Step 4 — Flash Circle OS

```bash
# Reboot to fastboot
adb reboot bootloader

# Unzip the package on your PC first
unzip circeos-1.0-nokiag21-stable.zip

# Flash partitions
fastboot flash boot boot.img
fastboot flash system system.img
fastboot flash vendor vendor.img
fastboot flash vbmeta vbmeta.img --disable-verity --disable-verification

# Wipe userdata for clean install
fastboot -w

# Reboot
fastboot reboot
```

---

## Step 5 — First boot

First boot takes **3–5 minutes** — encryption key generation is running.
When ◯ Circle OS setup wizard appears, see [First Boot Guide](../first-boot.md).

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `adb: no devices found` | Try different USB cable; enable USB debugging |
| `fastboot: waiting for device` | Re-enter fastboot: hold Power + Volume Down |
| `FAILED (remote: 'device is locked')` | Re-run `fastboot oem unlock` |
| Boot loop | Reflash all partitions; ensure `vbmeta` was flashed with `--disable-verity` |
| Black screen after boot | Wait 5 min; encryption may still be initializing |

---

## Restore stock Nokia Android

1. Download the stock firmware from [nokia.com/phones/en_int/support](https://www.nokia.com/phones/en_int/support)
2. Unzip and run the included flash tool (Windows)
3. Or: boot to fastboot → `fastboot oem lock` → flash stock `vbmeta.img` without flags → flash stock partitions
