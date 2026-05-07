#!/usr/bin/env bash
# Prepare geektrading2 for OpenHarmony 5.1 builds.
# Steps 1 + 2: extend LV to use full disk, install build deps.
# DOES NOT clone OH source (Step 3 deferred).
set -uo pipefail

# Cache sudo credentials for ~15 min so we don't echo password 20 times
echo "$SUDO_PWD" | sudo -S -v
sudo -v -p "" || { echo "sudo auth failed"; exit 1; }

echo "=== STEP 1: extend LVM to use full disk ==="
echo "--- before ---"
df -h /
sudo vgs
sudo lvs

# Extend the only LV to fill the volume group
sudo lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv 2>&1 | tail -5
sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv 2>&1 | tail -3

echo "--- after ---"
df -h /

echo
echo "=== STEP 2: apt update + install build deps ==="
sudo DEBIAN_FRONTEND=noninteractive apt-get update -q 2>&1 | tail -3
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install \
  build-essential \
  gcc-multilib g++-multilib \
  git curl wget \
  python3 python3-pip python3-venv python3-dev \
  ccache \
  bc bison flex \
  libssl-dev libffi-dev libgmp-dev libmpfr-dev libmpc-dev \
  gettext gawk ruby \
  libelf-dev \
  m4 perl \
  xz-utils zip unzip \
  zlib1g-dev \
  texinfo \
  bzip2 \
  rsync \
  cpio \
  device-tree-compiler \
  u-boot-tools \
  earlyoom \
  sshpass \
  htop \
  jq 2>&1 | tail -3

echo
echo "=== STEP 2b: install repo tool ==="
mkdir -p ~/.local/bin
curl -sS https://storage.googleapis.com/git-repo-downloads/repo > ~/.local/bin/repo
chmod +x ~/.local/bin/repo
grep -q '$HOME/.local/bin' ~/.bashrc 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
echo "repo installed: $(~/.local/bin/repo --version 2>/dev/null | head -1 || echo 'check failed')"

echo
echo "=== VERIFY ==="
echo "--- versions ---"
git --version
python3 --version
ccache --version | head -1
echo "node: $(which node 2>/dev/null || echo 'not on host — OH ships own in prebuilts')"
echo
echo "--- disk ---"
df -h /
echo
echo "--- mem ---"
free -h
echo
echo "--- ccache config ---"
ccache --version | head -1
ccache -M 50G 2>&1 | head -1
ccache --set-config compression=true
ccache --set-config compression_level=6
ccache --show-config 2>/dev/null | grep -E "max_size|compression" | head -5

echo
echo "=== READY (Step 3 deferred — OH source clone not run) ==="
