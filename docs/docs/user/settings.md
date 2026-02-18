# Circle OS Settings

All Circle OS privacy and feature settings live under **Settings → Circle OS**. This page describes every option.

---

## Privacy Engine

### Network permissions

**Settings → Circle OS → Privacy Engine → Network permissions**

| Option | Description |
|--------|-------------|
| Default-deny internet | New apps have no internet access until you grant it |
| Per-app internet toggle | Enable/disable internet per app without revoking other permissions |
| Background network block | Prevent apps from using the network when not in the foreground |
| Identifier spoofing | Randomise MAC, Android ID, and Build fingerprint per app |

### Auto-revoke

**Settings → Circle OS → Privacy Engine → Auto-revoke**

| Option | Description |
|--------|-------------|
| Revoke unused permissions | Revoke camera/mic/location from apps unused for N days |
| Revoke after N days | 7 / 14 / 30 / 60 / Never |
| Notify on revoke | Show a notification when a permission is auto-revoked |

---

## Butler AI

**Settings → Circle OS → Butler AI**

| Option | Description |
|--------|-------------|
| Enable Butler | Toggle the on-device AI assistant |
| Model size | Auto (based on RAM) / 0.5B / 1B / 3B / 7B / 14B |
| Personality | Neutral / Professional / Friendly / Technical |
| Voice input | Enable microphone for voice commands |
| Context depth | How many recent messages Butler can reference (1–20) |
| Butler suggestions | Show proactive suggestions based on usage patterns |

Butler runs entirely on-device. Disabling internet for Butler's process has no effect — it doesn't use the network.

---

## Titanium Wallet

**Settings → Circle OS → Titanium Wallet**

| Option | Description |
|--------|-------------|
| Enable NFC payments | Toggle tap-to-pay |
| Require PIN for payments | Always / Amounts over ₷50 / Never |
| Payment limit | Maximum single payment without additional auth |
| Auto-settle | Automatically settle pending transactions when internet is available |
| Transaction history | View all payments and receipts |

---

## Mesh Network

**Settings → Circle OS → Mesh Network**

| Option | Description |
|--------|-------------|
| Enable mesh | Join the local mesh network |
| BLE discovery | Advertise presence over Bluetooth LE |
| WiFi Direct relay | Act as a relay node for other peers |
| Store-and-forward | Hold messages for offline peers (up to 7 days) |
| Max relay hops | 3 / 5 / 7 / Unlimited |
| Show mesh peers | Display nearby peers in the notification shade |

---

## File DMZ

**Settings → Circle OS → File DMZ**

| Option | Description |
|--------|-------------|
| Enable File DMZ | Sanitise all inbound files before access |
| Auto-quarantine | Move suspicious files to quarantine automatically |
| Notify on quarantine | Show notification when a file is quarantined |
| Quarantine retention | 7 / 14 / 30 / 60 days before auto-delete |
| View quarantine | Browse quarantined files and restore or delete |

---

## Modes

**Settings → Circle OS → Modes**

| Option | Description |
|--------|-------------|
| Current mode | Active mode tile (tap to change) |
| Auto-detect mode | Let Butler suggest mode based on context |
| Mode schedule | Set modes to activate at specific times |
| Mode shortcuts | Add mode tiles to the quick settings panel |

See [Modes](features/modes.md) for the full list of available modes.

---

## OTA Updates

**Settings → Circle OS → Updates**

| Option | Description |
|--------|-------------|
| Update channel | Stable / Beta / Nightly |
| Auto-download | Download updates automatically when on WiFi |
| Mesh updates | Accept update chunks from nearby mesh peers |
| Check for updates | Manual update check |
| Update history | View past updates |

---

## Privacy Dashboard

**Settings → Circle OS → Privacy Dashboard**

A live view of all privacy events in the last 24 hours:

- Network access attempts (blocked and allowed)
- Permission uses (camera, mic, location, contacts)
- Identifier access attempts
- File DMZ events
- Auto-revoked permissions

Tap any event to see which app triggered it and what action Circle OS took.

---

## Analytics & Diagnostics

**Settings → Circle OS → Analytics**

| Option | Description |
|--------|-------------|
| Share anonymised analytics | Help improve Circle OS (opt-in, off by default) |
| Bug reports | Enable automatic crash reporting |
| Export diagnostics | Save a ZIP of logs for support |

All analytics are processed on-device. If you enable sharing, a weekly anonymised summary (no device ID, no app names) is sent to the Circle OS analytics endpoint. You can review exactly what will be sent before opting in.
