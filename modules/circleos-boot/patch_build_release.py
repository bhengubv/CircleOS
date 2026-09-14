#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Add a guarded magiskboot boot-image sanity gate to build_release.sh (#151).
# Run from vendor/circle.
import sys

F = "release/build_release.sh"
s = open(F, encoding="utf-8").read()
if "magiskboot.sh" in s:
    print("build_release.sh already has the magiskboot gate")
    sys.exit(0)

anchor = (
    '# Checksums\n'
    'sha256sum "${RELEASE_DIR_DEVICE}/payload.bin" > "${RELEASE_DIR_DEVICE}/payload.bin.sha256"\n'
)
if anchor not in s:
    print("FAIL: checksums anchor not found"); sys.exit(1)

gate = (
    '# Checksums\n'
    'sha256sum "${RELEASE_DIR_DEVICE}/payload.bin" > "${RELEASE_DIR_DEVICE}/payload.bin.sha256"\n'
    '\n'
    '# Sanity-verify the built boot image with magiskboot (#151). Non-fatal: skips\n'
    '# cleanly if magiskboot is not installed (run vendor/circle/dist/boot/fetch-magiskboot.sh).\n'
    'BOOT_IMG="${OUT_DIR}/boot.img"\n'
    'MAGISKBOOT_SH="vendor/circle/dist/boot/magiskboot.sh"\n'
    'if [ -f "${BOOT_IMG}" ] && "${MAGISKBOOT_SH}" path >/dev/null 2>&1; then\n'
    '    echo "Verifying boot image with magiskboot..."\n'
    '    "${MAGISKBOOT_SH}" verify "${BOOT_IMG}" || echo "WARN: boot image failed magiskboot verify"\n'
    'else\n'
    '    echo "Skipping magiskboot boot-image check (not installed or no boot.img)."\n'
    'fi\n'
)
s = s.replace(anchor, gate, 1)
open(F, "w", encoding="utf-8").write(s)
print("build_release.sh gate added")
