# Xiaomi Redmi Note 11 (spes/spesn)

!!! warning "7-day wait"
    Xiaomi requires a 7-day waiting period after enabling Mi Unlock in developer options.
    Start this process a week before you plan to flash.

## Specifications

| Property | Value |
|----------|-------|
| **Chipset** | Snapdragon 680 |
| **RAM** | 4 GB / 6 GB |
| **Android base** | Android 14 |
| **Circle OS build** | `circeos-1.0-note11-stable` |
| **Codename** | `spes` (India/Global) / `spesn` (China) |
| **Bootloader unlock** | Mi Unlock Tool required |
| **Status** | Supported ✅ |

---

## What you need

- Redmi Note 11 with at least 60% battery
- Mi account (create at [account.xiaomi.com](https://account.xiaomi.com))
- [Mi Unlock Tool](https://www.miui.com/unlock/download.html) (Windows only)
- USB-C cable
- ADB + fastboot ([platform-tools](https://developer.android.com/tools/releases/platform-tools))
- [Circle OS Note 11 package](https://ota.circleos.co.za/os/releases/latest?channel=stable&device=note11)

---

## Step 1 — Bind Mi account (start 7 days early)

1. **Settings → About phone** — tap **MIUI version** 7× to enable developer options
2. **Settings → Additional settings → Developer options**
3. Enable **Mi Unlock status** → **Add account and device**
4. Sign in with your Mi account
5. You'll see "Added successfully" — the 7-day clock starts now

---

## Step 2 — Unlock with Mi Unlock Tool (after 7 days)

1. Power off the phone
2. Hold **Volume Down + Power** to enter Fastboot mode
3. Connect USB cable
4. Open Mi Unlock Tool, sign in with same Mi account
5. Click **Unlock** → confirm all warnings
6. Wait for **Unlocked successfully** — the phone wipes and reboots

---

## Step 3 — Flash Circle OS

```bash
# Unzip the Circle OS package
unzip circeos-1.0-note11-stable.zip

# Boot into fastboot (if not already there)
adb reboot bootloader

# Flash
fastboot flash boot boot.img
fastboot flash system system.img
fastboot flash vendor vendor.img
fastboot flash dtbo dtbo.img

# Wipe userdata (clean install)
fastboot -w

# Reboot
fastboot reboot
```

---

## Step 4 — First boot

First boot takes **3–5 minutes**.
When you see ◯ Circle OS setup wizard, proceed to [First Boot Guide](../first-boot.md).

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Mi Unlock Tool says "wait N days" | The 7-day period hasn't elapsed; wait |
| `fastboot: command not found` | Add platform-tools to PATH |
| `FAILED (remote: 'device is locked')` | The bootloader isn't unlocked; recheck Step 2 |
| Phone stuck at MI logo | Hold Power for 12 sec; re-enter fastboot and reflash |
| `fastboot flash system` returns error | Some builds require `--disable-verity --disable-verification` flags |

---

## Restore stock MIUI / HyperOS

1. Download the Global or India ROM from [miui.com/download](https://www.miui.com/download.html)
2. Use Mi Flash Tool (Windows) to restore all partitions
3. Or: hold Power + Volume Up → MiRecovery → Wipe → Flash from SD card
