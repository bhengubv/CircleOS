#!/usr/bin/env bash
set -e
cd /home/geektrading/aosp/vendor/circle
mkdir -p aidl/android/circleos config
base64 -d /tmp/ce.b64 > aidl/android/circleos/CircleEndpoints.java
base64 -d /tmp/ep.b64 > config/endpoints.json
rm -f /tmp/ce.b64 /tmp/ep.b64
echo "=== placed ==="
wc -l aidl/android/circleos/CircleEndpoints.java config/endpoints.json
python3 -c "s=open('aidl/android/circleos/CircleEndpoints.java').read(); print('braces',s.count(chr(123))-s.count(chr(125)),'parens',s.count(chr(40))-s.count(chr(41)))"
python3 -c "import json;json.load(open('config/endpoints.json'));print('endpoints.json: valid JSON')"
echo "=== android.circleos-java glob covers it? ==="
grep -n "android/circleos/\*.java" aidl/Android.bp || echo "  (glob NOT found - would need Android.bp src add)"
echo "=== common.mk anchors ==="
grep -n "PRODUCT_COPY_FILES\|PRODUCT_PACKAGES *+=\|inherit" config/common.mk | head
