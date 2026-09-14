#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Register CircleStart in PRODUCT_PACKAGES. Run from AOSP root.
import sys
F = "vendor/circle/config/common.mk"
s = open(F, encoding="utf-8").read()
if "CircleStart" in s:
    print("CircleStart already registered"); sys.exit(0)
anchor = "    CirclePhotos \\\n"
if anchor not in s:
    print("FAIL: CirclePhotos anchor not found"); sys.exit(1)
open(F, "w", encoding="utf-8").write(s.replace(anchor, anchor + "    CircleStart \\\n", 1))
print("CircleStart registered in PRODUCT_PACKAGES")
