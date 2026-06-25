# SteamOS → Circle OS — Audit & Pattern-Port Lessons

> What to learn from SteamOS (esp. 3.8/3.9, mid-2026) and how to bring it to Circle OS **licence-clean**.
> Compiled 2026-06-25. IDs `SOS-xx` are stable. Pairs with `CircleOS_WP-Inspired_Backlog.md`.

## Method & scope
- Architecture-level audit from Valve's **public** repos + reputable technical write-ups (sources at the bottom).
- This is a **study-don't-copy** exercise. SteamOS is a **Linux desktop stack**; Circle OS is **Android (AOSP)** — so most of this is **pattern-port** (read theirs → write fresh under Apache 2.0 in our repo), per the standing licence rule. A few pieces (the compatibility layer) are genuinely **integratable** — flagged where so.
- Before implementing any single mechanism, do a deeper line-level read of that component. This doc gives the decisions and the route, not the final code.

## Licence discipline (the rule, restated)
- **Permissive (MIT/BSD/Apache/zlib)** → may vendor/integrate.
- **Copyleft (GPL/LGPL)** → don't pull into anything we want to keep ours; LGPL is OK only as a *separable, dynamically-linked* component.
- **Proprietary (Steam client)** → behaviour-only; never source.
- **Always verify each repo's licence before bundling.**

---

## A · Architecture to steal (pattern-port)

### SOS-A1 · Atomic A/B updates — "you cannot brick it"
- **What SteamOS does:** read-only root image. `steamos-update` → checks an update channel → server returns a signed **RAUC** bundle → `casync` downloads only the *changed chunks* → writes them to the **inactive** root partition → syncs `/var` → flips the bootloader to the new slot. A bad update? Reboot falls back to the previous known-good image.
- **Licence:** RAUC/casync are LGPL; not vendored anyway (Linux).
- **Circle OS (AOSP):** **this is already built into Android** — A/B "seamless" updates + `update_engine` + verified boot (dm-verity) + slot rollback. The single biggest reliability win in SteamOS is a *free* AOSP capability; we just have to wire it properly: ship a **signed A/B delta** OTA (not a full-image flash), with rollback on boot failure.
- **Maps to:** build tasks **#10** (OTA payload), **#15** (OTA pipeline). The "download only changed chunks" = AOSP streaming/delta OTA.

### SOS-A2 · One image, many devices
- **What SteamOS does:** one base ("holo"), with per-device quirks handled in *layers* — kernel handheld patches (TDP control, fan curves, AMD P-State, sleep-resume), Gamescope auto-detecting display orientation/VRR per device, per-device firmware folded in (e.g. Legion Go 2). **They never fork the OS per device.** 3.8 spread this across ROG Ally, Legion Go, MSI Claw, OneXPlayer, GPD, Anbernic, OrangePi.
- **Circle OS (AOSP):** this is **literally what GSI + Treble/HAL is for** — one system image, per-device vendor blobs + a per-device "quirks" overlay. Lesson: handle every device difference in the vendor/HAL/overlay layer, **never** in the system image. Note: SteamOS only covers AMD x86 handhelds; our reach (any ARM Android handset, old ones included) is *broader*, so invest early in a clean device-overlay system.
- **Maps to:** **#9** (device targets), **#11/#12** (install paths incl. old/locked phones). Validates the "exclude no handset" thesis.

### SOS-A3 · Single-app "session" / console front-end
- **What SteamOS does:** **Gamescope** (a tiny BSD-2 compositor) runs the Big Picture UI as one foreground "session" — the console-like experience.
- **Circle OS (AOSP):** pattern-port the *idea* onto SurfaceFlinger — CircleLauncher as a focused, single-surface "console home," plus a kiosk/lock-task mode for a TV/dock experience. (Ties to WP-42 Continuum.) Don't vendor Gamescope (Wayland); copy the concept.

### SOS-A4 · Immutable root + writable overlay
- **What SteamOS does:** root is read-only; `/etc` is a writable overlay stored under `/var`; root edits are lost on update — predictable and clean.
- **Circle OS (AOSP):** Android already does this (read-only `/system` + dm-verity, writable `/data`). The discipline: keep `/system` pristine and verifiable, **never** ship a writable-system hack. Reinforces the privacy-first, tamper-evident base.

---

## B · What makes it *mean something* (the substance layer)

SteamOS means something because it gives you a real console on open hardware and frees you from Windows. Circle OS's meaning is **stronger** and is the actual differentiator — lead with it, not the UI.

- **SOS-B1 · Real privacy** — communication blind to us forever; money encrypted, lawmaker-only. No mainstream OS makes this promise.
- **SOS-B2 · Ownership / no lock-in** — device-rooted portable identity (SDPKT), your wallet, your data.
- **SOS-B3 · Runs on ANY handset, including old ones** — dual-boot via DSU. Inclusion vs planned obsolescence. (SteamOS *drops* old/non-AMD hardware; we include everyone.)
- **SOS-B4 · AetherNet mesh** — works when the internet doesn't; every device a node. Nobody else has this.
- **SOS-B5 · Financial inclusion** — wallet/payments for the underserved, baked into the OS.
- **SOS-B6 · Uncensorable distribution** — free, BitTorrent, can't be taken down (see Part C).
- **The lesson:** SteamOS won hearts by *meaning* "freedom from Windows." Circle OS means "freedom from surveillance + an ecosystem you own, on any phone, even offline." That's the headline — the UI is just how it feels.

---

## C · Distribution (off-the-shelf + BitTorrent)

### SOS-C1 · One-file, flash-and-go image
- Like SteamOS's recovery image you flash onto any AMD handheld. Circle OS = the GSI, one file, flash-and-go, **plus** one-tap DSU dual-boot.
- **Maps to:** **#11** (one-tap DSU), **#13** (install docs).

### SOS-C2 · BitTorrent as the primary channel
- For a multi-GB OS image, BitTorrent is ideal: **zero hosting cost, scales with popularity** (more downloaders = faster), **censorship-resistant**, decentralised.
- Use a **torrent + web seed** (an HTTP mirror seeded into the swarm) so downloads always work even with few peers.
- **Maps to:** **#14** (host the release image).

### SOS-C3 · Trust = cryptographic verification, not the pipe ⭐ (the key insight)
- You can't trust a torrent's path, so the **artifact must verify itself** — exactly SteamOS's RAUC signature model: the image is signed; a tampered one won't install.
- Circle OS gets this from **Android verified boot + signed OTA**: sign the image/OTA with the release key; publish **GPG-signed SHA-256 checksums** on multiple independent channels (site, GitHub release). A tampered torrented image won't boot or install.
- **Result: decentralised distribution + self-verifying images = safe.** This is what makes "release it on BitTorrent" responsible rather than reckless.

### SOS-C4 · Update channels
- SteamOS has stable/beta/main channels. Circle OS: stable/beta OTA channels (ties to WP-60 dev-preview, task **#15**).

---

## D · SteamOS compatibility (the "don't restrict users" track)

### SOS-D1 · The honest reality of Steam-on-Android (2026)
- **Winlator / Steamlator** = Android apps that run Windows x86_64 games via **Proton + Box86/Box64** (or Arm64EC via **FEXCore**). Many Steam titles run "like on a Linux PC through Proton."
- **Hardware-gated:** Snapdragon 870+ minimum; 8 Gen 2/3/Elite recommended; 8 GB RAM min, 12 GB+ for AAA.
- **Performance:** indie/older titles run well; AAA = frame drops, heavy tweaking, battery drain. Great "bring your library," aspirational for AAA.

### SOS-D2 · The OS-level advantage ⭐
- A standalone app is sandboxed; **we own the OS**, so Circle OS can do what Winlator-as-an-app can't: ship the right GPU drivers, pre-tune per-device TDP, integrate controller support (already in our multi-device work), and wire in **Direct Android Compositing (DAC)** — a 2026 Vulkan present path that routes frames **DXVK → SurfaceFlinger directly, skipping X11**. Integrated at OS level, our compatibility layer can be meaningfully faster than the app version.

### SOS-D3 · Integratable, not just pattern-port
- The stack — Wine (LGPL-2.1), DXVK (zlib), Box64/Box86 (MIT), FEXCore (MIT), Proton (mostly BSD/MIT) — is **largely permissive/LGPL**, so it can be **bundled** as a separable component ("Circle Play"), not merely studied. **Verify each repo's licence before shipping.**
- Position: "**Sign into Steam, bring your library**" = a loud "you're not restricted" signal, and a phone-that-plays-your-PC-games pitch that *is* the "Steam for Android" story. Scope it honestly as an ARM-performance-bound, best-effort, hardware-gated track.

---

## Priority map (what to do with this)
| Lesson | Effort | Existing task it feeds |
|---|---|---|
| SOS-A1 atomic A/B updates | ✅ mostly AOSP-native | #10, #15 |
| SOS-A2 one-image/many-devices | ⭐ already our GSI model | #9, #11, #12 |
| SOS-C2/C3 BitTorrent + signed images | 🛠 build | #14 |
| SOS-A3 console session | 🛠 build | WP-42 |
| SOS-D2/D3 "Circle Play" compat layer | 🚀 own track | (new) |

**Single biggest takeaway:** the reliability crown-jewel (can't-brick atomic updates) is **already in AOSP** — wire it, don't build it. The differentiator isn't matching SteamOS's plumbing; it's **Part B (meaning)** + the **compatibility layer** that says "you keep everything you already own."

## Sources
- Atomic update internals: https://iliana.fyi/blog/build-your-own-steamos-updates/ · https://blogs.igalia.com/berto/2025/02/05/keeping-your-system-wide-configuration-files-intact-after-updating-steamos/ · https://deepwiki.com/pattontim/steamos-customizations/5.1-read-only-filesystem-control
- Multi-device / 3.8: https://www.gamingonlinux.com/2026/06/steamos-3-8-is-out-with-initial-steam-machine-support-desktop-mode-upgrades-new-graphics-drivers/ · https://www.pcgamer.com/hardware/big-update-to-steamos-improves-support-for-non-valve-handhelds-newer-platforms-discrete-gpus-and-steam-machine/
- Steam-on-Android: https://github.com/slaker222/Steamlator · https://winlator.dev/play-games/ · https://news-nest.com/2026/04/02/playing-steam-games-on-android-a-2026-reality-check/
- Open-source status: https://en.wikipedia.org/wiki/SteamOS
