# Patches against `frameworks/base` (AOSP 15, tag `android-15.0.0_r20`)

Every file in this directory is a `git format-patch` style patch series
that the build's sync step applies on top of a freshly checked-out
`frameworks/base`. Patches are applied with:

```bash
cd ~/aosp/frameworks/base
git am --3way ~/CircleOS/patches/frameworks-base/*.patch
```

If a patch stops applying after an upstream rebase, the right fix is to
rebase the patch — not to mutate the AOSP source in place. Keep the
upstream tree untouched outside of `git am`.

## Series

| # | File | Step | What it does |
|---|---|---|---|
| 0001 | `0001-systemserver-start-circle-privacy.patch` | 1 | Registers `CirclePrivacyService` with `SystemServer`. |
| 0002 | `0002-internet-runtime-permission.patch` | 1 | Demotes `android.permission.INTERNET` from a normal install-time permission to a `dangerous` runtime permission and routes the grant decision through `CirclePrivacyService`. |
