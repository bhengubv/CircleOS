# Circle OS — One Codebase, Every Device
*Plain-language design spec. Complete — nothing deferred.*
*This is the **cross-device layer**. For the operating system itself, it points to the 23 chapters rather than repeating them.*

## What this is, and how it fits the rest of the spec
The 23 chapters describe **Circle OS the phone system** — an Android-based system you flash onto a phone. This document describes the **one codebase that carries the Circle experience onto every kind of device** — phone, tablet, watch, TV, laptop, desktop, and cheap or old hardware — and fits itself to each one at install.

The one codebase is the **Core + Faces** (below). It is the same on every device. The only thing that changes is what sits *beneath* it:

- On a phone we can flash → it sits on the full Circle OS (the 23 chapters). Deepest control and privacy.
- On anything else → it runs **on top** of whatever system is already there, as a guest.

Either way the Core and the apps are identical. That is what "one codebase, every device" means, concretely.

**This is not hypothetical — the pattern already runs in this repo:**
- `aether-protocol` is one logic core carried across 8 languages, kept identical by a shared test oracle, with a **C build aimed at microcontrollers** (ESP32 / nRF52).
- `aether-protocol/samples/AetherNet.Sample` is a **.NET 10 app with one shared UI codebase, thin per-device heads, and a form-factor seam that already reports Phone / Tablet / Desktop / TV / Watch**, with hardware handled by swappable per-platform adapters.

This spec generalises that proven pattern into Circle's foundation. Where a section says "anchor:", that is the existing code it is built on — reuse, not invention.

---

## 1. The reach — every device
Circle runs on anything with a chip: phone, tablet, watch, TV, laptop, desktop, set-top box, cheap no-name handset, old hardware, down to a bare sensor. The rest of this document is *how* one codebase covers all of them without becoming a different program on each.

## 2. The shape — Core, Faces, Adapters
- **The Core** — written once. The brain: identity, privacy rules, talking to other devices (including with no internet), storage, and the engine that runs apps. It knows nothing about any specific device.
- **Faces** — one per kind of device. A face is only the front: how things are laid out and how you control them.
- **Adapters** — the small pieces that connect the Core to one device's real hardware (screen, wireless, camera, sensors, secure storage).

A new kind of device = a new face plus a few adapters. Never a new Circle.

*Anchor:* `AetherNet.Sample.Shared` is the single shared codebase (all pages + logic); the MAUI head and the Web head both consume it "with no per-head re-wiring". Every hardware need is an interface in the shared project — `IAudioIo`, `IVideoIo`, `IRadioMesh`, `ITapShare`, `ISecretVault`, `IAppTheme`, … — with native versions under `Platforms/Android/` (`AndroidAudioIo`, `AndroidKeystoreVault`, …) and browser versions in the shared project (`WebVideoIo`, `NullRadioMesh`). That is exactly Core + Faces + Adapters.

## 3. The Faces — and how one is defined
The set today:
- **Phone** — full screen, touch.
- **Tablet** — bigger, touch, room for two panes.
- **Watch** — tiny, quick glances, one thing at a time.
- **TV** — big screen, remote, lean-back, large text.
- **Desktop / laptop** — resizable windows, keyboard, mouse, many things at once.

A face is defined by two things: a **layout** and an **input style**. The code learns which face it is on through one seam that answers "what am I running on?".

*Anchor:* `AetherNet.Sample/Services/FormFactor.cs` implements `IFormFactor` via `DeviceInfo.Idiom`, already returning Phone / Tablet / Desktop / TV / Watch; the Web head has its own answer. This is the hook the whole thing hangs on.

## 4. Two ways onto a device
- **Underneath (full install).** Where the maker allows it, the device runs the full Circle OS (the 23 chapters) and the Core + Faces is its native experience. Best control, deepest privacy, longest battery. *(The install/boot mechanics are ch06.)*
- **On top (a guest).** Where we cannot replace the system, the Core + Faces runs *inside* the existing one — like opening a private space on the device. Nothing unlocked, nothing erased.

**The rule:** can we get onto the device without the maker's permission? Yes → underneath. No → on top. The one codebase is identical either way; only its host changes. On-top is the mechanism that makes "any device" real — if we cannot go under, we go on top, so nothing is out of reach.

**Honest note:** pre-installing Circle on *someone else's* hardware before it is sold needs that maker's agreement. That is a business conversation, not a technical block — the technology is ready either way.

## 5. The self-adapting installer
One installer for everything. At install it:
1. Looks at the device — chip, screen, memory, inputs, wireless, and whether we are allowed underneath.
2. Decides which **face** and which **hosting mode** (underneath or on top).
3. Lays down only the parts that fit — the full build where there is power, a trimmed build on a watch, the bare minimum on a cheap chip.

Same source every time; the installer decides how much of it to use and how to host it. It reads the device against the support tiers in ch05 and, for the underneath case, hands off to the boot flow in ch06.

## 6. Scaling down — full, trimmed, companion
The Core is not one fixed size. It is the same source with more or less switched on:
- **Full** — laptops, desktops, phones, tablets, TVs.
- **Trimmed** — watches and weak devices: the essentials only.
- **Companion** — the smallest chips that cannot run the real Core get a tiny build instead. It cannot show the full experience; it *can* carry your identity and join the network, so even a cheap sensor is part of your Circle.

*Anchor:* the `aether-protocol` **C port** is exactly this companion tier — fixed-size 44-byte packet header, pre-allocated peer tables (~33 KB for 256 peers), libsodium, targeting ESP32 / nRF52. **Honest limit:** its real on-device radio is not yet proven (it runs against an in-process simulation today); that verification is part of the build order, not assumed done.

## 7. Apps across faces
- An app never says "put this button here." It says what it is *made of* — its screens, its actions, its data — and what it needs (camera, keyboard, big screen).
- The Core arranges those pieces to fit the face: one column on a phone, a glance on a watch, a grid on a TV, windows on a desktop.
- Shared building blocks already know how to look right on each face.
- If a device lacks something an app wants, that part quietly folds away — the app still runs.
- The app's data lives in the Core, not the screen — so the same app is a window on a laptop and full-screen on a phone.

*Anchor:* the shared Blazor components in `AetherNet.Sample.Shared` render in both the MAUI head and the Web head; capability seams (e.g. `IVoiceCodec`, `IMeshLink`) are "filled with a phone's answers" per head. This **extends** the single-form-factor store and dev guide (ch15, ch16) to write-once-across-faces.

## 8. Adding a new face / form factor
Supporting a new *kind* of device is a known, repeatable job — not a rewrite:
1. **Pick the face** it uses, or define a new one if it is a genuinely new shape.
2. **Write the adapters** — the small pieces that connect the Core to this device's hardware. This is the only new code.
3. **Teach the installer** what this device is and can do, so assess-and-fit places the right build.
4. **Check it** against a fixed list — boots, screen right, input works, network works, handoff works — before it counts as supported.

The Core and the apps do not change. *(Adding a new **phone** — device tree, kernel, drivers — is a different, existing job: ch17. This section is about a new **form factor**.)*

## 9. Handoff — your work follows you, across devices and offline
What moves between devices is your **place**, not the screen.
- As you work, the app keeps a small note of where you are — which screen, which item, how far in. The meaning, not the picture. It is stamped with your identity.
- That note is tied to **you**, so it reaches your other devices.
- The device you pick up rebuilds that exact spot in its own face — full screen on the phone becomes a window on the laptop.
- Starts either way: you send it ("continue on the TV"), or a nearby device offers it ("pick up where you left off").
- **With no internet:** two of your devices near each other pass the note straight across; the receiver checks the stamp is really yours, then rebuilds the spot.

This **extends** ch09, which today covers only same-device Android↔Circle migration. *Anchor:* the store-and-forward machinery already exists in `aether-protocol` (`sync`, `dtn` corpora) — carry-now, deliver-later is a solved piece to build on.

## 10. Notifications across faces
Alerts reach you on whatever face you are on, and travel over the device-to-device network when there is no internet — so a phone with signal can hand a notification to your watch that has none. The delivery channel is the mesh (ch18); this section is only about showing the alert correctly per face.

## 11. How we prove it — one behaviour everywhere
The hard part of one-codebase-many-targets is proving the targets actually behave the same. We reuse the pattern that already works here:
- **One source of truth** produces the canonical result; every target asserts it matches — exactly (byte-for-byte) where possible.
- **Behaviour-match where a platform forces it.** Example already handled in the repo: Apple's crypto randomises signatures, so that one target *verifies* the signature instead of byte-matching it. Plan for these exceptions up front.
- **Each face is tested** through the form-factor seam, so "works on phone" is not assumed to mean "works on TV."

*Anchor:* `aether-protocol/fixtures/**` and the cross-language runners are exactly this oracle-and-assert harness. This complements the testing rules in ch16 and the P30-is-the-benchmark rule for on-device sign-off.

## 12. The decisions — decided
1. **What the Core is written in.** C# / .NET for the full and trimmed Core — the language `AetherNet.Sample` is already built in. A **C companion** for microcontrollers — the language `aether-protocol`'s C port already uses. Two languages, one Core design. This is the repo's current, working choice, not a new bet.
2. **Underneath vs on top.** Underneath wherever the maker allows it; on top everywhere else. "Any device" must never depend on a maker saying yes.
3. **The smallest chip we promise.** Anything that can run a small Linux gets the trimmed Core. Below that — bare microcontrollers — gets the companion only: enough to carry your identity and join the network, not the full experience.

## 13. Build order
1. **Core + phone face**, end to end — proves the split. (`AetherNet.Sample` already demonstrates it.)
2. **Desktop / laptop face** — the hardest jump (windows, keyboard, mouse). Do it early so the Core stays honest about big screens, not phone-shaped.
3. **TV and watch faces** — the far ends (remote; tiny glance).
4. **Handoff** — phone ↔ laptop first, then with no internet.
5. **On-top hosting** — so devices we cannot flash are reachable.
6. **The self-adapting installer** — assess-and-fit, once the pieces exist to assemble.
7. **Trimmed Core + companion** — the cheap-chip and old-hardware end, including proving the companion on a real microcontroller radio.

## 14. Everything else — where it already lives
These are already specced. This layer **references** them; it does not repeat them.

| Topic | Where |
|---|---|
| Vision, non-goals | ch01, ch02 |
| Privacy, permissions, dashboard, firewall, malware jail | ch04, ch19, ch20 |
| Security model, device tiers, verified/tamper-proof start | ch03, ch05, ch06 |
| Boot, dual-boot, recovery (the underneath install) | ch06 |
| OS layer stack + Circle system services | ch07 |
| Running Android apps | ch08 |
| Storage, migration, backup & restore, export | ch09 |
| Updates & recovery (tailored per device) | ch10 |
| First-boot setup / onboarding | ch11 |
| Age-adaptive modes & child safety | ch12 |
| Accessibility + languages | ch13 |
| Offline, low-resource, load-shedding, battery | ch14 |
| Circle Store, apps, paying | ch15 |
| Developer guide (building apps + the OS) | ch16 |
| Adding a new **phone** (porting) | ch17 |
| Mesh, device-to-device, relays + relay rewards | ch18 (+ LedgerAPI / SDPKT for tipping) |
| Threat telemetry, community defence | ch21, ch22 |
| Brand & design system (face styling) | ch23 |
| Legal, licensing, data-protection | docs/legal/* |
| Identity anchor (AetherTag / one-device-one-node) | existing identity docs |
| On-device AI (B!) | existing Butler docs |

**Every topic on the agreed map is either a section above or a line in this table. Nothing is deferred and nothing is carved out.**
