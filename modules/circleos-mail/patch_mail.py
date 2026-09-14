#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Initialise the MailCrypto singleton in MailActivity.onCreate. Run from the CircleMail app dir.
import sys
CA = "src/za/co/circleos/mail/MailActivity.java"
s = open(CA, encoding="utf-8").read()
if "MailCrypto.init" in s:
    print("MailActivity already inits MailCrypto"); sys.exit(0)
lines = s.split("\n")
out, done = [], False
for ln in lines:
    out.append(ln)
    if (not done) and "super.onCreate(" in ln:
        indent = ln[:len(ln) - len(ln.lstrip())]
        out.append(indent + "MailCrypto.init(getApplicationContext());")
        done = True
if not done:
    print("FAIL: super.onCreate not found"); sys.exit(1)
open(CA, "w", encoding="utf-8").write("\n".join(out))
print("MailActivity wired MailCrypto.init")
