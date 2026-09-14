#!/usr/bin/env bash
cd /home/geektrading/aosp
{
  echo "BUILD_START $(date -u)"
  source build/envsetup.sh
  lunch circle_arm64-trunk_staging-userdebug
  export USE_CCACHE=1
  export CCACHE_EXEC=/usr/bin/ccache
  m -j4 services android.circleos-java circleos-sdpkt-aidl SdpktTitanium Panik
  rc=$?
  echo "BUILD_RC=$rc"
  echo "BUILD_DONE $(date -u)"
} > /tmp/circle_modbuild.log 2>&1
