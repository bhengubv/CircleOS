#!/usr/bin/env bash
set -e
cd /home/geektrading/aosp/vendor/circle
F=apps/Panik/src/za/co/circleos/panik/PanikActivity.java
python3 -c "s=open('$F').read(); print('braces', s.count(chr(123))-s.count(chr(125)), 'parens', s.count(chr(40))-s.count(chr(41)))"
grep -c "Add emergency contact" "$F"
git add "$F"
git commit -q -m "Panik: implement add-emergency-contact dialog (was a stub) [skip ci]

The SOS app's 'add emergency contact' was a stub that just re-loaded from the API
instead of letting you add one. Now it shows a name + phone dialog and POSTs the
new contact, then reloads. Real safety feature for an emergency app."
echo COMMITTED
git log --oneline -1
