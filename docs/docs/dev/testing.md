# Testing Guide

Circle OS has three layers of tests: unit tests, integration tests, and device tests.

---

## Unit tests (host)

Unit tests run on your development machine without a device.

```bash
source build/envsetup.sh
lunch circeos_a52-userdebug

# Run all Circle OS unit tests
m PrivacyEngineTests MeshServiceTests WalletTests ButlerTests

# Or run a specific module
atest PrivacyEngineTests
```

### Key test suites

| Suite | Tests | Location |
|-------|-------|----------|
| `PrivacyEngineTests` | NetworkPermissionEnforcer, identifier spoofing, auto-revoke | `frameworks/base/tests/PrivacyEngine/` |
| `MeshServiceTests` | MeshProtocol, MeshCrypto, PeerManager, MessageStore | `frameworks/base/tests/Mesh/` |
| `WalletTests` | SDPKT token generation, verification, settlement queue | `frameworks/base/tests/Wallet/` |
| `ButlerTests` | LLM backend loading, inference, privacy guardrails | `frameworks/base/tests/Butler/` |
| `OtaClientTests` | Update fetch, delta verification, A/B slot management | `frameworks/base/tests/OtaClient/` |

### Writing unit tests

```java
// frameworks/base/tests/PrivacyEngine/NetworkPermissionEnforcerTest.java
@RunWith(JUnit4.class)
public class NetworkPermissionEnforcerTest {

    private NetworkPermissionEnforcer mEnforcer;

    @Before
    public void setUp() {
        mEnforcer = new NetworkPermissionEnforcer(/* mock context */);
    }

    @Test
    public void testDefaultDenyBlocks() {
        boolean allowed = mEnforcer.isNetworkAllowed("com.example.newapp", 1000);
        assertFalse("New app should be denied internet by default", allowed);
    }

    @Test
    public void testGrantedAppAllowed() {
        mEnforcer.grantNetworkPermission("com.example.app", 1000);
        assertTrue(mEnforcer.isNetworkAllowed("com.example.app", 1000));
    }
}
```

---

## Integration tests (device)

Integration tests require a connected device or emulator with Circle OS.

```bash
# Run Circle OS integration tests
atest CircleOsIntegrationTests

# Run against a specific device
atest -s emulator-5554 CircleOsIntegrationTests
```

### Emulator setup

```bash
# Build the emulator image
m sdk_phone_x86_64

# Start emulator
emulator -avd CircleOS_test -kernel prebuilts/qemu-kernel/x86_64/kernel-qemu2

# Check it's up
adb devices
```

---

## CTS (Compatibility Test Suite)

Circle OS must pass relevant CTS tests before any stable release.

```bash
# Download CTS from AOSP
# https://source.android.com/compatibility/cts/downloads

# Run full CTS
./cts-tradefed run cts

# Run privacy-relevant subsets
./cts-tradefed run cts -m CtsPerm
./cts-tradefed run cts -m CtsOs
./cts-tradefed run cts -m CtsNet
```

Known intentional CTS deviations (documented in `vendor/circle/cts/known_failures.txt`):
- `CtsNetTest#testDefaultHttpClient` — intentionally blocked by Privacy Engine default-deny
- `CtsOsTest#testAndroidId` — Android ID is spoofed per-app

---

## Manual test checklist

Before each stable release, manually verify:

### Privacy Engine
- [ ] New app installed → no internet access by default
- [ ] Grant internet via Settings → app has internet
- [ ] Leave app unused 14 days → permission auto-revoked
- [ ] Privacy dashboard shows all recent permission uses

### Mesh
- [ ] Two Circle OS phones pair over BLE
- [ ] Message sent when both offline (WiFi off, mobile data off)
- [ ] Message received after peer comes back online (store-and-forward)
- [ ] OTA update transferred via mesh

### Titanium Wallet
- [ ] Generate wallet (new device)
- [ ] Create SDPKT token → tap to pay (two devices)
- [ ] Token settles when internet connects
- [ ] Double-spend attempt rejected

### Butler AI
- [ ] Butler loads at boot (model selected by RAM)
- [ ] Chat responds without internet
- [ ] Voice input transcribed on-device
- [ ] Butler does not access internet (verified via Privacy Dashboard)

### SleptOn
- [ ] Browse apps (no account required)
- [ ] Install free app
- [ ] Purchase paid app with Shongololo
- [ ] Mesh app distribution (phone-to-phone APK transfer)

### OTA
- [ ] Update check finds new version
- [ ] Delta downloaded and verified
- [ ] A/B switch on reboot
- [ ] Rollback on boot failure

---

## CI/CD

Circle OS uses GitHub Actions for automated testing:

```yaml
# .github/workflows/test.yml
on: [push, pull_request]
jobs:
  unit-tests:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - name: Run unit tests
        run: |
          source build/envsetup.sh
          lunch circeos_a52-userdebug
          m PrivacyEngineTests MeshServiceTests
          atest PrivacyEngineTests MeshServiceTests
```

PRs that fail unit tests are blocked from merging.

---

## Reporting test failures

1. Open a [GitHub Issue](https://github.com/bhengubv/CircleOS/issues/new)
2. Label: `type: test-failure`
3. Include:
   - Device model and Circle OS version
   - Test name and failure output
   - Steps to reproduce
   - Attach logcat: `adb logcat -d > logcat.txt`
