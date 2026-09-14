#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Wire MeshLinkPrivacy into CircleMeshService: rotating BLE service UUID + link
# encryption of every frame on the air (closes the BLE-fingerprint + cleartext-
# envelope gaps).
import sys
F = "frameworks/base/services/core/java/com/circleos/server/mesh/CircleMeshService.java"
s = open(F, encoding="utf-8").read()
if "currentServiceUuid" in s:
    print("already wired"); sys.exit(0)

# 1) rotating UUID at the scan filter + the GATT service lookup
if "new ParcelUuid(CIRCLE_MESH_BLE_SVC_UUID)" not in s or "gatt.getService(CIRCLE_MESH_BLE_SVC_UUID)" not in s:
    print("FAIL: UUID use-sites not found"); sys.exit(1)
s = s.replace("new ParcelUuid(CIRCLE_MESH_BLE_SVC_UUID)", "new ParcelUuid(currentServiceUuid())", 1)
s = s.replace("gatt.getService(CIRCLE_MESH_BLE_SVC_UUID)", "gatt.getService(currentServiceUuid())", 1)

# 2) link-encrypt the frame before the BLE write
old_set = "                    ch.setValue(frame);\n"
if old_set not in s:
    print("FAIL: ch.setValue(frame) not found"); sys.exit(1)
new_set = (
    "                    // Link-layer encrypt: the envelope is opaque on the air to any\n"
    "                    // non-Circle observer (defeats fingerprinting + metadata capture).\n"
    "                    final byte[] wire = MeshLinkPrivacy.linkEncrypt(\n"
    "                            MeshLinkPrivacy.currentEpoch(System.currentTimeMillis()), frame);\n"
    "                    if (wire == null) { gatt.close(); return; }\n"
    "                    ch.setValue(wire);\n"
)
s = s.replace(old_set, new_set, 1)

# 3) the helper
anchor = "    private static String generateDeviceId() {"
if anchor not in s:
    print("FAIL: generateDeviceId anchor not found"); sys.exit(1)
helper = (
    "    /** Current rotating BLE service UUID (daily; unguessable without the network key),\n"
    "     *  so a passive scanner can't fingerprint the device as Circle. */\n"
    "    private UUID currentServiceUuid() {\n"
    "        return MeshLinkPrivacy.serviceUuid(MeshLinkPrivacy.currentEpoch(System.currentTimeMillis()));\n"
    "    }\n\n"
)
s = s.replace(anchor, helper + anchor, 1)

open(F, "w", encoding="utf-8").write(s)
print("MeshLinkPrivacy wired: rotating UUID + link encryption")
