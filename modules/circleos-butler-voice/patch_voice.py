#!/usr/bin/env python3
# Add the mic content-description string + RECORD_AUDIO permission for voice.
import sys

# 1. strings.xml — add cd_mic
SF = "res/values/strings.xml"
s = open(SF, encoding="utf-8").read()
if 'name="cd_mic"' in s:
    print("strings already has cd_mic")
else:
    anchor = '<string name="send">Send</string>'
    if anchor not in s:
        print("FAIL: strings anchor not found")
        sys.exit(1)
    s = s.replace(anchor, anchor + '\n    <string name="cd_mic">Speak</string>', 1)
    open(SF, "w", encoding="utf-8").write(s)
    print("strings wired")

# 2. AndroidManifest.xml — add RECORD_AUDIO
MF = "AndroidManifest.xml"
m = open(MF, encoding="utf-8").read()
if "RECORD_AUDIO" in m:
    print("manifest already has RECORD_AUDIO")
else:
    anchor = '<uses-permission android:name="android.permission.INTERNET" />'
    if anchor not in m:
        print("FAIL: manifest anchor not found")
        sys.exit(1)
    m = m.replace(anchor,
                  anchor + '\n    <uses-permission android:name="android.permission.RECORD_AUDIO" />',
                  1)
    open(MF, "w", encoding="utf-8").write(m)
    print("manifest wired")
