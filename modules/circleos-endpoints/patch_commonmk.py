#!/usr/bin/env python3
import sys
F = "config/common.mk"
s = open(F, encoding="utf-8").read()
if "endpoints.json" in s:
    print("already wired"); sys.exit(0)
anchor = "    vendor/circle/wallpapers/mesh_dark.png:$(TARGET_COPY_OUT_PRODUCT)/media/wallpaper/mesh_dark.png"
if anchor not in s:
    print("FAIL: anchor"); sys.exit(1)
block = (anchor +
    "\n\n# Circle OS central API endpoint -- read at runtime; repointable via OTA/config push (no rebuild)\n"
    "PRODUCT_COPY_FILES += \\\n"
    "    vendor/circle/config/endpoints.json:$(TARGET_COPY_OUT_SYSTEM)/etc/circle/endpoints.json")
s = s.replace(anchor, block, 1)
open(F, "w", encoding="utf-8").write(s)
print("wired endpoints.json -> /system/etc/circle/endpoints.json")
