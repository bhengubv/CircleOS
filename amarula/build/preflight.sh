#!/usr/bin/env bash
# CircleOS Amarula build preflight.
# Validates everything we learned the hard way over 50+ hours of failed attempts.
#
# Usage:
#   bash preflight.sh         — read-only checks, exit 1 on first FAIL
#   bash preflight.sh --fix   — apply auto-fixes where safe (sudo prompts as needed)
#
# Exit codes:
#   0   all checks passed
#   1   at least one FAIL (build will not succeed)
#   2   preflight script bug

set -uo pipefail

MODE="${1:-check}"
PASS=0
FAIL=0
WARN=0
FIXES=()

log()  { printf "%-7s %s\n" "$1" "$2"; }
pass() { log "[PASS]" "$1"; PASS=$((PASS+1)); }
fail() { log "[FAIL]" "$1"; FAIL=$((FAIL+1)); }
warn() { log "[WARN]" "$1"; WARN=$((WARN+1)); }
fix()  { FIXES+=("$1"); }

echo "=== CircleOS Amarula preflight  $(date '+%F %T %Z') ==="
echo

# ---------- 1. Network ----------
echo "--- 1. Network reachability ---"

check_url() {
  local label="$1" url="$2"
  local code=$(curl -sI -o /dev/null -w "%{http_code}" --connect-timeout 8 "$url" 2>/dev/null || echo 000)
  if [ "$code" = "200" ] || [ "$code" = "301" ] || [ "$code" = "302" ]; then
    pass "$label reachable ($code)"
    return 0
  else
    fail "$label unreachable ($code) — $url"
    return 1
  fi
}

check_url "github.com"            https://github.com
check_url "github raw"            https://raw.githubusercontent.com
check_url "openharmony manifest"  https://github.com/openharmony/manifest
check_url "huawei prebuilts CDN"  https://repo.huaweicloud.com/openharmony/compiler/
check_url "npm registry"          https://registry.npmjs.org

# Probe gitee/gitcode — informational
GITEE_OK=$(curl -sI -o /dev/null -w "%{http_code}" --connect-timeout 5 https://gitee.com 2>/dev/null || echo 000)
if [ "$GITEE_OK" = "200" ] || [ "$GITEE_OK" = "301" ] || [ "$GITEE_OK" = "302" ]; then
  pass "gitee.com reachable (manifest works as-is)"
else
  warn "gitee.com unreachable — need git insteadOf redirect to github"
  fix "git config --global url.\"https://github.com/openharmony/\".insteadOf \"https://gitee.com/openharmony/\""
  fix "git config --global --add url.\"https://github.com/openharmony/\".insteadOf \"https://gitcode.com/openharmony/\""
fi

echo

# ---------- 2. System resources ----------
echo "--- 2. System resources ---"

CORES=$(nproc)
if [ "$CORES" -ge 4 ]; then pass "CPU cores: $CORES"
else fail "CPU cores: $CORES (need ≥ 4)"; fi

RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
if [ "$RAM_GB" -ge 16 ]; then pass "RAM: ${RAM_GB}GB"
elif [ "$RAM_GB" -ge 12 ]; then warn "RAM: ${RAM_GB}GB (16+ recommended)"
else fail "RAM: ${RAM_GB}GB (need ≥ 12GB)"; fi

SWAP_GB=$(free -g | awk '/^Swap:/{print $2}')
log "[INFO]" "Swap: ${SWAP_GB}GB"

DISK_FREE_GB=$(df --output=avail -BG / | tail -1 | tr -d ' G')
if [ "$DISK_FREE_GB" -ge 250 ]; then pass "Disk free: ${DISK_FREE_GB}GB"
elif [ "$DISK_FREE_GB" -ge 200 ]; then warn "Disk free: ${DISK_FREE_GB}GB (250+ recommended)"
else fail "Disk free: ${DISK_FREE_GB}GB (need ≥ 200GB)"; fi

echo

# ---------- 3. Kernel tuning ----------
echo "--- 3. Kernel tuning ---"

VMC=$(sysctl -n vm.max_map_count 2>/dev/null)
if [ "$VMC" -ge 262144 ]; then pass "vm.max_map_count: $VMC"
else
  fail "vm.max_map_count: $VMC (need ≥ 262144 for ThinLTO; llvm #48833)"
  fix "sudo sh -c 'echo vm.max_map_count = 1048576 >> /etc/sysctl.d/99-build.conf; sysctl -p /etc/sysctl.d/99-build.conf'"
fi

SWAPPINESS=$(sysctl -n vm.swappiness)
if [ "$SWAPPINESS" -le 10 ]; then pass "vm.swappiness: $SWAPPINESS"
else warn "vm.swappiness: $SWAPPINESS (10 recommended for build hosts)"; fi

OVERCOMMIT=$(sysctl -n vm.overcommit_memory)
if [ "$OVERCOMMIT" = "1" ]; then pass "vm.overcommit_memory: 1 (heuristic off)"
else warn "vm.overcommit_memory: $OVERCOMMIT (1 recommended)"; fi

echo

# ---------- 4. Build tools ----------
echo "--- 4. Build tools ---"

check_cmd() {
  local cmd="$1" min="${2:-}"
  if command -v "$cmd" >/dev/null 2>&1; then
    local v=$("$cmd" --version 2>&1 | head -1)
    pass "$cmd: $v"
  else
    fail "$cmd: not installed"
    fix "apt-get install -y $cmd"
  fi
}

check_cmd git
check_cmd python3
check_cmd ccache
check_cmd make
check_cmd gcc
check_cmd g++
check_cmd curl
check_cmd wget
check_cmd unzip
check_cmd rsync

# repo tool — special: usually in ~/.local/bin
if command -v repo >/dev/null 2>&1; then
  pass "repo: $(repo --version 2>/dev/null | head -1 || echo installed)"
elif [ -x "$HOME/.local/bin/repo" ]; then
  warn "repo found at ~/.local/bin/repo but not in PATH"
  fix "echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
else
  fail "repo: not installed"
  fix "mkdir -p ~/.local/bin && curl -sSL https://storage.googleapis.com/git-repo-downloads/repo > ~/.local/bin/repo && chmod +x ~/.local/bin/repo"
fi

echo

# ---------- 5. Build configuration ----------
echo "--- 5. Build configuration ---"

CCACHE_MAX=$(ccache --get-config max_size 2>/dev/null | head -1 || echo "")
if echo "$CCACHE_MAX" | grep -qE "[0-9]+G"; then
  CCACHE_GB=$(echo "$CCACHE_MAX" | grep -oE "[0-9]+" | head -1)
  if [ "$CCACHE_GB" -ge 30 ]; then pass "ccache max_size: $CCACHE_MAX"
  else warn "ccache max_size: $CCACHE_MAX (50G recommended)"; fi
else
  warn "ccache max_size not set (default 5G)"
  fix "ccache -M 50G"
fi

if ccache --get-config compression 2>/dev/null | grep -qi true; then
  pass "ccache compression: on"
else
  warn "ccache compression off (saves disk)"
  fix "ccache --set-config compression=true && ccache --set-config compression_level=6"
fi

# git http buffer — needed for large fetches
HBUF=$(git config --global http.postBuffer 2>/dev/null || echo 0)
if [ "$HBUF" -ge 1048576000 ]; then pass "git http.postBuffer: $HBUF"
else
  warn "git http.postBuffer: ${HBUF:-unset} (1GB recommended for large pushes)"
  fix "git config --global http.postBuffer 1048576000"
fi

if git config --global --get-all safe.directory | grep -q '\*'; then
  pass "git safe.directory: '*' allows any owner"
else
  warn "git safe.directory not set to '*' (repo forall may fail)"
  fix "git config --global --add safe.directory '*'"
fi

echo

# ---------- 6. CircleOS overlay ----------
echo "--- 6. CircleOS overlay ---"

CIRCLEOS_DIR="${CIRCLEOS_DIR:-$HOME/CircleOS}"
if [ -d "$CIRCLEOS_DIR/amarula" ]; then
  pass "CircleOS repo at $CIRCLEOS_DIR"

  for f in \
    amarula/build/overlay.sh \
    amarula/productdefine/amarula.json \
    amarula/_ohos_patches/build/toolchain/concurrent_links.gni \
    amarula/_ohos_patches/build/config/compiler/BUILD.gn
  do
    if [ -f "$CIRCLEOS_DIR/$f" ]; then pass "  $f"
    else fail "  missing: $CIRCLEOS_DIR/$f"; fi
  done
else
  fail "CircleOS repo not at $CIRCLEOS_DIR — clone it first"
  fix "git clone https://github.com/bhengubv/CircleOS.git $CIRCLEOS_DIR"
fi

echo

# ---------- 7. OHOS source tree (optional — present if already synced) ----------
echo "--- 7. OHOS source tree ---"

OHOS_DIR="${OHOS_DIR:-$HOME/ohos}"
if [ -d "$OHOS_DIR/.repo" ]; then
  PROJECT_COUNT=$(find "$OHOS_DIR/.repo/projects" -name '*.git' -type d 2>/dev/null | wc -l)
  if [ "$PROJECT_COUNT" -ge 400 ]; then pass "OHOS tree: $PROJECT_COUNT projects (synced)"
  else warn "OHOS tree: $PROJECT_COUNT projects (incomplete — sync may have failed)"; fi
else
  warn "OHOS tree not yet at $OHOS_DIR — run repo sync first"
fi

echo

# ---------- Summary ----------
echo "================================="
echo "PASS: $PASS  FAIL: $FAIL  WARN: $WARN"
if [ ${#FIXES[@]} -gt 0 ]; then
  echo
  echo "--- Suggested fixes (run with --fix to apply where safe) ---"
  for f in "${FIXES[@]}"; do echo "  $f"; done
fi
echo "================================="

if [ "$MODE" = "--fix" ]; then
  echo
  echo "=== APPLYING FIXES (--fix mode) ==="
  for f in "${FIXES[@]}"; do
    echo "+ $f"
    eval "$f" || echo "  ^ failed (may need manual intervention)"
  done
fi

if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
