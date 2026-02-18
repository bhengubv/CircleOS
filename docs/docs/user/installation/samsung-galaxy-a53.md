# Samsung Galaxy A53 (SM-A536B)

!!! warning "Back up your data"
    Unlocking the bootloader **wipes all data**. Back up photos, contacts, and app data before you start.

## Specifications

| Property | Value |
|----------|-------|
| **Chipset** | Exynos 1280 |
| **RAM** | 6 GB / 8 GB |
| **Android base** | Android 14 |
| **Circle OS build** | `circeos-1.0-a53-stable` |
| **Bootloader unlock** | Supported (Samsung OEM) |
| **Status** | Supported ✅ |

---

## What you need

- Samsung Galaxy A53 (SM-A536B) with at least 60% battery
- USB-C cable
- Windows PC (Odin method) or Linux/Mac (Heimdall method)
- [Download Odin](https://odindownload.com/) (Windows) or `brew install heimdall` (Mac)
- [Circle OS A53 package](https://ota.circleos.co.za/os/releases/latest?channel=stable&device=a53) — download the `.zip`

---

## Step 1 — Enable developer options

1. **Settings → About phone → Software information**
2. Tap **Build number** 7 times
3. Enter your PIN when prompted
4. **Settings → Developer options** now visible

---

## Step 2 — Enable OEM unlocking

1. **Settings → Developer options**
2. Toggle **OEM unlocking** ON
3. Confirm the warning dialog

!!! note
    If **OEM unlocking** is greyed out, connect to the internet once and wait a few minutes.
    Samsung activates the toggle server-side after device registration.

---

## Step 3 — Enter Download Mode

1. Power off the phone completely
2. Hold **Volume Up + Volume Down** together
3. Connect USB cable while holding both buttons
4. Press **Volume Up** to confirm entering Download Mode

---

## Step 4 — Flash with Odin (Windows)

1. Open Odin as Administrator
2. Click **AP** → select `circeos-1.0-a53-stable.tar.md5`
3. Verify Odin shows `[0] Added` in the log
4. Settings tab: ensure **Auto Reboot** and **F. Reset Time** are checked
5. Click **Start**
6. Wait for `PASS!` in green — the phone will reboot automatically

### Heimdall (Linux / Mac)

```bash
heimdall flash --AP circeos-1.0-a53-stable.bin --no-reboot
```

---

## Step 5 — First boot

First boot takes **3–5 minutes** — this is normal.
Circle OS is generating encryption keys and calibrating the privacy engine.

When you see the ◯ Circle OS setup wizard, proceed to [First Boot Guide](../first-boot.md).

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Odin shows `FAIL` | Re-download the package; check MD5 hash |
| Phone stuck on Samsung logo | Hold Power + Volume Down for 10 sec to force reboot |
| OEM unlock greyed out | Connect to internet, wait 10 min, retry |
| `Not authorised` in Heimdall | Run with `sudo`; install Samsung USB drivers |
| Bootloop after flash | Re-enter Download Mode, reflash |

---

## Restore stock Android

If you want to go back:

1. Download the stock firmware from [samfrew.com](https://samfrew.com) for your exact model/CSC
2. Flash all partitions (BL, AP, CP, CSC, HOME_CSC) via Odin
3. Samsung warranty note: OEM unlock voids Samsung's warranty in some regions
