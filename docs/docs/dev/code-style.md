# Code Style Guide

Circle OS follows the **Android Open Source Project (AOSP) code style** for Java/Kotlin, with the additions below.

---

## Java

### General

- Follow [AOSP Java style guide](https://source.android.com/setup/contribute/code-style)
- **4-space indentation** — no tabs
- **100-character line limit**
- `import` statements: no wildcard imports; static imports last
- Braces on the same line (K&R style)

### Naming

| Element | Convention | Example |
|---------|-----------|---------|
| Class | UpperCamelCase | `PrivacyEngineService` |
| Method | lowerCamelCase | `revokePermission()` |
| Constant | UPPER_SNAKE_CASE | `MAX_RELAY_HOPS` |
| Field (non-public) | `m` prefix | `mPeerManager` |
| Static field | `s` prefix | `sInstance` |
| Parameter | lowerCamelCase | `deviceId` |
| Local variable | lowerCamelCase | `packetCount` |

### Circle OS additions

- All CircleOS system service classes must be in `android.circleos.*` or `com.circleos.server.*`
- New AIDL interfaces: prefix with `ICircle` (e.g., `ICircleMeshService`)
- Privacy-sensitive operations must log to `CirclePrivacyLog` at `DEBUG` level:
  ```java
  CirclePrivacyLog.d(TAG, "NetworkPermission denied: pkg=" + packageName);
  ```
- Never log user data (email, content, location) at any log level

### Thread safety

- All system service methods that can be called from binder threads must be `synchronized` or use a `HandlerThread`
- Use `@GuardedBy("mLock")` annotation for fields accessed under a lock

---

## Kotlin

Kotlin is used for new SleptOn app code and optional AOSP modules.

- Follow [Kotlin coding conventions](https://kotlinlang.org/docs/coding-conventions.html)
- Prefer `val` over `var`
- Use coroutines for async — no `AsyncTask`
- Use `Flow` for reactive streams

---

## C / C++

For native code (JNI, HAL):

- Follow [LLVM coding standards](https://llvm.org/docs/CodingStandards.html)
- **2-space indentation**
- `snake_case` for functions and variables
- Include guards: `#ifndef CIRCLEOS_<MODULE>_<FILE>_H_`

---

## Android-specific

### Resources

- Layout files: `activity_<name>.xml`, `fragment_<name>.xml`, `item_<name>.xml`
- String keys: `circle_<feature>_<description>` (e.g., `circle_mesh_status_connected`)
- Colour resources: use design tokens from `res/values/colors.xml`

### Permissions

New permissions added by Circle OS:
- Must be declared in `vendor/circle/config/permissions/circle_permissions.xml`
- Must have a `protectionLevel` of `signature` or higher
- Must be documented in this guide

---

## Shell scripts

- `#!/usr/bin/env bash`
- `set -euo pipefail` at the top of every script
- Quote all variable expansions: `"${var}"`
- Prefer `[[ ]]` over `[ ]`

---

## Git commits

Follow the format in [Contributing](contributing.md):

```
component: short imperative description (max 72 chars)

Longer explanation of why, not what. Wrap at 72 chars.

Bug: b/12345
```

Components: `mesh`, `privacy`, `wallet`, `butler`, `ota`, `build`, `docs`, `test`.

---

## Linting & formatting

| Language | Tool | Config |
|----------|------|--------|
| Java | `checkstyle` (AOSP config) | `tools/checkstyle/` |
| Kotlin | `ktlint` | `.editorconfig` |
| C/C++ | `clang-format` | `.clang-format` |
| Shell | `shellcheck` | — |
| Python (build tools) | `flake8` | `setup.cfg` |

Run all linters:
```bash
source build/envsetup.sh
lunch circeos_a52-userdebug
mma checkstyle
```

---

## Code review checklist

Before merging any PR:

- [ ] No user data logged at any level
- [ ] New permissions declared and documented
- [ ] Thread safety annotated
- [ ] Unit tests for new logic
- [ ] CTS tests pass if touching system APIs
- [ ] Privacy-sensitive paths log to `CirclePrivacyLog`
