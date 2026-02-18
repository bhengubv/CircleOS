# Installation Overview

Circle OS can be installed on any [supported device](https://circleos.co.za/compatibility). The process takes about 20 minutes.

!!! tip "Dual boot is safer"
    If you're not sure, choose dual boot. Your original Android stays intact in Slot A.

---

## Step 1: Prepare your phone

1. Charge your phone to at least 70%.
2. Back up all your data (photos, contacts, apps).
3. Enable Developer Options: **Settings → About Phone → tap Build Number 7 times**.
4. Enable USB Debugging: **Settings → Developer Options → USB Debugging → On**.
5. Enable OEM Unlocking: **Settings → Developer Options → OEM Unlocking → On**.

!!! warning
    Enabling OEM Unlocking may void your software warranty. Hardware is unaffected.

---

## Step 2: Download the tools

Download and install:

- **ADB + Fastboot** — [platform-tools from Google](https://developer.android.com/tools/releases/platform-tools)
- **Circle OS ROM** for your device — [versions.circleos.co.za](https://versions.circleos.co.za)
- **TWRP recovery** (or equivalent) for your device — see your device guide

---

## Step 3: Unlock the bootloader

Connect your phone via USB. Open a terminal and run:

```bash
adb devices          # confirm your phone is listed
adb reboot bootloader
fastboot oem unlock  # or: fastboot flashing unlock
```

Your phone will factory reset. This is normal.

---

## Step 4: Flash Circle OS

Follow the device-specific guide for your phone:

| Device | Guide |
|--------|-------|
| Samsung Galaxy A52 | [View guide](samsung-galaxy-a52.md) |
| Samsung Galaxy A53 | [View guide](samsung-galaxy-a53.md) |
| Xiaomi Redmi Note 10 | [View guide](xiaomi-redmi-note-10.md) |
| Xiaomi Redmi Note 11 | [View guide](xiaomi-redmi-note-11.md) |
| Nokia G21 | [View guide](nokia-g21.md) |

---

## Step 5: First boot

[First Boot Guide →](../first-boot.md)

---

## Something went wrong?

Don't panic. [Troubleshooting guide →](../troubleshooting.md)

Your original Android can always be restored using the stock firmware for your device.
