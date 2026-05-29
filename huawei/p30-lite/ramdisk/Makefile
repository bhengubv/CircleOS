# Cross-compile the CircleOS boot-selector init for aarch64 Linux.
#
# Static-linked against musl so the binary has zero shared-library
# dependencies — it runs as PID 1 before any system libs exist.
#
# Default target: `make init`.
# Requires one of these aarch64 cross-toolchains on $PATH:
#   - aarch64-linux-musl-gcc   (preferred; smallest binary, ~30 KB)
#   - aarch64-linux-gnu-gcc    (fallback; larger binary, requires --static)
#
# To install on Ubuntu 22.04+:
#   sudo apt install musl-tools                            # gives x86_64
#   # For aarch64 cross — fetch from https://musl.cc :
#   wget https://musl.cc/aarch64-linux-musl-cross.tgz
#   tar xf aarch64-linux-musl-cross.tgz
#   export PATH=$PWD/aarch64-linux-musl-cross/bin:$PATH

# Auto-detect a cross-compiler. Musl preferred, fall back to gnu.
CC_MUSL := $(shell command -v aarch64-linux-musl-gcc 2>/dev/null)
CC_GNU  := $(shell command -v aarch64-linux-gnu-gcc 2>/dev/null)

ifneq ($(CC_MUSL),)
    CC := $(CC_MUSL)
    TOOLCHAIN := musl
else ifneq ($(CC_GNU),)
    CC := $(CC_GNU)
    TOOLCHAIN := gnu
else
    $(error "No aarch64 cross-compiler found. Install aarch64-linux-musl-gcc (preferred) or aarch64-linux-gnu-gcc.")
endif

CFLAGS  := -Os -Wall -Wextra -Wpedantic \
           -ffunction-sections -fdata-sections \
           -fno-stack-protector \
           -static
LDFLAGS := -Wl,--gc-sections -static -s

OUT := init

.PHONY: all clean check info

all: $(OUT)

$(OUT): init.c
	@echo ">>> building with $(CC) ($(TOOLCHAIN))"
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
	@echo ">>> size:"
	@size $@ || true
	@echo ">>> file:"
	@file $@ || true

check: $(OUT)
	@# Ensure the binary is a fully-static aarch64 ELF.
	@file $(OUT) | grep -qE "ELF 64-bit LSB.*aarch64|ELF 64-bit LSB.*ARM aarch64" \
	    || (echo "ERROR: not aarch64"; exit 1)
	@file $(OUT) | grep -q "statically linked" \
	    || (echo "ERROR: not statically linked"; exit 1)
	@echo ">>> checks passed: aarch64, static."

clean:
	rm -f $(OUT)

info:
	@echo "CC        = $(CC)"
	@echo "TOOLCHAIN = $(TOOLCHAIN)"
	@echo "CFLAGS    = $(CFLAGS)"
	@echo "LDFLAGS   = $(LDFLAGS)"
