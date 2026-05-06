#!/usr/bin/env bash
# Retry failed repo-sync projects sequentially.
set -uo pipefail

cd /root/ohos
for p in docs foundation/multimedia/av_codec foundation/multimedia/image_framework test/xts/acts; do
  echo "=== retrying $p ==="
  repo sync -c --force-sync -j1 "$p" 2>&1 | tail -10
done
echo "RETRY_DONE"
