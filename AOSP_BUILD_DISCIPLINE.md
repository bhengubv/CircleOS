# feedback_aosp_dry_run_first.md

**HARD RULE. Never kick off `m systemimage` or `m otapackage` without running the dry-run gate first.**

Established 2026-06-05 after wasting ~3 hours of wall-clock on 4 full-systemimage builds (each ~55 min) that each failed on issues a 1-5 minute pre-check would have caught:

- Build #2 (51 min): missing `@mipmap/ic_launcher` — caught by `m CircleLauncher` (~5 min)
- Build #4 (57 min): "succeeded" but microG missing because `microg.mk` was never `include`d — caught by `get_build_var PRODUCT_PACKAGES | grep GmsCore` (1 sec)
- Build #5 (48 min): presigned APK missing `preprocessed: true` — caught by `m FDroid` (~3 min) and is a documented Soong rule for any presigned APK with target SDK ≥ 30

## The discipline (in order, every time)

### Before ANY full systemimage build

1. **`m nothing`** — Soong analysis only, no compilation. 1-2 min. Catches:
   - Broken Android.bp syntax
   - Missing include paths
   - Malformed PRODUCT_PACKAGES blocks
   - Glob mismatches (e.g. new files in services/core/java/** triggering re-regen)

2. **`get_build_var PRODUCT_PACKAGES | tr ' ' '\n' | grep <ExpectedModule>`** for any new module — instant. If empty, your `include` or `+=` isn't reaching the active product mk. **microG missed build #4 because microg.mk was on disk but never included anywhere. One grep would have caught it.**

3. **Per-module `m <ModuleName>`** for each new/changed module — 3-15 min per module. Catches:
   - Missing resources (icons, layouts, strings)
   - Android.bp errors (wrong package, missing deps)
   - Presigned/preprocessed APK mismatches
   - AIDL stub linking failures
   - SELinux compilation errors

4. **ONLY THEN `m systemimage`** — the 55-min build. Should pass on first try if steps 1-3 are green.

### Known AOSP gotchas to check upfront

- **Prebuilt APKs with `presigned: true` and target SDK ≥ 30 require `preprocessed: true`.** Soong's signature-v2 protection refuses to re-process them otherwise. Update fetch scripts to emit both.
- **vendor/.mk files only fire if `include`d.** Adding a new .mk doesn't auto-link. Check `grep -r "include.*your.mk" vendor/circle build/circle device/circle`.
- **PRODUCT_PROPERTY_OVERRIDES vs PRODUCT_SYSTEM_PROPERTIES:** properties labeled by SELinux as `system_property_type` (via `system_public_prop`) only land in `/system/build.prop` if declared via `PRODUCT_SYSTEM_PROPERTIES`, not the legacy `PRODUCT_PROPERTY_OVERRIDES`. (Round 21 fix — took the team 4 rounds.)
- **Adding new files to `services/core/java/**`** triggers Soong glob regen — that's an extra ~5-15 min vs an unchanged build. Batch multiple Java additions into one build cycle.
- **APKs with `privileged: true`** need a `privapp-permissions-<pkg>.xml` enumerating every signature|privileged perm. Skipping that XML = build failure. Set `privileged: false` for prebuilts when the XML isn't pinned to a specific version.
- **`/data/circle` SELinux labels** require the dir to live at exactly `/data/circle`. Using `Context.createDeviceProtectedStorageContext().getDataDir()` puts it at `/data/system_de/0/circle/` — works functionally but the label is `system_data_file`, not `circle_privacy_data_file`.

### Soong dry-run recipe

```bash
cd ~/aosp
source build/envsetup.sh >/dev/null
lunch circle_arm64-trunk_staging-userdebug >/dev/null
time m -j4 nothing 2>&1 | tail -30
# Expect "build completed successfully" — typical 60-120s
```

### Get-build-var recipe

```bash
get_build_var PRODUCT_PACKAGES | tr ' ' '\n' | grep -E "GmsCore|FDroid|CircleLauncher" | sort -u
# Expect: every module you added to vendor/circle/{config/common.mk,microg/microg.mk}, etc.
```

### Per-module build recipe

```bash
time m -j4 ModuleName 2>&1 | tail -30
# Expect "build completed successfully" — typical 3-15 min depending on module
```

## When NOT to skip

There is no "when to skip." Even a 1-line config change goes through `m nothing` first. The time penalty (90 seconds) is dwarfed by the cost of one failed 55-minute systemimage build.

## How to recognize when this rule is being violated

If you're about to call `m systemimage` and you can't say all of:
- "I ran `m nothing` since my last change and it passed"
- "I verified my new modules are in `get_build_var PRODUCT_PACKAGES`"
- "I built each new module individually and they passed"

then STOP. Run those first.
