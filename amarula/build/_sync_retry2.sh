#!/usr/bin/env bash
# Retry the 2 stubborn repos: docs and av_codec.
set -uo pipefail

cd /root/ohos
for p in docs foundation/multimedia/av_codec; do
  echo "=== retrying $p (attempt with retry-fetches=3) ==="
  repo sync -c --force-sync -j1 --retry-fetches=3 "$p" 2>&1 | tail -15
done
echo "RETRY2_DONE"
