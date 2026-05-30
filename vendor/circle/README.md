# `vendor/circle/` — Circle OS source tree

This directory is what makes an upstream AOSP build into Circle OS. It
lives outside the AOSP tree so it can be developed independently and
synced into `aosp/vendor/circle/` at build time.

The intent: every Circle-specific service, app, library, sepolicy snippet,
product makefile fragment, and resource overlay lives here. Nothing
Circle-specific should be added directly inside the upstream AOSP source
trees (`frameworks/`, `system/`, `packages/`, …). Where we *do* need to
patch upstream — e.g. promoting `INTERNET` to a runtime permission — the
patch lives in `../patches/` and is applied at sync time, not
hand-edited into the AOSP checkout.

## Layout

```
vendor/circle/
├── README.md             ← this file
├── circle.mk             ← product makefile fragment (included from device.mk)
├── privacy/              ← Privacy Framework (Step 1)
│   ├── Android.bp
│   ├── aidl/za/co/circleos/privacy/ICirclePrivacyManager.aidl
│   ├── java/com/circleos/privacy/CirclePrivacyService.java
│   └── sepolicy/circle_privacy.te
├── inference/            ← Inference Service (Step 2 — TODO)
├── personality/          ← Personality Engine (Step 3 — TODO)
├── mesh/                 ← Mesh networking (Step 4 — TODO)
├── security/             ← Traffic Lobby, File DMZ, CDR, Zombie Map (Step 5 — TODO)
├── sdpkt/                ← SDPKT Titanium (Step 6 — TODO)
├── apps/                 ← 8 Circle apps (Step 7 — TODO)
├── ota/                  ← OTA delivery (Step 8 — TODO)
└── design/               ← Design System (Step 9 — TODO)
```

## Build integration

A device's `device.mk` adds Circle by including a single line:

```make
$(call inherit-product, vendor/circle/circle.mk)
```

`circle.mk` declares every Circle package, so adding a new service is a
two-step change: drop the module under `vendor/circle/<area>/`, then
append it to `PRODUCT_PACKAGES` in `circle.mk`.

## Sync to a build environment

The build server (`.201`) has the AOSP tree at `~/aosp/`. This
directory is rsynced into `~/aosp/vendor/circle/` before each build.
See `../scripts/sync-vendor.sh` for the script.
