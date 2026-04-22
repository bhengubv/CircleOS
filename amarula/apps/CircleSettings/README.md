# CircleSettings

First ArkTS app skeleton for Amarula. Baked into the OS image.

**Bundle name:** `com.circle.settings`
**Purpose:** user-facing control surface — privacy, modes, OTA, permissions, diagnostics, theme.

## Status

Skeleton only. Opens to an Index page with placeholder tiles. Meant to (a) prove the DevEco Studio toolchain works, (b) be the first app to round-trip through our build pipeline.

## Run it

1. Open this folder in DevEco Studio
2. Let it sync dependencies (`oh-package.json5`)
3. Select the rk3568 emulator
4. Hit Run

Expected: app opens, shows "Welcome to the Circle" with a list of stub sections.

## Next work

- Wire to real settings providers (OTA status, privacy toggles)
- Apply Circle design tokens (Circle Deep, Circle Warm, Circle Gold, Comfortaa font)
- Connect to `ICircleFirewallService` once that lands
- A11y pass (Elder mode overrides)
