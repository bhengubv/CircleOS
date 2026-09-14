#!/usr/bin/env python3
# Register CircleReminders in vendor/circle/config/common.mk PRODUCT_PACKAGES.
import re, sys

F = "config/common.mk"
s = open(F, encoding="utf-8").read()
if re.search(r'\bCircleReminders\b', s):
    print("CircleReminders already present in common.mk")
    sys.exit(0)
for anchor in ["CirclePodcasts", "CirclePeople", "CircleNotes", "CircleMessages", "CircleLauncher"]:
    m = re.search(r'^([ \t]*)' + anchor + r'[ \t]*\\[ \t]*$', s, re.M)
    if m:
        indent = m.group(1)
        s = s[:m.end()] + "\n" + indent + "CircleReminders \\" + s[m.end():]
        open(F, "w", encoding="utf-8").write(s)
        print("Inserted CircleReminders after " + anchor)
        sys.exit(0)
print("FAIL: no PRODUCT_PACKAGES anchor found in common.mk")
sys.exit(1)
