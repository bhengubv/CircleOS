# circleos-gsi devcontainer
# Reproducible AOSP build host: Ubuntu 24.04 + AOSP deps + Clang + Rust + Android SDK platform-tools.
# Match this image to .201 (Ubuntu 24.04) so builds are bit-identical between dev and CI.

FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# ---- AOSP build essentials (per source.android.com initial setup) ----
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl wget unzip zip rsync git gnupg \
        build-essential bc bison flex \
        python3 python3-distutils python3-pip \
        libc6-dev libncurses-dev libssl-dev libgl1 libxml2-utils \
        openjdk-21-jdk-headless \
        ccache fontconfig \
        clang lld llvm \
    && rm -rf /var/lib/apt/lists/*

# ---- repo (AOSP source tool) ----
RUN curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo \
        -o /usr/local/bin/repo \
    && chmod +x /usr/local/bin/repo

# ---- Rust (for native components: ramdisk helpers, Aether daemon glue) ----
RUN curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs \
    | sh -s -- -y --default-toolchain stable --profile minimal
ENV PATH="/root/.cargo/bin:${PATH}"

# ---- Android SDK command-line tools + platform-tools (adb, fastboot) ----
ENV ANDROID_SDK_ROOT=/opt/android-sdk
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools \
    && curl -fsSL https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
        -o /tmp/cmdline.zip \
    && unzip -q /tmp/cmdline.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools \
    && mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
    && rm /tmp/cmdline.zip
ENV PATH="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

RUN yes | sdkmanager --licenses >/dev/null 2>&1 || true \
    && sdkmanager --install "platform-tools" >/dev/null

# ---- ccache config (huge speedup on rebuilds) ----
RUN ccache --max-size=50G && ccache --set-config compression=true

WORKDIR /workspace
