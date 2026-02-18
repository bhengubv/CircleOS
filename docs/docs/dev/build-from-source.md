# Build from Source

Full build instructions for Circle OS. See [Getting Started](getting-started.md) for prerequisites.

---

## Environment setup

```bash
# Ubuntu 22.04
sudo apt update && sudo apt install -y \
  git-core gnupg flex bison build-essential zip curl \
  zlib1g-dev libc6-dev-i386 libncurses5 lib32ncurses5-dev \
  x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev \
  libxml2-utils xsltproc unzip fontconfig python3 python3-pip \
  openjdk-17-jdk ccache

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Enable ccache (speeds up rebuilds significantly)
export USE_CCACHE=1
export CCACHE_DIR=~/.ccache
ccache -M 50G
```

---

## Sync source

```bash
mkdir ~/circleos && cd ~/circleos

repo init \
  -u https://github.com/bhengubv/CircleOS \
  -b circle-14.0-clean \
  --depth=1

repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags
```

---

## Build targets

| Target | Device | Use |
|--------|--------|-----|
| `circleos_a52-userdebug` | Samsung Galaxy A52 | Development |
| `circleos_a52-user` | Samsung Galaxy A52 | Release |
| `circleos_rosemary-userdebug` | Xiaomi Redmi Note 10 | Development |
| `circleos_G21-userdebug` | Nokia G21 | Development |

---

## Full build

```bash
cd ~/circleos
source build/envsetup.sh
lunch circleos_a52-userdebug
mka bacon -j$(nproc) 2>&1 | tee build.log
```

Output: `out/target/product/a52/circleos-1.0-YYYYMMDD-a52.zip`

---

## Incremental build

After making changes to a specific service:

```bash
# Rebuild just the frameworks jar
mmm frameworks/base

# Rebuild CircleSettings APK
mmm vendor/circle/apps/CircleSettings

# Push to connected device
adb push out/target/product/a52/system/app/CircleSettings/CircleSettings.apk /system/app/CircleSettings/
adb shell am force-stop za.co.circleos.settings
adb shell am start za.co.circleos.settings/.CircleSettingsActivity
```

---

## Signing

Development builds are signed with test keys automatically. For release signing:

```bash
# Generate release keys (do once, store securely)
subject='/C=ZA/ST=Gauteng/L=Johannesburg/O=The Geek Network/OU=CircleOS/CN=CircleOS Release/emailAddress=info@thegeek.co.za'
for x in releasekey platform shared media networkstack; do
    ./development/tools/make_key vendor/circle/signing/keys/$x "$subject"
done

# Build with release keys
TARGET_BUILD_VARIANT=user \
PRODUCT_DEFAULT_DEV_CERTIFICATE=vendor/circle/signing/keys/releasekey \
mka bacon -j$(nproc)
```

---

## Common build errors

| Error | Fix |
|-------|-----|
| `JAVA_HOME not set` | `export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64` |
| `ninja: error: ...` | `make clean && mka bacon` |
| Out of disk space | Clean old builds: `make clobber` |
| OOM during build | Reduce parallelism: `mka bacon -j4` |
