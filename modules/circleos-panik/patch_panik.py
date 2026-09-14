#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Panik: make "add emergency contact" actually add one (name+phone dialog -> POST).
import sys
F = "src/za/co/circleos/panik/PanikActivity.java"
s = open(F, encoding="utf-8").read()
if "Add emergency contact" in s:
    print("already implemented"); sys.exit(0)
old = (
    "    private void addEmergencyContact() {\n"
    "        // TODO: show dialog for name + phone input\n"
    "        // For now, load from API\n"
    "        loadContacts();\n"
    "    }")
if old not in s:
    print("FAIL: addEmergencyContact stub not matched"); sys.exit(1)
new = (
    "    private void addEmergencyContact() {\n"
    "        final android.widget.EditText name = new android.widget.EditText(this);\n"
    "        name.setHint(\"Name\");\n"
    "        final android.widget.EditText phone = new android.widget.EditText(this);\n"
    "        phone.setHint(\"Phone number\");\n"
    "        phone.setInputType(android.text.InputType.TYPE_CLASS_PHONE);\n"
    "        android.widget.LinearLayout box = new android.widget.LinearLayout(this);\n"
    "        box.setOrientation(android.widget.LinearLayout.VERTICAL);\n"
    "        final int pad = Math.round(20 * getResources().getDisplayMetrics().density);\n"
    "        box.setPadding(pad, pad, pad, 0);\n"
    "        box.addView(name);\n"
    "        box.addView(phone);\n"
    "        new android.app.AlertDialog.Builder(this)\n"
    "                .setTitle(\"Add emergency contact\")\n"
    "                .setView(box)\n"
    "                .setPositiveButton(\"Add\", (d, w) -> {\n"
    "                    final String n = name.getText().toString().trim();\n"
    "                    final String p = phone.getText().toString().trim();\n"
    "                    if (n.isEmpty() || p.isEmpty()) return;\n"
    "                    mExecutor.execute(() -> {\n"
    "                        try {\n"
    "                            JSONObject body = new JSONObject();\n"
    "                            body.put(\"name\", n);\n"
    "                            body.put(\"phone\", p);\n"
    "                            httpPost(API_BASE + \"/contacts\", body.toString());\n"
    "                        } catch (Exception ignored) {}\n"
    "                        runOnUiThread(this::loadContacts);\n"
    "                    });\n"
    "                })\n"
    "                .setNegativeButton(\"Cancel\", null)\n"
    "                .show();\n"
    "    }")
open(F, "w", encoding="utf-8").write(s.replace(old, new, 1))
print("Panik addEmergencyContact implemented")
