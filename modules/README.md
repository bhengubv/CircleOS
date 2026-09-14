# modules

The Circle OS overlay work that used to live as loose folders beside this repo on the
Windows dev box (moved in on 2026-09-14 so a fresh clone is enough to work). Each folder is one
module: an AOSP app package (`res/ src/ Android.bp AndroidManifest.xml` + a `patch_reg.py` that
registers it in the build), a framework patch (`patch_*.py` applied to the AOSP tree on .201,
with `run_*.sh`), or build/dist tooling (magisk module, OTA, installer, torrent, hardening).

- `circleos-achievements` - Android.bp, AndroidManifest.xml, patch_reg.py, res, src
- `circleos-ar` - Android.bp, AndroidManifest.xml, patch_reg.py, res, src
- `circleos-backup` - Android.bp, AndroidManifest.xml, patch_reg.py, res, src
- `circleos-bio` - BIOMETRIC_TEST_PLAN.md, CircleBiometricAuth.java, patch_biometric.py, run_bio.sh
- `circleos-boot` - README.md, fetch-magiskboot.sh, magiskboot.sh, patch-boot.sh, patch_build_release.py
- `circleos-build` - modbuild.sh
- `circleos-butler-mesh` - MeshServiceConnection.java, patch_butler_mesh.py
- `circleos-butler-voice` - ChatActivity.java, Personality.java, activity_chat.xml, ic_mic.xml, patch_voice.py
- `circleos-camera` - Android.bp, AndroidManifest.xml, patch_reg.py, res, src
- `circleos-castscreen` - Android.bp, AndroidManifest.xml, patch_reg.py, res, src
- `circleos-circleplay` - Android.bp, AndroidManifest.xml, patch_reg.py, res, src
- `circleos-commute` - Android.bp, AndroidManifest.xml, patch_reg.py, res, src
- `circleos-console` - Android.bp, AndroidManifest.xml, ConsoleActivity.java
- `circleos-datasense` - Android.bp, AndroidManifest.xml, patch_reg.py, res, src
- `circleos-desktop` - Android.bp, AndroidManifest.xml, patch_reg.py, res, src
- `circleos-dist` - README.md, make_torrent.py, sign-release.sh
- `circleos-endpoints` - CircleEndpoints.java, CircleEndpointsTest.java, TESTS_README.md, endpoints.json, patch_commonmk.py, place.sh
- `circleos-findmy` - Android.bp, AndroidManifest.xml, patch_reg.py, res, src
- `circleos-glance` - Android.bp, AndroidManifest.xml, patch_reg.py, res, src
- `circleos-harden` - README.md, board-hardening.mk, fetch-hardened-malloc.sh, hardening.mk
- `circleos-heyb` - Android.bp, AndroidManifest.xml, patch_reg.py, res, src
- `circleos-installer` - INSTALL_GUIDE.md, install-circleos.sh
- `circleos-keyboard` - Android.bp, AndroidManifest.xml, patch_reg.py, res, src
- `circleos-kids` - Android.bp, AndroidManifest.xml, patch_reg.py, res, src
- `circleos-launcher-skin` - drawable, layout, lockscreen, patch_launcher.py, patch_wp12.py, patch_wp78.py, systemui, values
- `circleos-magisk` - README.md, build-module.sh, customize.sh, module.prop, post-fs-data.sh, sepolicy.rule, service.sh, system.prop ...
- `circleos-mail` - Android.bp, AndroidManifest.xml, MailBridge.java, MailCrypto.java, key_directory.py, patch_mail.py, patch_reg.py, res ...
- `circleos-maps` - CircleMapsActivity.java
- `circleos-me` - Android.bp, AndroidManifest.xml, patch_reg.py, res, src
- `circleos-meshcrypto` - ConversationActivity.java, MeshCrypto.java, MeshMessageReceiver.java, PendingStore.java
- `circleos-meshlink` - MeshLinkPrivacy.java, MeshLinkTest.java, patch_mesh_link.py, run_meshlink.sh
- `circleos-meshpriv` - THREAT_MODEL.md, patch_mesh_privacy.py
- `circleos-meshrx` - patch_mesh_receive.py, run_meshrx.sh
- `circleos-music` - Android.bp, AndroidManifest.xml, MusicActivity.java, patch_reg.py, res, src
- `circleos-notebook` - Android.bp, AndroidManifest.xml, butler, patch_reg.py, res, src
- `circleos-notes` - Android.bp, AndroidManifest.xml, patch_common.py, res, src
- `circleos-ota` - README.md, ota_server.py, publish-release.py
- `circleos-panik` - patch_panik.py, run_panik.sh
- `circleos-people` - Android.bp, AndroidManifest.xml, patch_reg.py, res, src
- `circleos-perm` - patch_perm_enforce.py, run_perm.sh
- `circleos-photos` - Android.bp, AndroidManifest.xml, patch_reg.py, res, src
- `circleos-play` - CirclePlayActivity.java, Ownership.java
- `circleos-podcasts` - Android.bp, AndroidManifest.xml, patch_reg.py, res, src
- `circleos-quickshare` - Android.bp, AndroidManifest.xml, patch_reg.py, res, src
- `circleos-quiethours` - Android.bp, AndroidManifest.xml, patch_reg.py, res, src
- `circleos-ratchet` - DoubleRatchet.java, MeshCrypto.java, RatchetSelfTest.java, repackage_butler.py
- `circleos-reader` - Android.bp, AndroidManifest.xml, patch_reg.py, res, src
- `circleos-reminders` - Android.bp, AndroidManifest.xml, patch_reg.py, res, src
- `circleos-render` - libcircleplay_render.cpp
- `circleos-rooms` - Android.bp, AndroidManifest.xml, patch_reg.py, res, src
- `circleos-rooms-e2e` - RoomBridge.java, RoomCrypto.java
- `circleos-router` - MeshRouter.java, MeshRouterTest.java, patch_router_integrate.py, run_router.sh
- `circleos-runtime` - Android.bp, AndroidManifest.xml, NativePack.java, README.md, RuntimeActivity.java, RuntimeSession.java, SurfaceBridge.java, fetch-runtime.sh
- `circleos-saf` - patch_store_forward.py, run_saf.sh
- `circleos-security` - Android.bp, AndroidManifest.xml, CircleSecurityService.java, patch_reg.py, patch_sec.py, res, src
- `circleos-start` - Android.bp, AndroidManifest.xml, CircleStartActivity.java, TileStore.java, patch_commonmk.py
- `circleos-strict` - patch_strict.py
- `circleos-torrent` - README.md, make-torrent.sh
- `circleos-update` - CrashReporter.java, DeviceEnrollment.java, patch_crash.py, patch_enroll.py
- `circleos-vault` - KeyVault.java, SealEnvelope.java, SealEnvelopeTest.java
- `circleos-wallet` - ShongololoWalletService.java, commit_app.sh, commit_fw.sh, patch_wallet_app.py, patch_wallet_wire.py, place_wallet.sh
- `circleos-wallettest` - WalletFrame.java, WalletFrameTest.java, WalletMath.java, WalletMathTest.java, patch_wallet_wire.py, recon.sh, run_wire.sh
- `circleos-wifi` - patch_wifi_p2p.py, run_wifi.sh
- `circleos_work` - circleos_telemetry_service.cfg, circleos_telemetry_service.cpp, circleos_telemetry_service.json, launcher_BUILD.gn, main.cpp, push.py
