# CircleOS frameworks-base patches

Established 2026-06-05 per the architectural decision documented in
`.repo/local_manifests/circle.xml`:

> Build against upstream frameworks/base (no override here). Circle framework
> services ship as patch series applied post-sync, NOT as a wholesale fork.

## Directory layout

```
~/CircleOS/patches/
├── README.md                          (this file)
├── frameworks-base/
│   ├── overlays/                      ← new files: cp -r into tree, no diff needed
│   │   └── services/core/java/com/circleos/server/privacy/
│   │       ├── CirclePrivacyManagerService.java
│   │       ├── PrivacyDatabase.java      (TODO)
│   │       └── PrivacyLogger.java        (TODO)
│   └── series/                        ← modifications to upstream files (git format-patch)
│       └── 0001-register-circle-privacy-service.patch
└── apply.sh                           ← idempotent applier
```

## Workflow

```
$ ~/run-aosp-sync.sh       # 1. pull latest AOSP
$ ~/run-circle-sync.sh     # 2. pull CircleOS_* projects (vendor/circle etc.)
$ ~/CircleOS/patches/apply.sh   # 3. apply overlays + series to frameworks/base
$ ~/run-aosp-build.sh      # 4. build
```

`run-post-sync.sh` should be updated to call `apply.sh` after the verification
block.

## Rebase strategy

When AOSP rebases to a new release (e.g. r20 → r21):

1. Run `~/run-aosp-sync.sh` against the new manifest
2. Each `series/*.patch` will either apply cleanly (good) or fail with rejects
3. For rejects: manually re-roll the patch against the new context, regenerate
   via `git format-patch` from a temporary commit in frameworks/base
4. Overlays in `overlays/` always apply cleanly — they don't touch upstream files

## What's NOT here yet

- `apply.sh` (write next session)
- `PrivacyDatabase.java`, `PrivacyLogger.java` (scaffolds; defer implementation)
- The actual networking permission enforcer (NetworkPermissionEnforcer.java)
- The 6 other privacy services per alpha_checklist.md

## First-time setup history

- 2026-06-05: Directory established. First overlay file:
  CirclePrivacyManagerService.java (skeleton with binder stubs). First patch:
  0001-register-circle-privacy-service.patch (SystemServer.java + services/core/Android.bp).
