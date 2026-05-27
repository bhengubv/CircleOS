#!/usr/bin/env bash
# circleos-gsi: host setup — install AOSP build deps on Ubuntu 22.04 / 24.04.
# Run with sudo. Idempotent.

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Run with sudo: sudo $0" >&2
    exit 1
fi

# shellcheck disable=SC1091
. /etc/os-release
if [ "${ID:-}" != "ubuntu" ]; then
    echo "WARNING: tested on Ubuntu (you have ID='${ID:-}'). Continuing in 3s — Ctrl-C to abort."
    sleep 3
fi

apt-get update
apt-get install -y --no-install-recommends \
    ca-certificates curl wget unzip zip rsync git gnupg \
    build-essential bc bison flex \
    python3 python3-setuptools python3-pip \
    libc6-dev libncurses-dev libssl-dev libgl1 libxml2-utils \
    openjdk-21-jdk-headless \
    ccache fontconfig \
    clang lld llvm

# repo tool — AOSP source manager
if [ ! -x /usr/local/bin/repo ]; then
    curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo \
        -o /usr/local/bin/repo
    chmod +x /usr/local/bin/repo
fi

# ccache config for the calling user (not root)
SUDO_USER_HOME=$(getent passwd "${SUDO_USER:-root}" | cut -d: -f6)
if [ -n "$SUDO_USER_HOME" ] && [ "$SUDO_USER" != "root" ]; then
    sudo -u "$SUDO_USER" ccache --max-size=50G || true
    sudo -u "$SUDO_USER" ccache --set-config compression=true || true
fi

echo ""
echo "[+] Host ready for AOSP build."
echo "[+] Disk free on /:    $(df -h / | tail -1 | awk '{print $4}')"
echo "[+] Java version:      $(java -version 2>&1 | head -1)"
echo "[+] repo version:      $(/usr/local/bin/repo --version 2>&1 | head -1)"
echo ""
echo "[+] Next: ./scripts/sync.sh   (fetches ~150 GB of AOSP source — multi-hour)"
