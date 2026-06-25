# Circle OS — Skin & Icon-Pack Design Guide

> **Intent:** take the Windows Phone / Metro design positives that the *design world* admired — and that the platform's app gap + Microsoft dependency wasted — and do them **right**, on Circle OS's independent, app-rich foundation. Metro is the design *discipline* we inherit; **the soul stays Circle OS** (privacy, ownership, AetherNet, any-handset, uncensorable). A few small deliberate touches make it **distinctly Circle OS**.
> This is the spec you hand a designer + engineer. Numbers are a **starting spec — tune in design**, not gospel.

---

## 0. Why Metro is worth inheriting
Design circles loved Windows Phone for things that were never the reason it failed (the app gap + being chained to Microsoft were). We keep exactly those things:
- **Authentically digital** — flat, content-first, anti-skeuomorphic. (Predated iOS 7's flattening by 3 years.)
- **Typography as the interface** — type does the work icons/chrome do elsewhere.
- **Live Tiles** — a living, glanceable home.
- **Motion with intent** — "fast and fluid," choreographed, not decorative.
- **System rigor** — one consistent design across the whole OS.
- **Restraint** — reductive, generous negative space.

---

## 1. Foundations we inherit (the Metro rules)

### 1.1 The tile grid (the spine of the whole look)
- Phone start screen = a tile grid, **4 "small" columns** wide.
- Tile sizes (in small-cell units): **small 1×1 · medium 2×2 · wide 4×2 · large 4×4**.
- Starting numbers: small cell **≈ 76dp**, gutter **≈ 8dp** → medium ≈ 160dp, wide ≈ 328dp. Outer margin ≈ 12dp.
- Everything snaps to this grid. No free placement.

### 1.2 Tile anatomy
- **Content sits bottom-left** (app name lowercase, small); counts/badges top-right.
- Tile glyph (for non-live tiles): **white, centred** on the accent fill.
- **Live face + back face** that flips; **transparent-tile** option (glyph on the wallpaper).
- Flat fill, **sharp corners**, no shadow, no gradient.

### 1.3 Typography
- Base face: **Selawik** (OFL, Segoe-metric) — the legal Segoe feel.
- Light weights, **large headers**; the panorama/section **wordmark bleeds off the right edge**.
- Lowercase section headers (Metro convention) — keep.
- Starting type ramp (dp): Display 48 / Header 28 / Subhead 20 / Body 15 / Caption 12; headers Light, body Regular.

### 1.4 Colour & theme
- Flat fills; **one accent colour applied across all tiles**.
- **True-black** dark theme (OLED) / clean white light theme.
- No gradients on UI; colour = information, not decoration.

### 1.5 Motion
- **Tile flip / turnstile** on the start screen.
- **Press-to-tilt** feedback (tiles depress toward the touch).
- **Panorama / Pivot** horizontal motion between sections.
- **Parallax** wallpaper behind tiles.
- Page transitions are choreographed (staggered list cascade).

### 1.6 Layout patterns
- **Panorama** (wide canvas that runs off-screen) and **Pivot** (swipe between tabbed sections).
- **Long-list with alphabetical jump** (tap a letter → index grid).
- Content-first: minimal chrome, no title bars where text can lead.

### 1.7 Iconography — two distinct contexts
- **Tile glyph** = white, centred, optical-sized, on the accent square.
- **In-app / list icons** = **monoline** (single stroke weight), monochrome, angular/geometric.
- Flat only — no 3D, gradient, or shadow. SVG masters → exported sizes.

---

## 2. Distinctly Circle OS — the signatures (PROPOSED — your call to refine/extend)
Small, disciplined departures so it reads as Circle OS, not WP. Metro's ethos is restraint, so these are **accents, not a redesign**:

1. **Circle Blue accent.** Accent is **locked to the brand palette** (`#2196F3` primary, `#2c3e50`, `#ffffff`) — optionally a small *curated* set of brand accents, never WP's free-for-all. Signature colour, never orange.
2. **Square-meets-circle.** Tiles stay **square** (Metro discipline) — but the **human/identity layer is circular**: avatars, contact tiles, B! presence, status badges, toggles. The square/circle tension is the visual signature (and honours the name). Tiles disciplined; identity warm.
3. **Soul tiles by default.** The out-of-box home surfaces what Circle OS *means*, not generic widgets: a **live AetherNet mesh tile**, the **SDPKT wallet tile**, **B!** — the tile *content* is itself a differentiator nobody else has.
4. **One signature motion.** Keep flip/turnstile; add a **circular reveal / ripple from the tile centre** on app launch — a subtle "Circle" motion fingerprint.
5. **Privacy as a visible state.** A tasteful, persistent cue that comms are **blind/encrypted** — a soul signal WP never had.
6. **Dual dark base.** True-black *and* a signature **deep-navy (`#2c3e50`)** base option; default wallpapers carry a restrained Circle mark.
7. **Wordmark.** Selawik for the system; the **Circle wordmark** in the panorama header instead of a generic title.

Guardrails carried in from the brand rules: **no orange**, **no scrollbars**, fully **responsive**, accessibility-first.

---

## 3. Building a skin on Circle OS (technical shape)
A **skin** = a bundle the theme engine applies, with a **first-boot picker**:
- **RRO overlay** — overrides `colors.xml` (accent/theme), `dimens` (grid/tile/corner), shape tokens, and font tokens.
- **Icon pack** — Lawnicons/appfilter-style mapping; SVG masters → density buckets.
- **Wallpaper set** — true-black + navy variants with the Circle mark.
- **Font** — Selawik.
- **Accent** — from the brand palette.
- Engine = **AOSP RRO + Material You** (native); packaging structure can follow the Apache `substratum/template`.

---

## 4. Starter set to actually build
- **Skin 1 — "Circle Metro"** (flagship): full Metro discipline + the §2 signatures; ship **light + true-black dark**.
- **Skin 2 — "Circle Aether"**: more Circle-native; navy base, mesh-forward soul tiles.
- **Icon pack v1**: monoline set — core ~150 app glyphs + tile glyphs, weight aligned to Selawik.

## 5. Asset shortcuts (optional — only if cleanly licensed)
Per the policy: **if a clean-licensed asset already exists, use it as a base; otherwise make our own.** Realistically the one clear clean grab is **Selawik** (OFL). Everything else — tiles, icons, wallpapers — **make our own**, which also makes it distinct. (See `CircleOS_Theme_Skins_Scout.md` for the verified clean-asset list.)

## Appendix — "don't lose what critics loved" checklist
Typographic hierarchy ✓ · Live Tiles ✓ · choreographed motion ✓ · flat/authentically-digital ✓ · panorama/pivot ✓ · grid discipline ✓ · restraint ✓
