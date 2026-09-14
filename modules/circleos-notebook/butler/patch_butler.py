#!/usr/bin/env python3
# Wire NotebookSkill into Butler: ChatActivity dispatch + manifest permission.
import sys

# 1. ChatActivity — insert the notebook dispatch block before mInference.generate.
CA = "src/za/co/circleos/butler/ChatActivity.java"
s = open(CA, encoding="utf-8").read()
if "NotebookSkill.tryHandle" in s:
    print("ChatActivity already wired")
else:
    block = (
        "        // Notebook: let the user tell B! what to remember / forget / recall\n"
        "        String noteAnswer = NotebookSkill.tryHandle(this, text);\n"
        "        if (noteAnswer != null) {\n"
        "            final String answer = noteAnswer;\n"
        "            mUiHandler.post(() -> {\n"
        "                if (mPendingIndex >= 0 && mPendingIndex < mMessages.size()) {\n"
        "                    mMessages.get(mPendingIndex).text = answer;\n"
        "                    mMessages.get(mPendingIndex).isThinking = false;\n"
        "                    mAdapter.notifyDataSetChanged();\n"
        "                }\n"
        "                mPendingIndex = -1;\n"
        "                mGenerating = false;\n"
        "                mBtnSend.setEnabled(true);\n"
        "            });\n"
        "            return;\n"
        "        }\n\n"
    )
    anchor = "        mInference.generate(text, SYSTEM_PROMPT,"
    idx = s.find(anchor)
    if idx < 0:
        print("FAIL: mInference.generate anchor not found")
        sys.exit(1)
    s = s[:idx] + block + s[idx:]
    open(CA, "w", encoding="utf-8").write(s)
    print("ChatActivity wired")

# 2. Manifest — grant the Notebook access permission (signature; platform-signed).
MF = "AndroidManifest.xml"
m = open(MF, encoding="utf-8").read()
if "ACCESS_NOTEBOOK" in m:
    print("Manifest already has ACCESS_NOTEBOOK")
else:
    anchor = '<uses-permission android:name="com.circleos.permission.ACCESS_INFERENCE" />'
    if anchor not in m:
        print("FAIL: manifest anchor not found")
        sys.exit(1)
    m = m.replace(anchor,
                  anchor + '\n    <uses-permission android:name="com.circleos.permission.ACCESS_NOTEBOOK" />',
                  1)
    open(MF, "w", encoding="utf-8").write(m)
    print("Manifest wired")

# 3. Sanity — does Android.bp glob src so NotebookSkill.java compiles in?
bp = open("Android.bp", encoding="utf-8").read()
print("BP_GLOB:", ("src/**/*.java" in bp) or ('"src/' in bp and "**/*.java" in bp))
