# Release Process

This page describes how Circle OS releases are built, signed, and distributed.

---

## Release channels

| Channel | Audience | Stability | Update frequency |
|---------|----------|-----------|-----------------|
| `stable` | All users | High | ~monthly |
| `beta` | Early adopters | Medium | ~biweekly |
| `nightly` | Developers | Low | Daily (automated) |

---

## Version numbering

`MAJOR.MINOR.PATCH` — e.g., `1.2.3`

- **MAJOR** — breaking change to system APIs or major feature additions
- **MINOR** — new features, backward-compatible
- **PATCH** — bug fixes and security patches

Security-only patches also carry a date suffix: `1.2.3-2026-02`

---

## Build a release

### Prerequisites

- Ubuntu 22.04 LTS (recommended)
- 16 GB RAM minimum
- 250 GB free disk space
- Release signing keys (see [Signing](#signing))

```bash
source build/envsetup.sh
lunch circeos_a52-user  # 'user' not 'userdebug' for releases

# Full build
m -j$(nproc)

# Build output
ls out/target/product/a52/
# system.img, vendor.img, boot.img, dtbo.img, vbmeta.img
```

### Supported targets

| Lunch target | Device |
|-------------|--------|
| `circeos_a52-user` | Samsung Galaxy A52 |
| `circeos_a53-user` | Samsung Galaxy A53 |
| `circeos_note10-user` | Xiaomi Redmi Note 10 |
| `circeos_note11-user` | Xiaomi Redmi Note 11 |
| `circeos_nokiag21-user` | Nokia G21 |
| `circeos_pixel6-user` | Google Pixel 6 |
| `circeos_rednote12-user` | Xiaomi Redmi Note 12 |

---

## Signing

### Generate release keys (first time only)

```bash
# In the AOSP root
subject='/C=ZA/ST=Western Cape/L=Cape Town/O=The Geek Network/OU=CircleOS/CN=CircleOS Release/emailAddress=release@thegeek.co.za'

mkdir -p ~/.android-certs
for cert in platform shared media networkstack releasekey; do
    make_key ~/.android-certs/${cert} "${subject}"
done
```

Store keys in a **hardware security module (HSM)** or encrypted offline storage. Never commit keys to git.

### Sign a build

```bash
./build/tools/releasetools/sign_target_files_apks \
  -o \
  -d ~/.android-certs \
  out/dist/circeos_a52-target_files.zip \
  signed-target-files.zip

./build/tools/releasetools/ota_from_target_files \
  -k ~/.android-certs/releasekey \
  signed-target-files.zip \
  circeos-1.0.4-a52.zip
```

### Delta generation

```bash
./build/tools/releasetools/ota_from_target_files \
  -k ~/.android-certs/releasekey \
  --incremental_from previous-target-files.zip \
  signed-target-files.zip \
  circeos-1.0.3-to-1.0.4-a52.zip
```

---

## Publish a release

### 1. Upload to R2

```bash
rclone copy circeos-1.0.4-a52.zip r2:circeos-ota/stable/a52/
rclone copy circeos-1.0.3-to-1.0.4-a52.zip r2:circeos-ota/stable/a52/deltas/
```

### 2. Publish via SleptOnAPI

```bash
# Get the manifest URL after upload
MANIFEST_URL="https://ota.circleos.co.za/stable/a52/circeos-1.0.4-a52.zip"

# Sign the manifest JSON
echo '{"version":"1.0.4","channel":"stable","rollout_percent":5}' > manifest.json
openssl dgst -sha256 -sign release.pem -out manifest.sig manifest.json
SIG=$(base64 < manifest.sig)

curl -X POST https://api.slepton.co.za/os/releases \
  -H "X-Api-Key: ${CIRCLEOS_PUBLISHER_KEY}" \
  -F "version=1.0.4" \
  -F "channel=stable" \
  -F "rollout_percent=5" \
  -F "release_notes=Bug fixes and security patches" \
  -F "signature_b64=${SIG}" \
  -F "file=@circeos-1.0.4-a52.zip"
```

### 3. Staged rollout ladder

| Stage | Rollout % | Wait time |
|-------|-----------|-----------|
| Soak | 5% | 48 hours (watch crash rates) |
| Expand | 25% | 72 hours |
| Full | 100% | — |

Adjust rollout via:
```bash
curl -X PATCH https://api.slepton.co.za/os/releases/{id} \
  -H "X-Api-Key: ${CIRCLEOS_ADMIN_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"rollout_percent": 25}'
```

### 4. Rollback

```bash
# Deactivate a broken release
curl -X PATCH https://api.slepton.co.za/os/releases/{id} \
  -H "X-Api-Key: ${CIRCLEOS_ADMIN_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"is_active": false}'
```

Devices that have already downloaded but not yet applied the update will see the release as unavailable on next check.

---

## Release checklist

Before publishing to stable:

- [ ] All unit tests pass on CI
- [ ] CTS subset passes (see [Testing](testing.md))
- [ ] Manual test checklist completed for all supported devices
- [ ] Security patches for the current Android Security Bulletin applied
- [ ] Release notes written
- [ ] Delta generated from N-1 version
- [ ] SHA-256 checksums published
- [ ] Staged rollout at 5% for 48 hours with no critical issues
