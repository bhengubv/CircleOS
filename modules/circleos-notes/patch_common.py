#!/usr/bin/env python3
# Register CircleNotes in vendor/circle/config/common.mk PRODUCT_PACKAGES.
import re, sys

F = "config/common.mk"
s = open(F, encoding="utf-8").read()

if re.search(r'\bCircleNotes\b', s):
    print("CircleNotes already present in common.mk")
    sys.exit(0)

inserted = False
for anchor in ["CircleMessages", "CircleLauncher", "CircleOsSettings", "CircleMaps", "Panik", "Bruh"]:
    m = re.search(r'^([ \t]*)' + anchor + r'[ \t]*\\[ \t]*$', s, re.M)
    if m:
        indent = m.group(1)
        s = s[:m.end()] + "\n" + indent + "CircleNotes \\" + s[m.end():]
        open(F, "w", encoding="utf-8").write(s)
        print("Inserted CircleNotes after " + anchor)
        inserted = True
        break

if not inserted:
    print("FAIL: no PRODUCT_PACKAGES continuation anchor found in common.mk")
    sys.exit(1)
