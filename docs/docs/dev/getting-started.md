# Developer Getting Started

Welcome. This guide gets you from zero to a running Circle OS build environment.

---

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Ubuntu | 22.04 LTS | Recommended. macOS works with caveats. |
| Python | 3.10+ | Required for repo tool |
| Git | 2.35+ | |
| Java | OpenJDK 17 | `sudo apt install openjdk-17-jdk` |
| Disk | 500 GB free | AOSP + build artifacts |
| RAM | 16 GB | 32 GB recommended |

---

## Step 1: Install repo tool

```bash
mkdir -p ~/.local/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/.local/bin/repo
chmod a+x ~/.local/bin/repo
export PATH="$PATH:$HOME/.local/bin"
```

---

## Step 2: Configure git

```bash
git config --global user.email "you@example.com"
git config --global user.name  "Your Name"
```

---

## Step 3: Sync the source

```bash
mkdir circleos && cd circleos
repo init -u https://github.com/bhengubv/CircleOS -b circle-14.0-clean
repo sync -c -j$(nproc) --force-sync --no-clone-bundle
```

This downloads ~250 GB. Take a break.

---

## Step 4: Set up build environment

```bash
source build/envsetup.sh
```

---

## Step 5: Build for a device

```bash
lunch circleos_a52-userdebug    # Samsung Galaxy A52
# or
lunch circleos_rosemary-userdebug  # Xiaomi Redmi Note 10

mka bacon -j$(nproc)
```

Output: `out/target/product/{device}/circleos-*.zip`

---

## Step 6: Flash to device

```bash
adb reboot recovery
adb sideload out/target/product/a52/circleos-1.0-a52.zip
```

---

## Project structure

```
circleos/
├── frameworks/base/         ← Circle OS system services
│   └── services/core/java/com/circleos/server/
│       ├── privacy/         ← Privacy engine
│       ├── security/        ← Security engine
│       └── update/          ← OTA service
├── vendor/circle/           ← Circle OS vendor overlays + apps
│   ├── apps/CircleSettings/ ← Settings app
│   ├── config/              ← Build configs
│   └── overlay/             ← Resource overlays
└── device/circle/common/    ← Common device config
```

---

## Next steps

- [Architecture overview](architecture.md)
- [Contributing guide](contributing.md)
- [Code style](code-style.md)
