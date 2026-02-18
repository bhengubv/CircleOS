# Frequently Asked Questions

## General

**Is Circle OS free?**
Yes. Circle OS is free forever. The source code is open under the Apache 2.0 licence.

**Does Circle OS work without the internet?**
Yes. Most features work offline: calls (via carrier), SMS, on-device Butler AI, Titanium wallet, mesh messaging, and all installed apps. An internet connection is only needed for internet-dependent apps (browsers, social media).

**Is Circle OS safe to use as a daily driver?**
Yes. Circle OS is built on Android 14 AOSP and receives the same security patches. The privacy engine adds layers on top — it does not remove Android's existing security.

**Does Circle OS void my warranty?**
Unlocking the bootloader voids the manufacturer's hardware warranty in most regions. Samsung, Xiaomi, and Nokia treat bootloader unlock as warranty-voiding. Circle OS itself doesn't interact with manufacturer warranty systems.

---

## Privacy

**Does Circle OS phone home?**
No. There is no telemetry by default. You can opt in to anonymised analytics in Settings, but the default is fully offline.

**What data does Circle OS collect?**
None, by default. If you join the waitlist or use SleptOn, the data you provide (email, device model) is stored on The Geek Network's servers in South Africa. See [Privacy Policy](../legal/privacy.md).

**Can apps track me?**
The Privacy Engine limits what apps can do. Internet access is default-deny, identifier spoofing is on by default, and unused permissions are auto-revoked. Apps can still track you within their own storage — but they can't phone home without your permission.

**What is identifier spoofing?**
Each app sees a different, randomly-generated Android ID, MAC address, and device fingerprint. This prevents cross-app tracking via device identifiers.

---

## Compatibility

**Will my banking app work?**
Banking apps that rely on Google Play Integrity (formerly SafetyNet) may not work on Circle OS. The dual-boot feature lets you keep stock Android on one slot specifically for banking apps.

**Can I install Google apps?**
Not by default. Circle OS ships with microG, a privacy-respecting Google Play Services replacement. Most apps work with microG. For full Google compatibility, use the dual-boot stock Android slot.

**Does WhatsApp work?**
Yes. WhatsApp works on Circle OS with microG handling the push notifications.

**Does Circle OS support 5G?**
Yes, if your device supports 5G. Circle OS uses the same modem drivers as stock Android.

---

## Titanium Wallet

**What is Shongololo (₷)?**
Shongololo is the Circle OS digital currency. It is used for app purchases on SleptOn and person-to-person payments. 1 ₷ = 1 ZAR (South African Rand) at current rates.

**Does Titanium Wallet require internet?**
No. Payments are processed on-device using offline cryptographic signatures (SDPKT protocol). Transactions settle over the internet when connectivity is available, but the payment itself completes instantly offline.

**Is my wallet safe if I lose my phone?**
Your wallet is encrypted with your device PIN. Without the PIN, the wallet cannot be accessed. You can remotely lock the wallet from the Circle OS web dashboard if you have remote management enabled.

---

## Updates & Mesh

**How do I get updates?**
Updates are delivered over-the-air via the OTA update system. **Settings → Circle OS → Updates → Check for updates**. Updates can also be received from nearby Circle OS phones via the mesh network — no internet required.

**What is a delta update?**
Instead of downloading the full OS (~2 GB), Circle OS downloads only what changed since your current version (~180 MB on average). The delta is applied on-device to reconstruct the full updated partition.

**How does mesh messaging work?**
Nearby Circle OS phones form a local network over Bluetooth LE and WiFi Direct. Messages are relayed hop-by-hop (up to 7 hops) through this network. All messages are end-to-end encrypted with Ed25519/X25519/ChaCha20-Poly1305.

---

## Installation

**What phones are supported?**
See the [Compatibility](https://circleos.co.za/compatibility) page for the full list. At launch: Samsung Galaxy A52, A53 · Xiaomi Redmi Note 10, 11 · Nokia G21. 50+ devices targeted by Q2 2026.

**I bricked my phone. What do I do?**
See [Troubleshooting](troubleshooting.md). Most "bricks" are soft bricks — the bootloader is still accessible and you can reflash. Full hardware bricks are extremely rare with Circle OS.

**Can I go back to stock Android?**
Yes. Each installation guide includes a "Restore stock" section with step-by-step instructions.

---

## Community & Support

**Where can I get help?**
- [Discord](https://discord.gg/circleos) — fastest response
- [Telegram](https://t.me/circleos) — community chat
- [GitHub Issues](https://github.com/bhengubv/CircleOS/issues) — bug reports
- [support.circleos.co.za](https://support.circleos.co.za) — formal support tickets

**Can I contribute to Circle OS?**
Yes! See the [Contributing Guide](../dev/contributing.md). We welcome code, documentation, device ports, and translations.

**Is there a roadmap?**
Yes. See [circleos.co.za/roadmap](https://circleos.co.za/roadmap).
