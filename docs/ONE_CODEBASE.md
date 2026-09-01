# Circle OS — One Codebase, Every Device
*Plain-language design spec. No jargon. Complete.*

## What this covers
The full design for one codebase that installs and runs on anything with a chip: the goal, the Core and its insides, identity, the faces, adapters, the two ways onto a device, the installer, how apps work, handoff, scaling down to tiny hardware, updates, the rules that keep it one codebase, the build order, and the three decisions — decided. What is *not* covered is listed at the end, on purpose, so nothing here is mistaken for finished when it isn't.

## The goal
One codebase. It installs on anything with a chip — phone, tablet, watch, TV, laptop, desktop, cheap no-name hardware, old stuff. On install it looks at the device, works out what it is, and fits itself to it. Apps are written once and show up right everywhere. Your work follows you from one device to the next. It works even with no internet.

## The shape: one core, many faces
- **The Core** — written once. The brain. Knows nothing about any specific device.
- **Faces** — the front-end, one per kind of device: layout + how you control it.
- **Adapters** — the small piece that plugs the Core into one device's real hardware.

A new kind of device = a new face (and maybe a small adapter). Never a new Circle.

## Inside the Core (written once)
Five parts, all device-blind:
1. **You** — your identity. One "you," not tied to any single device (see *Identity*).
2. **Privacy & safety** — the gatekeeper. Apps get nothing by default; anything they want (location, camera, contacts, the internet) must be granted, and you can see it and take it back any time. Nothing leaves the device unless you allow it.
3. **Talking to other devices** — over the internet when there is one, and directly device-to-device when there isn't. The same channel your apps and handoffs ride on.
4. **Storage** — your stuff, kept on the device, readable across your own devices.
5. **The app engine** — runs apps and arranges each one to fit the current face.

## Identity: the anchor
- Your identity is a private stamp that belongs to **you**, carried by the devices you own.
- A new device joins by proving it's yours: you approve it from a device you already trust. No central sign-up.
- Everything personal hangs off this one identity — your data, your place in an app, your handoffs, your permissions — not off any single device.
- Lose a device and it's just one holder of the stamp: revoke it from another device, and your identity is intact.

## The faces
Same Core, different front:
- **Phone** — full screen, touch.
- **Tablet** — bigger, touch, room for two panes side by side.
- **Watch** — tiny, quick glances, one thing at a time.
- **TV** — big screen, remote, lean-back, large text.
- **Desktop / laptop** — resizable windows, keyboard, mouse, many things at once.

Adding a face is a front-end job, not a rebuild.

## Adapters: meeting the real hardware
The adapter connects the Core to a specific device's screen, wireless, buttons, and sensors. It is the *only* place that knows "this exact hardware." Keep it small; keep everything else in the Core.

## Getting onto a device — two ways
- **Underneath (full install).** Where the maker allows it, Circle becomes the device's system. Best control, deepest privacy, longest battery.
- **On top (a guest).** Where we can't replace the system, Circle runs *inside* the one already there — like opening a private space on the device. Nothing unlocked, nothing erased.
- **The rule:** can we get on without the maker's permission? Yes → underneath. No → on top.
- Same Core both ways — only how it's hosted changes. This is what makes "any device" real: if we can't go under, we go on top, so nothing is out of reach.

## The installer: assess and fit
One installer for everything. On install it:
1. Looks at the device — chip, screen, memory, inputs, wireless, and whether we're allowed underneath.
2. Decides which face, and underneath-or-on-top.
3. Lays down only the parts that fit — full build where there's power, trimmed on a watch, bare minimum on a cheap chip.

Same source every time; the installer decides how much of it to use and how to host it.

## Apps: describe, don't place
- An app never says "put this button here." It says what it's *made of* — screens, actions, data — and what it needs (camera, keyboard, big screen).
- The Core arranges those pieces to fit the face: one column on a phone, a glance on a watch, a grid on a TV, windows on a desktop.
- Shared building blocks (a list, a button) already know how to look right on every face.
- If a device lacks something an app wants, that part quietly folds away — the app still runs.
- The app's data lives in the Core, not the screen — so the same app is a window on a laptop and full-screen on a phone, same stuff underneath.

Write the app once. The Core dresses it for whatever it lands on.

## Handoff: your work follows you
What moves is your **place**, not the screen.
- As you work, the app keeps a small note of where you are — which screen, which item, how far in. The meaning, not the picture. It's stamped with your identity.
- That note is tied to **you**, so it reaches your other devices.
- The device you pick up rebuilds that exact spot in its own face — full screen on the phone becomes a window on the laptop, same place.
- Starts either way: you send it ("continue on the TV"), or a nearby device offers it ("pick up where you left off").
- **With no internet:** two of your devices near each other pass the note straight across, screen to screen — no internet, no middleman. The receiver checks the stamp is really yours, then rebuilds the spot.

## Scaling down to tiny hardware
The Core isn't one fixed size — it's the same source with more or less switched on:
- **Full** — laptops, desktops, phones, tablets, TVs.
- **Trimmed** — watches and weak devices: essentials only.
- **Companion** — the smallest chips that can't run the real Core get a tiny piece of code instead. It can't show the full experience; it *can* carry your identity and join the network, so even a cheap sensor is part of your Circle.

## Updates
- One codebase means one update, tailored on the way down: each device pulls only the update for the parts it actually has.
- Updates travel the same way everything else does — internet, or device-to-device when there's none — so a phone can hand a fresh update to a watch or a chip that's never online.

## Five rules that keep it ONE codebase
1. Nothing device-specific ever goes in the Core.
2. Device differences live only in Faces and Adapters.
3. The Core scales — same source, more or less switched on.
4. Apps describe; they never hard-place anything.
5. Where we can't install underneath, Circle runs on top — so it still reaches the device.

## Build order
1. **Core + phone face** — one device, end to end. Proves the split works.
2. **Desktop / laptop face** — the hardest jump (windows, keyboard, mouse). Do it early so the Core stays honest about big screens, not phone-shaped.
3. **TV and watch faces** — the far ends (remote; tiny glance).
4. **Handoff** — phone ↔ laptop first, then with no internet.
5. **On-top hosting** — so devices we can't replace are reachable.
6. **The self-adapting installer** — assess-and-fit, once the pieces exist to assemble.
7. **Trimmed Core + companion** — the cheap-chip and old-hardware end.

## The three decisions — decided
1. **What the Core is written in.** One main language that turns into small, fast programs and runs on everything from laptops down to small devices — the house stack (C# / .NET) for the full and trimmed Core. The smallest chips get the **companion**, written in a lower-level language (C or Rust) that fits where the main one can't. Two languages, one Core design.
2. **Underneath vs on top.** Underneath wherever the maker allows it; on top everywhere else. "Any device" must never depend on a maker saying yes.
3. **The smallest chip we promise.** Floor: anything that can run a small Linux gets the trimmed Core. Below that (bare microcontrollers), only the companion — enough to carry your identity and join the network, not the full experience.

## Deliberately NOT covered (named so nothing is implied finished)
- The app-store and payment plumbing — separate spec.
- The device-by-device work to make a full "underneath" install run on each specific model — that stays per-device and ongoing.
- Legal/agreements for shipping on third-party hardware.
