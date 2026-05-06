#!/usr/bin/env bash
# Amarula — WSL2 Ubuntu toolchain setup. Run once.
# Tested path: Ubuntu 22.04 / 24.04 in WSL2.
set -euo pipefail

echo "[amarula/setup] updating apt..."
sudo apt update
sudo apt install -y \
  git git-lfs git-core curl wget gnupg \
  build-essential ninja-build gcc g++ gcc-multilib g++-multilib make cmake pkg-config \
  python3 python3-pip python3-setuptools python3-venv scons \
  ruby ruby-dev \
  ccache \
  default-jdk openjdk-8-jdk \
  zip unzip xz-utils bzip2 cpio tar \
  libssl-dev libffi-dev libncurses5 libncurses5-dev libncursesw5-dev libtinfo5 \
  zlib1g-dev lib32z-dev lib32z1-dev lib32ncurses5-dev libc6-dev-i386 \
  libxml2-dev libxml2-utils libelf-dev libgl1-mesa-dev libdwarf-dev \
  bc bison flex gperf m4 xsltproc gnutls-bin \
  device-tree-compiler u-boot-tools mtd-utils genext2fs \
  liblz4-tool doxygen texinfo dosfstools mtools xxd \
  rsync locales apt-utils

echo "[amarula/setup] configuring locale..."
sudo locale-gen en_US.UTF-8

echo "[amarula/setup] installing repo tool..."
if ! command -v repo >/dev/null 2>&1; then
  curl -sSL https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo
  chmod +x /usr/local/bin/repo
fi

echo "[amarula/setup] configuring ccache (50GB)..."
ccache -M 50G || true
mkdir -p "$HOME/.ccache"

echo "[amarula/setup] configuring git for repo..."
git config --global user.name  "${GIT_USER_NAME:-Circle Dev}"
git config --global user.email "${GIT_USER_EMAIL:-dev@thegeek.co.za}"
git config --global color.ui   auto

echo "[amarula/setup] done."
echo "next: run ./sync.sh to pull OH 6.1 source into ~/ohos"
