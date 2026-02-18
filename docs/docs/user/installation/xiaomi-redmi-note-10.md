# Xiaomi Redmi Note 10 — Installation Guide

**Model:** M2101K7AG / M2101K7AI
**Support status:** ✅ Supported
**Estimated time:** 30 minutes (Xiaomi requires bootloader unlock approval)

---

## Prerequisites

- [ ] Redmi Note 10 charged to 70%+
- [ ] USB cable
- [ ] Computer with ADB + Fastboot
- [ ] **Mi Unlock Tool** (Windows only, required for bootloader unlock)
- [ ] Xiaomi account with the device linked for 7+ days
- [ ] Data backed up

!!! warning "7-day wait"
    Xiaomi requires your Mi account to be linked to the device for at least 7 days before allowing bootloader unlock. Do this early.

---

## Step 1: Enable Developer Options

1. **Settings → About Phone → tap MIUI Version 7 times**.
2. **Settings → Additional Settings → Developer Options**.
3. Enable **USB Debugging** and **OEM Unlocking**.
4. Enable **Mi Unlock Status** → **Agree** and link your Mi account.

---

## Step 2: Unlock the bootloader (Mi Unlock Tool — Windows)

1. Download **Mi Unlock Tool** from the Xiaomi website.
2. Sign in with your Mi account.
3. Power off the phone. Hold **Volume Down + Power** to enter Fastboot.
4. Connect via USB.
5. In Mi Unlock Tool, click **Unlock** and follow prompts.
6. The phone will factory reset. Normal.

**Mac/Linux (alternative):**
```bash
fastboot oem unlock
```
This may be disabled — use Mi Unlock Tool if it fails.

---

## Step 3: Flash TWRP

```bash
fastboot flash recovery twrp-redmi-note-10.img
fastboot boot twrp-redmi-note-10.img
```

---

## Step 4: Flash Circle OS

In TWRP:

1. **Wipe → Format Data** → type "yes".
2. **Install** → select Circle OS zip.
3. Swipe to flash.
4. **Reboot → System**.

---

## First boot

First boot takes 4–6 minutes. Follow the [First Boot guide](../first-boot.md).

[Troubleshooting →](../troubleshooting.md)
