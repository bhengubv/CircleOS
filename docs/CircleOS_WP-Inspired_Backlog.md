# Circle OS — Windows Phone–Inspired Feature Backlog

> 80 positive elements distilled from Windows Phone / Windows 10 Mobile, each mapped to a Circle OS route.
> Compiled 2026-06-25. IDs `WP-01`…`WP-80` are **stable** — reference them in commits, branches and PRs.

## How to use
- Tick `- [x]` as each lands; keep the ID.
- **Fit** = effort/leverage verdict. **How** = the Circle OS route.

## Fit legend
- ⭐ **Have an analog** in the ecosystem — mostly wiring/branding
- ✅ **Native to AOSP/Android** — low effort (launcher or settings)
- 🛠 **Build it** — feasible, real component work
- 🚀 **Ambitious** — bigger lift, longer-term, still doable

## Tally
- **Total: 80** — ⭐ ~17 · ✅ ~33 · 🛠 ~22 · 🚀 ~6
- ~60 of 80 are low-to-moderate effort: Circle OS is Android underneath **and** the analogs already exist
  (CircleAI / "B!", the Bruh & txtMe hubs, .NET MAUI cross-platform, AetherNet, CircleLauncher,
  SocialMediaAPI, CircleUp, SDPKT).

## Suggested first cluster (most distinctive, leans on assets you already own)
- **Live Tiles** (`WP-10`…`WP-13`) + **Hubs** (`WP-18`…`WP-21`) + **B! Notebook** (`WP-27`).
  These are what make Circle OS feel like more than "another Android skin."

---

## A · Design language (Metro)
- [ ] **WP-01** Flat, content-first visual style — ✅ — CircleLauncher + system theme
- [ ] **WP-02** Typography-led UI (big bold headers) — ✅ — Theme typography overrides
- [ ] **WP-03** Choreographed motion / transitions — ✅ — Launcher + system animations
- [ ] **WP-04** Panorama (wide horizontal canvas) navigation — 🛠 — Custom launcher surface
- [ ] **WP-05** Pivot (swipe between tab sections) — ✅ — Standard Android tabs / pager
- [ ] **WP-06** System-wide true-black dark mode — ✅ — AOSP dark theme (great on OLED)
- [ ] **WP-07** System-wide accent colour — ✅ — Material theming, **locked to #2196F3 palette** (no free-for-all, no orange)
- [ ] **WP-08** One design across OS + all apps — 🛠 — Publish DESIGN_GUIDELINES.md as a Circle design system
- [ ] **WP-09** Distinctive, recognisable identity — 🛠 — Brand launcher / boot / theme

## B · Live Tiles
- [ ] **WP-10** Live, self-updating home tiles — 🛠 — CircleLauncher "tile" widgets (Android widgets are the substrate)
- [ ] **WP-11** Resizable tiles (S / M / W) — ✅ — Android resizable widgets
- [ ] **WP-12** Pin anything (person / playlist / site / app-section) — ✅ — Pinned shortcuts + deep links
- [ ] **WP-13** Glanceable info without opening apps — ⭐ — Fed by Bruh / txtMe hubs + widgets

## C · Speed on cheap / old hardware
- [ ] **WP-14** Smooth on old / 512 MB-class phones — ⭐ — The "exclude no handset" goal: lean GSI, dual-boot
- [ ] **WP-15** Guaranteed UI responsiveness — 🛠 — Low-RAM AOSP flags, zram, render priorities
- [ ] **WP-16** Stays fast over time — ✅ — No bloatware (privacy-lean by design)
- [ ] **WP-17** Battery efficiency — ✅ — AOSP power profiles + tuning

## D · Hubs (organise by person / type, not app)
- [ ] **WP-18** People Hub (one card per person) — ⭐ — Bruh / txtMe + unified contact view
- [ ] **WP-19** "Me" tile (post to all socials, see replies) — ⭐ — Front-end for your designed **SocialMediaAPI**
- [ ] **WP-20** Rooms / Groups (shared calendar / chat / album) — ⭐ — txtMe groups + shared album
- [ ] **WP-21** Photos Hub (local + cloud + social gallery) — 🛠 — Circle gallery aggregator

## E · Productivity
- [ ] **WP-22** Built-in notes / office — ⭐ — **CircleUp** for notes; bundle / Web for docs
- [ ] **WP-23** Cloud file sync / backup — 🛠 — A Circle cloud, **client-encrypted** (honours the "comms blind to us" rule)
- [ ] **WP-24** Great email / calendar (combined inbox) — 🛠 — Bundle a strong mail / cal app
- [ ] **WP-25** Identity / achievements tie-in — ⭐ — Hang off SDPKT identity

## F · Cortana → CircleAI / "B!"
- [ ] **WP-26** Capable on-device voice assistant — ⭐ — **"Hey B" already is this**
- [ ] **WP-27** Transparent "Notebook" (see / edit what it knows) — 🛠 — B! privacy notebook — **strong fit with your privacy ethos**, real differentiator
- [ ] **WP-28** Proactive commute / context alerts — 🛠 — B! proactive layer + DataAcuity
- [ ] **WP-29** Place-based reminders — ✅ — Geofencing + B!
- [ ] **WP-30** Person-based reminders — 🛠 — B! + comms hooks
- [ ] **WP-31** Quiet Hours w/ inner-circle breakthrough — ✅ — Android DND + favourites, branded
- [ ] **WP-32** Assistant personality / charm — 🛠 — B! persona design

## G · Keyboard
- [ ] **WP-33** Excellent predictive + swipe typing — 🛠 — Bundle / enhance a keyboard; **on-device prediction via CircleAI** (keeps typing private)

## H · Camera & imaging
- [ ] **WP-34** Manual "pro" controls — ✅ — Camera2 API + a good camera app
- [ ] **WP-35** Optical stabilisation / low-light pipeline — 🛠 — HW-dependent; software HDR doable
- [ ] **WP-36** High-res / full-sensor capture — ✅ — Expose full sensor (HW-dependent)
- [ ] **WP-37** Creative modes (living photo / refocus / pano / story) — 🛠 — Camera app features

## I · Maps
- [ ] **WP-38** Free worldwide **offline** maps — 🛠 — **Via DataAcuity only** (your map rule) — needs offline tiles from them
- [ ] **WP-39** Turn-by-turn voice nav — 🛠 — DataAcuity
- [ ] **WP-40** Transit directions — 🛠 — DataAcuity
- [ ] **WP-41** AR "point camera to see places" — 🚀 — ARCore + DataAcuity overlay

## J · Continuum (phone-as-PC)
- [ ] **WP-42** Plug into a monitor → desktop mode — 🛠 — **AOSP 15 has desktop / freeform windowing** — enable + polish
- [ ] **WP-43** Phone as touchpad / 2nd screen while docked — 🚀 — Extra layer on the above

## K · One-app-everywhere
- [ ] **WP-44** One app runs phone / PC / tablet / TV — ⭐ — **You're .NET MAUI + Blazor — already lived**
- [ ] **WP-45** Buy / own once, use everywhere — ⭐ — Entitlements via SDPKT wallet

## L · Security & manageability
- [ ] **WP-46** Strong app sandboxing + capability perms — ✅ — Android already; harden (privacy-first)
- [ ] **WP-47** Device encryption — ✅ — AOSP file-based encryption on by default
- [ ] **WP-48** Low-malware locked-down posture — ✅ — Curated store, no Play bloat
- [ ] **WP-49** Enterprise management (MDM) — 🚀 — Android Enterprise APIs, later

## M · Family / data / "care" features
- [ ] **WP-50** Kid's Corner (sandboxed child mode) — ✅ — AOSP multi-user / restricted profile → "Circle Kids"
- [ ] **WP-51** Data Sense (track + compress data) — ✅ — Data Saver + **AetherNet compression** angle
- [ ] **WP-52** Battery Saver — ✅ — AOSP
- [ ] **WP-53** Storage Sense (manage space) — ✅ — AOSP storage manager
- [ ] **WP-54** Glance / always-on display — 🛠 — AOD (OLED / HW-dependent)
- [ ] **WP-55** Find My Phone (ring / lock / locate / wipe) — ⭐ — **Build on AetherNet — locate even offline via mesh, no Google** (killer angle)
- [ ] **WP-56** Double-tap to wake — ✅ — AOSP / HW
- [ ] **WP-57** "Tap and send" quick share — ✅ — Quick Share / NFC — or ⭐ **AetherNet share**

## N · Consistency & updates
- [ ] **WP-58** Consistent on-screen nav — ✅ — AOSP nav
- [ ] **WP-59** Low fragmentation / predictable — ⭐ — Circle OS *is* one consistent GSI image
- [ ] **WP-60** Developer-preview early-update channel — 🛠 — Your OTA beta channel
- [ ] **WP-61** Fast, direct updates (no carrier gating) — ⭐ — You own the OTA pipeline (build tasks #10 / #15)

## O · Developer-friendly
- [ ] **WP-62** Familiar C# / .NET / XAML tooling — ⭐ — **You're already a .NET shop** — a Circle SDK in .NET is natural
- [ ] **WP-63** Free tools + emulator — 🛠 — Ship a CircleOS SDK + emulator image
- [ ] **WP-64** Design guidelines for consistent apps — ⭐ — Publish DESIGN_GUIDELINES.md for 3rd parties

## P · Intangibles
- [ ] **WP-65** A real "third choice" beyond iOS / Android — ⭐ — Circle OS's whole reason to exist
- [ ] **WP-66** Distinctive, human identity / marketing — 🛠 — Brand / narrative work
- [ ] **WP-67** Colourful, characterful identity — 🛠 — Theme / brand within the #2196F3 palette

## Q · Deeper tier (smaller touches)
- [ ] **WP-68** Project My Screen (mirror to PC) — ✅ — Cast / screen mirror
- [ ] **WP-69** Built-in podcasts — ✅ — App
- [ ] **WP-70** Per-app background limits — ✅ — AOSP battery controls
- [ ] **WP-71** Temp-file cleanup — ✅ — AOSP storage manager
- [ ] **WP-72** Auto-connect known Wi-Fi — 🛠 — Privacy-careful version
- [ ] **WP-73** NFC tap-to-pair — ✅ — AOSP NFC
- [ ] **WP-74** Glance / AOD customisation — 🛠 — What shows on always-on
- [ ] **WP-75** Music subscription tie-in — 🚀 — Optional
- [ ] **WP-76** Accent applied to keyboard / system surfaces — ✅ — Theme propagation
- [ ] **WP-77** Fast app-switch / resume cards — ✅ — AOSP recents
- [ ] **WP-78** Alphabetical jump in app list — ✅ — Launcher feature
- [ ] **WP-79** Clean "reading view" web — ✅ — Browser feature
- [ ] **WP-80** One-handed, bottom-anchored UI — ✅ — Design choice in CircleLauncher

---

### Notes
- **Map work (`WP-38`…`WP-41`)** is gated on DataAcuity exposing offline tiles / nav — confirm capability before committing.
- **Privacy guardrails:** anything touching comms or cloud (`WP-23`, `WP-30`, `WP-33`) must stay client-encrypted / on-device per the "communication blind to us, forever" ruling.
- **Theming (`WP-07`, `WP-67`, `WP-76`)** stays inside the brand palette `#2196F3 / #2c3e50 / #ffffff`.
