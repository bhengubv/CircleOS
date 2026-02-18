# Troubleshooting

Don't worry — most problems have a simple fix. If something went wrong, you can always restore your original Android.

---

## Installation problems

### Phone not detected by ADB

```bash
adb kill-server
adb start-server
adb devices
```

- Check USB Debugging is enabled
- Try a different USB cable (data cable, not charging-only)
- Install phone-specific drivers (Samsung, Xiaomi, etc.)
- Try a different USB port

### Fastboot not found / command not found

Make sure platform-tools is in your PATH:

```bash
# Mac/Linux — add to ~/.zshrc or ~/.bashrc:
export PATH="$PATH:/path/to/platform-tools"

# Verify:
fastboot --version
```

### Stuck on Circle OS logo after install

Hold Power for 10 seconds to force restart. If it happens again:

1. Boot into recovery (TWRP).
2. **Wipe → Dalvik/ART Cache**.
3. Reboot system.

### Bootloop (keeps restarting)

1. Boot into TWRP.
2. **Wipe → Advanced Wipe → check Cache + Dalvik**.
3. If still looping: **Wipe → Format Data** and reflash.

---

## After installation

### Apps can't connect to the internet

Circle OS uses **default-deny internet**. Grant network access per app:

**Circle Settings → Privacy → Network Permissions → [App Name] → Allow**

### Butler isn't responding

- Check you're using a supported model tier (see [Butler docs](features/butler.md))
- Try: **Settings → Butler → Clear Cache → Restart Butler**

### Mesh not finding nearby devices

- Ensure both devices have Circle OS
- Check: **Settings → Mesh → Enable WiFi Direct + Bluetooth LE**
- Devices must be within ~100m

### Titanium payment failed

- Ensure both phones have NFC enabled
- Check the sending phone has a positive balance
- If offline: check that mesh is active for settlement

---

## Restoring Android

If you need to go back to stock Android:

1. Download your device's stock firmware from the manufacturer.
2. Boot into Fastboot mode.
3. Flash the stock firmware:
   ```bash
   fastboot flashall
   ```
4. Or for Samsung: use Odin with the stock firmware package.

!!! info
    Dual boot users can simply reboot and select Slot A — no restoration needed.

---

## Getting more help

- [Community Discord](https://discord.gg/circleos) — fastest response
- [Support portal](https://support.circleos.co.za) — ticket system
- [GitHub Issues](https://github.com/bhengubv/CircleOS/issues) — bug reports
