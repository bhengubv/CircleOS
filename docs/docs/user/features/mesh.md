# Mesh Network

Circle OS devices form a mesh network. When the internet goes down, messages relay phone-to-phone until they arrive.

---

## How it works

Every Circle OS phone is a **node**. When you send a message:

1. Your phone tries to deliver it directly.
2. If the recipient isn't reachable, nearby Circle OS devices relay the message.
3. The message hops up to 5 devices before giving up.
4. Once any device has internet access, queued messages are delivered.

This is called **store-and-forward** messaging.

---

## Mesh status

Check your mesh status in **Circle Settings → Mesh**:

- **Active peers:** Number of Circle OS devices nearby
- **Transport:** What's being used (WiFi Direct / Bluetooth LE / mDNS)
- **Queued messages:** Messages waiting to be delivered

---

## Messaging on mesh

Use any app that supports mesh delivery. Recommended:

- **Briar** — fully mesh-native, works without internet
- **Meshtastic integration** — long-range (requires LoRa hardware)
- **Circle Messenger** (coming in v1.1)

---

## OTA updates via mesh

If a nearby Circle OS device has already downloaded an update, your phone can get it directly from them — for free, without mobile data.

---

## Range

| Transport | Range |
|-----------|-------|
| WiFi Direct | ~100m |
| Bluetooth LE | ~30m |
| mDNS (LAN) | Same network |

---

## Privacy on mesh

All mesh traffic is end-to-end encrypted using Ed25519 keys. Relay nodes can forward messages but cannot read them.

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| No peers found | Enable both WiFi and Bluetooth |
| Messages not delivering | Check TTL: message may have expired (5 hops) |
| Mesh draining battery | Settings → Mesh → Scan Interval → set to "Passive" |
