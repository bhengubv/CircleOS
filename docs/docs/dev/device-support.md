# Adding Device Support

This guide explains how to port Circle OS to a new device.

---

## Prerequisites

Before starting a port, you need:

- **Device kernel source** — usually available from the manufacturer or LineageOS
- **Device tree** — partition layout, board config, hardware drivers
- **Vendor blobs** — proprietary firmware for GPU, modem, camera, etc.
- A development device (ideally 2 — one to keep working if you brick the port device)
- **Android 14 AOSP** build environment (see [Build from Source](build-from-source.md))

---

## Supported device structure

Each device has two repos:

| Repo | Example | Contains |
|------|---------|----------|
| `device/<manufacturer>/<codename>` | `device/samsung/a52q` | Device tree, board config |
| `vendor/<manufacturer>/<codename>` | `vendor/samsung/a52q` | Proprietary blobs |

These are included in the Circle OS manifest:

```xml
<!-- .repo/local_manifests/circledevices.xml -->
<manifest>
  <remote name="circle-devices" fetch="https://github.com/bhengubv" />

  <project path="device/samsung/a52q"
           name="android_device_samsung_a52q"
           remote="circle-devices"
           revision="main" />

  <project path="vendor/samsung/a52q"
           name="android_vendor_samsung_a52q"
           remote="circle-devices"
           revision="main" />
</manifest>
```

---

## Step 1 — Create the device tree

```bash
mkdir -p device/<manufacturer>/<codename>
cd device/<manufacturer>/<codename>
git init
```

Minimum required files:

```
device.mk          — Package lists, overlays, device-specific config
BoardConfig.mk     — Partition sizes, kernel config, hardware flags
AndroidProducts.mk — Lunch combo definition
Android.mk         — Makefile entry point
```

### BoardConfig.mk essentials

```makefile
# Kernel
TARGET_KERNEL_SOURCE := kernel/<manufacturer>/<codename>
TARGET_KERNEL_CONFIG := <codename>_defconfig

# Partitions
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 4294967296  # 4 GB
BOARD_VENDORIMAGE_PARTITION_SIZE := 1073741824  # 1 GB
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs

# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS := boot system vendor dtbo vbmeta

# Circle OS features
BOARD_CIRCLE_MESH_ENABLED := true
BOARD_CIRCLE_NFC_WALLET := true  # only if device has NFC
```

### AndroidProducts.mk

```makefile
PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/circeos_<codename>.mk

COMMON_LUNCH_CHOICES := \
    circeos_<codename>-user \
    circeos_<codename>-userdebug \
    circeos_<codename>-eng
```

---

## Step 2 — Circle OS device config

Include Circle OS base config in your `device.mk`:

```makefile
# Inherit Circle OS base
$(call inherit-product, vendor/circle/config/circle_base.mk)

# Device-specific overrides
PRODUCT_NAME := circeos_<codename>
PRODUCT_DEVICE := <codename>
PRODUCT_BRAND := <Manufacturer>
PRODUCT_MODEL := <Model Name>
PRODUCT_MANUFACTURER := <manufacturer>

# Features (enable only what hardware supports)
CIRCLE_FEATURE_NFC_WALLET := true
CIRCLE_FEATURE_MESH := true
CIRCLE_FEATURE_BUTLER_AI := true
CIRCLE_BUTLER_DEFAULT_MODEL := 1b  # 0.5b / 1b / 3b / 7b / 14b

# Privacy Engine
CIRCLE_PRIVACY_DEFAULT_DENY_INTERNET := true
```

---

## Step 3 — Extract vendor blobs

```bash
# With the stock ROM flashed and ADB connected:
cd vendor/<manufacturer>/<codename>

# Use extract-utils (from TheMuppets or device-specific)
./extract-files.sh

# Or manually:
adb pull /vendor ./vendor
adb pull /system/lib ./lib
```

Create `vendor/<manufacturer>/<codename>/Android.bp` with `cc_prebuilt_library_shared` entries for each blob.

---

## Step 4 — Build and test

```bash
source build/envsetup.sh
lunch circeos_<codename>-userdebug
m -j$(nproc) 2>&1 | tee build.log
```

Common first-build failures:
- Missing kernel config → update `defconfig`
- Missing blob → update `extract-files.sh`
- Partition size mismatch → update `BoardConfig.mk`

Flash and test basic boot:
```bash
fastboot flash boot out/target/product/<codename>/boot.img
fastboot flash system out/target/product/<codename>/system.img
fastboot flash vendor out/target/product/<codename>/vendor.img
fastboot -w
fastboot reboot
```

---

## Step 5 — Verify Circle OS features

After basic boot, verify:

- [ ] Privacy Engine initialises (check `logcat -s CirclePrivacy`)
- [ ] Mesh service starts (if enabled) — `adb shell dumpsys circle_mesh`
- [ ] NFC wallet accessible (if hardware supports it)
- [ ] Butler AI loads (check available RAM vs model size)
- [ ] OTA check connects to SleptOnAPI

---

## Step 6 — Submit your port

1. Push your device and vendor repos to GitHub under your account
2. Open a PR to [CircleOS/local_manifests](https://github.com/bhengubv/CircleOS) adding your device to `circledevices.xml`
3. Include in the PR:
   - Device specs table
   - Build instructions
   - Test results for all Circle OS features
   - Photos of Circle OS running on the device

Device ports maintained by the community are listed on [circleos.co.za/compatibility](https://circleos.co.za/compatibility).

---

## Supported hardware features

| Feature | Requirement |
|---------|-------------|
| Mesh (BLE) | Bluetooth LE 4.0+ with GATT support |
| Mesh (WiFi Direct) | WiFi Direct (P2P) support in kernel |
| Titanium Wallet | NFC (ISO 14443-4) hardware |
| Butler AI (0.5B) | 2 GB RAM |
| Butler AI (3B) | 4 GB RAM |
| Butler AI (7B) | 6 GB RAM |
| Butler AI (14B) | 12 GB RAM |
| A/B seamless updates | A/B partition scheme in bootloader |
