# Privacy

Circle OS's privacy engine runs silently in the background, protecting you without any configuration required.

---

## What's protected by default

| Protection | How it works |
|------------|-------------|
| **No Google** | Google Play Services are not installed. No Google tracking. |
| **Default-deny internet** | New apps have no internet access until you grant it. |
| **Identifier spoofing** | Advertising IDs, device IDs, and serial numbers are faked per-app. |
| **Permission auto-revoke** | Permissions unused for 7 days are automatically revoked. |
| **File DMZ** | Every incoming file is sanitised before you can open it. |
| **Clipboard protection** | Apps can't silently read your clipboard. |
| **Notification privacy** | Lock screen notifications hide sensitive content. |

---

## Network Permissions

By default, every app has no internet access. To grant access:

**Circle Settings → Privacy → Network Permissions → [App] → Allow**

Or from the notification when an app requests internet:

1. Tap the notification.
2. Choose **Allow once**, **Allow always**, or **Deny**.

---

## Privacy Dashboard

View your privacy summary in **Circle Settings → Privacy**:

- **Permissions denied:** How many permission requests have been blocked
- **Identifiers faked:** How many tracker IDs have been spoofed
- **Network grants:** Which apps have internet access

---

## Changing permissions

**Circle Settings → Privacy → Permission Manager**

Here you can:
- See every app's permissions
- Revoke any permission at any time
- Set auto-revoke schedules per app

---

## File DMZ

When you receive a file (via mesh, downloads, or share), it goes through the DMZ:

1. Quarantined — you can't open it yet
2. Scanned for threats
3. Sanitised (CDR — Content Disarm & Reconstruction)
4. Released to your Downloads folder — clean

This happens automatically in 1–3 seconds for most files.

---

## Privacy modes

Privacy behaviour changes by [Personality Mode](modes.md):

| Mode | Privacy level |
|------|--------------|
| Standard | High (default-deny + spoofing) |
| Private | Maximum (stricter deny + no history) |
| Work | High (same as Standard) |
| Sleep | High + screen off protections |
