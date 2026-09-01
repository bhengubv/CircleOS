# Circle OS — One Codebase, Every Device
*Plain-language design spec. No jargon.*

## The goal
One codebase. It installs on anything with a chip — phone, tablet, watch, TV, laptop, desktop, cheap no-name hardware, old stuff. On install it looks at the device, works out what it is, and fits itself to it. Apps are written once and show up right everywhere. Your work follows you from one device to the next.

## The shape: one core, many faces
**The Core** — written once. The brain of Circle: who you are, keeping things private and secure, talking to other devices (including with no internet), storage, and the engine that runs apps. **The Core knows nothing about any specific device.**

**Faces** — one per kind of device. A face is only the front: how things are laid out and how you control them.
- Phone — full screen, touch
- Tablet — bigger, touch, room for two panes
- Watch — tiny, quick glances
- TV — big screen, remote, lean back
- Desktop / laptop — windows, keyboard, mouse, many things at once

Same Core under every face. A new kind of device = a new face, never a new Circle.

**Adapters** — the small piece that plugs the Core into one device's real hardware: screen, wireless, buttons, sensors.

## The installer: assess and fit
One installer for everything. On install it:
1. Looks at the device — chip, screen, memory, inputs, wireless.
2. Works out what kind of device it is and what it can do.
3. Picks the right face.
4. Lays down only the parts that fit — the full build where there's power, a trimmed build on a watch, the bare minimum on a cheap chip.

Same source every time; the installer decides how much of it to use.

## Apps: describe, don't place
An app never says "put this button here." It says what it's *made of* — its screens, its actions, its data — and what it needs (camera, keyboard, big screen).
- The Core arranges those pieces to fit the current face: one column on a phone, a glance on a watch, a grid on a TV, windows on a desktop.
- Shared building blocks (a list, a button) already know how to look right on each face.
- If a device is missing something an app wants, that part quietly folds away — the app still runs.

Write the app once. The Core dresses it for whatever it lands on.

## Handoff: your work follows you
What moves between devices is your **place**, not the screen.
- As you work, the app keeps a small note of where you are — which screen, which item, how far in. The meaning, not the picture.
- That note is tied to **you**, not the device, so it reaches your other devices — over the internet, or straight device-to-device when there's no internet.
- The device you pick up rebuilds that exact spot in its own face — full screen on the phone becomes a window on the laptop, same place.
- Starts either way: you send it ("continue on the TV"), or a nearby device offers it ("pick up where you left off").

## Five rules that keep it ONE codebase
1. Nothing device-specific ever goes in the Core.
2. Device differences live only in Faces and Adapters.
3. The Core scales — same source, more or less of it switched on.
4. Apps describe; they never hard-place anything.
5. Where we can't install underneath, Circle runs on top — so it still reaches the device.

## Build order
1. **Core + phone face** — prove one device end to end.
2. **Add the desktop/laptop face** — the hardest jump (windows, keyboard, mouse). Do it early so the Core stays honest about big screens.
3. **Add TV and watch faces** — the far ends (remote; tiny glance).
4. **Handoff** between two faces — phone ↔ laptop first.
5. **The self-adapting installer** — assess-and-fit, once the pieces exist.
6. **Cheap-chip / old-hardware target** — the trimmed Core.

## Decisions to make first
- **What the Core is written in** — it has to build small and run on everything, from a laptop down to a cheap chip.
- **Where the line sits** between "install underneath" (full control of the device) and "run on top" (reaches devices we can't replace).
- **The smallest chip we promise to support** — this sets how small the trimmed Core has to go.
