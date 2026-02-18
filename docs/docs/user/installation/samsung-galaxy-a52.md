# Samsung Galaxy A52 — Installation Guide

**Model:** SM-A525F / SM-A526B
**Support status:** ✅ Supported
**Estimated time:** 25 minutes

---

## Prerequisites

- [ ] Samsung Galaxy A52 charged to 70%+
- [ ] USB cable (USB-C)
- [ ] Computer with ADB + Fastboot installed
- [ ] Data backed up
- [ ] Samsung USB drivers installed (Windows only)

---

## Step 1: Enable Developer Options

1. Open **Settings → About Phone → Software Information**.
2. Tap **Build Number** 7 times until you see "Developer mode has been enabled".
3. Go to **Settings → Developer Options**.
4. Enable **USB Debugging**.
5. Enable **OEM Unlocking**.

---

## Step 2: Download files

Download these to your computer:

- **Circle OS for A52** — [versions.circleos.co.za](https://versions.circleos.co.za)
- **TWRP for A52** — `twrp-3.7.x-samsung-a52.img`
- **Odin 3.14** (Windows) or **Heimdall** (Mac/Linux)

---

## Step 3: Boot into Download Mode

1. Power off the phone completely.
2. Hold **Volume Down + Volume Up**, then connect USB cable.
3. When the warning screen appears, press **Volume Up** to continue.

---

## Step 4: Flash TWRP

**Windows (Odin):**

1. Open Odin. Your device should appear in the ID:COM field.
2. Click **AP** and select the TWRP `.img` file.
3. Uncheck **Auto Reboot**.
4. Click **Start**. Wait for "PASS" message.

**Mac/Linux (Heimdall):**

```bash
heimdall flash --RECOVERY twrp-3.7.x-samsung-a52.img --no-reboot
```

---

## Step 5: Boot into TWRP

Immediately hold **Volume Up + Power** to boot into TWRP (before Android can overwrite recovery).

---

## Step 6: Flash Circle OS

In TWRP:

1. Tap **Wipe → Format Data** → type "yes" to confirm.
2. Go back, tap **Install**.
3. Navigate to the Circle OS zip file and tap it.
4. Swipe to flash.
5. Wait for completion (2–3 minutes).

For dual boot:
1. Flash to **Slot B** — select the slot in TWRP before flashing.

---

## Step 7: First boot

1. In TWRP, tap **Reboot → System**.
2. First boot takes 3–5 minutes. This is normal.
3. Follow the [First Boot guide](../first-boot.md).

---

## Troubleshooting

| Problem | Solution |
|---------|---------|
| Odin shows "FAIL" | Use a different USB port or cable |
| Phone won't enter Download Mode | Ensure OEM Unlocking is enabled |
| Stuck on boot logo | Wait 10 minutes, then hold Power to restart and try again |
| Can't find device in ADB | Install Samsung USB drivers and restart ADB server |

[General troubleshooting →](../troubleshooting.md)
