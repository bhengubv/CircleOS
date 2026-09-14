#!/usr/bin/env python3
# Register CircleGlance in vendor/circle/config/common.mk PRODUCT_PACKAGES.
import re, sys

F = "config/common.mk"
s = open(F, encoding="utf-8").read()
if re.search(r'\bCircleGlance\b', s):
    print("CircleGlance already present in common.mk")
    sys.exit(0)
for anchor in ["CircleDesktop", "CircleAR", "CircleProjectScreen", "CircleCommute", "CircleLauncher"]:
    m = re.search(r'^([ \t]*)' + anchor + r'[ \t]*\\[ \t]*$', s, re.M)
    if m:
        indent = m.group(1)
        s = s[:m.end()] + "\n" + indent + "CircleGlance \\" + s[m.end():]
        open(F, "w", encoding="utf-8").write(s)
        print("Inserted CircleGlance after " + anchor)
        sys.exit(0)
print("FAIL: no PRODUCT_PACKAGES anchor found in common.mk")
sys.exit(1)
