# SleptOn App Store

SleptOn is Circle OS's privacy-first app store. It works without Google Play Services and can distribute apps peer-to-peer over the mesh network.

---

## What makes SleptOn different

| Feature | SleptOn | Google Play |
|---------|---------|-------------|
| Account required | No | Yes |
| Tracks installs | No | Yes |
| Works offline | Yes (mesh) | No |
| APK inspection | Yes (sandbox) | No |
| Revenue to developers | 85% | 70% |
| Payment method | Shongololo (₷) or card | Card / carrier billing |

---

## Installing apps

1. Open **SleptOn** from the home screen
2. Browse or search for an app
3. Tap the app → **Install**
4. Circle OS runs the APK through the **Behavioral Sandbox** before installation
5. You see a privacy summary: what permissions the app requests and whether they match its stated purpose
6. Confirm to install

Apps are signed by their developers and verified against SleptOn's signing database.

---

## Mesh distribution

When you download an app, your phone caches the APK locally. If a nearby Circle OS phone needs the same app:

1. Your phone broadcasts availability over BLE
2. The other phone requests chunks directly over WiFi Direct
3. The APK is transferred and verified before install

This means popular apps spread through communities without any internet traffic.

---

## Developer publishing

Developers publish to SleptOn through the [developer portal](https://dev.circleos.co.za):

1. Create a developer account (free)
2. Submit your APK and listing
3. SleptOn's automated scanner checks for privacy violations
4. Human review for apps requesting sensitive permissions
5. Publish to stable, beta, or nightly channel

See the [App Submission Guide](../../dev/app-submission.md) for full details.

---

## Payment with Shongololo

Apps can charge in **Shongololo (₷)**, the Circle OS digital currency:

- Users top up via Titanium Wallet or bank transfer
- Purchases settle instantly on-device (no internet required)
- Developers receive 85% of the sale price
- Chargebacks are handled via the SleptOnAPI dispute endpoint

---

## Sideloading

Circle OS allows sideloading APKs from any source. To sideload:

1. **Settings → Apps → Special app access → Install unknown apps**
2. Enable for your file manager or browser
3. Open the APK file and install

!!! warning
    Sideloaded apps bypass SleptOn's privacy scanner. Circle OS still runs the Behavioral Sandbox and File DMZ on sideloaded APKs, but you take responsibility for the source.

---

## Privacy

SleptOn does not:

- Track which apps you browse or install
- Require a persistent account
- Phone home with your device ID

Your download history lives only on your device. If you clear SleptOn's data, the history is gone.
