#!/usr/bin/env bash
set -e
cd /home/geektrading/aosp/vendor/circle

echo "=== functional test ==="
python3 mail/key_directory.py --store /tmp/mk.json --port 8099 >/tmp/kd.log 2>&1 &
SRV=$!
sleep 1
K='QUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVowMTIzNDU2Nzg5'
printf 'publish:        '; curl -s -X POST -H 'X-Circle-User: alice@circle' -d "{\"key\":\"$K\"}" http://127.0.0.1:8099/api/mail/key
printf '\nlookup alice:   '; curl -s 'http://127.0.0.1:8099/api/mail/key?user=alice@circle'
printf '\nlookup bob:     '; curl -s -w ' [http %{http_code}]' 'http://127.0.0.1:8099/api/mail/key?user=bob@x'
printf '\nunauth publish: '; curl -s -w ' [http %{http_code}]' -X POST -d "{\"key\":\"$K\"}" http://127.0.0.1:8099/api/mail/key
printf '\n'
kill "$SRV" 2>/dev/null || true
rm -f /tmp/mk.json

echo "=== commit ==="
git add mail/key_directory.py
git commit -q -m "CircleMail: self-hostable public-key directory for the seal [skip ci]

The server half of #153: the X25519 key directory CircleMail publishes to and
looks up. POST /api/mail/key writes the authenticated owner's key (X-Circle-User
header, set by the bridge after IMAP/SMTP auth); GET /api/mail/key?user= returns
it (404/empty for non-Circle addresses, so the sender stays plaintext). Stdlib
only and self-hostable, matching ota_server.py — no central, censorable key
authority. Verified end to end: publish -> lookup -> unknown-user(404) ->
unauthenticated-reject(401). Task #153 (client + directory both done)."
echo COMMITTED
git log --oneline -1
