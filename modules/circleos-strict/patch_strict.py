#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Wire strict no-plaintext-receive into CircleMessages. Run from the CircleMessages app dir.
import sys

# 1) MeshMessageReceiver: drop unencrypted messages when strict mode is on.
MR = "src/za/co/circleos/messages/MeshMessageReceiver.java"
r = open(MR, encoding="utf-8").read()
if "isStrictReceive" in r:
    print("MeshMessageReceiver already strict-aware")
else:
    old = (
        "        // ── Legacy plaintext (back-compat) ──\n"
        "        deliver(context, senderId, wire);"
    )
    new = (
        "        // ── Unencrypted: a pre-E2E build or an injection attempt ──\n"
        "        if (crypto.isStrictReceive()) {\n"
        "            Log.w(TAG, \"Dropped unencrypted message from \" + senderId + \" (strict mode)\");\n"
        "            return;\n"
        "        }\n"
        "        deliver(context, senderId, wire);"
    )
    if old not in r:
        print("FAIL: MeshMessageReceiver plaintext branch not matched"); sys.exit(1)
    open(MR, "w", encoding="utf-8").write(r.replace(old, new, 1))
    print("MeshMessageReceiver wired")

# 2) ConversationActivity: add a checkable "Block unencrypted messages" menu item.
CA = "src/za/co/circleos/messages/ConversationActivity.java"
s = open(CA, encoding="utf-8").read()
if "Block unencrypted" in s:
    print("ConversationActivity already has the toggle")
    sys.exit(0)

old_menu = (
    "    public boolean onCreateOptionsMenu(Menu menu) {\n"
    "        menu.add(0, 1, 0, \"Verify security code\");\n"
    "        return true;\n"
    "    }"
)
new_menu = (
    "    public boolean onCreateOptionsMenu(Menu menu) {\n"
    "        menu.add(0, 1, 0, \"Verify security code\");\n"
    "        MenuItem strict = menu.add(0, 2, 1, \"Block unencrypted messages\");\n"
    "        strict.setCheckable(true);\n"
    "        strict.setChecked(mCrypto != null && mCrypto.isStrictReceive());\n"
    "        return true;\n"
    "    }"
)
if old_menu not in s:
    print("FAIL: onCreateOptionsMenu not matched"); sys.exit(1)
s = s.replace(old_menu, new_menu, 1)

old_sel = (
    "        if (item.getItemId() == 1) {\n"
    "            showSecurityCode();\n"
    "            return true;\n"
    "        }\n"
    "        return super.onOptionsItemSelected(item);"
)
new_sel = (
    "        if (item.getItemId() == 1) {\n"
    "            showSecurityCode();\n"
    "            return true;\n"
    "        }\n"
    "        if (item.getItemId() == 2) {\n"
    "            boolean now = !item.isChecked();\n"
    "            item.setChecked(now);\n"
    "            if (mCrypto != null) mCrypto.setStrictReceive(now);\n"
    "            Toast.makeText(this, now ? \"Unencrypted messages will be blocked\"\n"
    "                    : \"Unencrypted messages will be shown\", Toast.LENGTH_SHORT).show();\n"
    "            return true;\n"
    "        }\n"
    "        return super.onOptionsItemSelected(item);"
)
if old_sel not in s:
    print("FAIL: onOptionsItemSelected not matched"); sys.exit(1)
s = s.replace(old_sel, new_sel, 1)
open(CA, "w", encoding="utf-8").write(s)
print("ConversationActivity wired")
