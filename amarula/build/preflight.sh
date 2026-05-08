#!/usr/bin/env bash
# CircleOS Amarula build preflight.
# Validates everything we learned the hard way over 70+ hours of failed attempts.
#
# Usage:
#   bash preflight.sh         — read-only checks, exit 1 on first FAIL
#   bash preflight.sh --fix   — apply auto-fixes where safe (sudo prompts as needed)
#
# Exit codes:
#   0   all checks passed
#   1   at least one FAIL (build will not succeed)
#   2   preflight script bug
#
# Lessons encoded here (newest first):
#   ulimit -n 1024  → "Cannot initialize work tree" on 100+ repos (fix: 65536)
#   duplicate repo sync processes → corrupted checkout state
#   ~/.askpass.sh missing → sudo over SSH fails silently
#   ccache 4.9.x prints "50.0 GB" not "50G" — regex must handle decimals + spaces
#   repo only in ~/.local/bin → invisible to nohup / non-interactive shells
#   gitee/gitcode unreachable from SA → FAIL if no insteadOf redirect configured
#   vm.max_map_count 65530 → ThinLTO linker deadlock (llvm #48833)

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

# Probe gitee/gitcode — many networks (especially outside China) block these
# FAIL if unreachable AND no insteadOf redirect — repo sync will fail on 100+ projects
GITEE_OK=$(curl -sI -o /dev/null -w "%{http_code}" --connect-timeout 5 https://gitee.com 2>/dev/null || echo 000)
if [ "$GITEE_OK" = "200" ] || [ "$GITEE_OK" = "301" ] || [ "$GITEE_OK" = "302" ]; then
  pass "gitee.com reachable (manifest works as-is)"
else
  GITEE_REDIRECT=$(git config --global --get-all url."https://github.com/openharmony/".insteadOf 2>/dev/null | grep -cE "gitee|gitcode" || echo 0)
  if [ "$GITEE_REDIRECT" -ge 2 ]; then
    pass "gitee/gitcode unreachable — insteadOf → github redirects configured (both)"
  elif [ "$GITEE_REDIRECT" -eq 1 ]; then
    warn "gitee/gitcode unreachable — only 1 of 2 insteadOf redirects configured"
    fix "git config --global --add url.\"https://github.com/openharmony/\".insteadOf \"https://gitcode.com/openharmony/\""
  else
    fail "gitee/gitcode unreachable AND no insteadOf redirects — repo sync will fail on 100+ projects"
    fix "git config --global url.\"https://github.com/openharmony/\".insteadOf \"https://gitee.com/openharmony/\""
    fix "git config --global --add url.\"https://github.com/openharmony/\".insteadOf \"https://gitcode.com/openharmony/\""
  fi
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

# ulimit -n — CRITICAL: default 1024 causes "Cannot initialize work tree" on 100+ repos
# repo sync opens a file descriptor per project; with 449 projects it needs >1024
NOFILE=$(ulimit -n 2>/dev/null || echo 0)
if [ "$NOFILE" -ge 65536 ]; then
  pass "ulimit -n (open files): $NOFILE"
else
  fail "ulimit -n (open files): $NOFILE (need ≥ 65536 — default 1024 breaks repo checkout)"
  fix "ulimit -n 65536  # apply now (this shell only)"
  fix "echo -e '$(whoami) soft nofile 65536\n$(whoami) hard nofile 65536' | sudo tee -a /etc/security/limits.conf  # persist across sessions"
fi

# Verify limits.conf has persistent nofile setting
WHOAMI=$(whoami)
if grep -q "${WHOAMI}.*nofile" /etc/security/limits.conf 2>/dev/null; then
  pass "limits.conf: persistent nofile entry for $WHOAMI"
else
  warn "limits.conf: no persistent nofile entry — ulimit resets on reconnect"
  fix "echo -e '$WHOAMI soft nofile 65536\n$WHOAMI hard nofile 65536' | sudo tee -a /etc/security/limits.conf"
fi

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

# repo tool — must be in a PATH that works for ALL shells (interactive, nohup, cron)
# ~/.local/bin is NOT in PATH for non-interactive shells unless symlinked to /usr/local/bin
if [ -x /usr/local/bin/repo ]; then
  pass "repo: $(repo --version 2>/dev/null | head -1 || echo installed) [/usr/local/bin — universal PATH]"
elif command -v repo >/dev/null 2>&1; then
  warn "repo in PATH but not at /usr/local/bin — nohup/cron builds will fail"
  fix "sudo ln -sf \$(which repo) /usr/local/bin/repo"
elif [ -x "$HOME/.local/bin/repo" ]; then
  fail "repo at ~/.local/bin/repo but not in universal PATH — nohup sync will fail"
  fix "sudo ln -sf \$HOME/.local/bin/repo /usr/local/bin/repo"
else
  fail "repo: not installed"
  fix "mkdir -p ~/.local/bin && curl -sSL https://storage.googleapis.com/git-repo-downloads/repo > ~/.local/bin/repo && chmod +x ~/.local/bin/repo && sudo ln -sf \$HOME/.local/bin/repo /usr/local/bin/repo"
fi

echo

# ---------- 5. Build configuration ----------
echo "--- 5. Build configuration ---"

# ccache 4.9.x prints "50.0 GB" via --show-config; older versions print "50.0G" via --get-config
# Use --show-config as canonical source and handle both formats
CCACHE_MAX=$(ccache --show-config 2>/dev/null | grep -E "^\s*max_size\s*=" | grep -oE "[0-9]+(\.[0-9]+)?\s*[GMT]i?B?" | head -1)
if [ -z "$CCACHE_MAX" ]; then
  CCACHE_MAX=$(ccache --get-config max_size 2>/dev/null | head -1 || echo "")
fi
if [ -n "$CCACHE_MAX" ]; then
  CCACHE_GB=$(echo "$CCACHE_MAX" | grep -oE "^[0-9]+" | head -1)
  if [ "${CCACHE_GB:-0}" -ge 30 ]; then pass "ccache max_size: $CCACHE_MAX"
  else warn "ccache max_size: $CCACHE_MAX (50G recommended for OH build)"; fi
else
  warn "ccache max_size not detectable (default may be 5G)"
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

# git lowSpeedLimit/lowSpeedTime — prevents premature timeout on slow fetches
LOWSPEED=$(git config --global http.lowSpeedLimit 2>/dev/null || echo 0)
if [ "$LOWSPEED" -ge 1000 ]; then pass "git http.lowSpeedLimit: $LOWSPEED"
else
  warn "git http.lowSpeedLimit not set (repo sync may time out on slow connections)"
  fix "git config --global http.lowSpeedLimit 1000 && git config --global http.lowSpeedTime 600"
fi

# sudo askpass helper — required for non-interactive sudo over SSH
# Without this, sudo prompts for a terminal and silently fails in scripts
if [ -x "$HOME/.askpass.sh" ]; then
  pass "~/.askpass.sh: exists and executable"
else
  fail "~/.askpass.sh: missing — sudo in build scripts will fail over SSH"
  fix "printf '#!/bin/bash\necho YOUR_SUDO_PASSWORD_HERE\n' > ~/.askpass.sh && chmod 700 ~/.askpass.sh"
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

  # Check for duplicate/stale repo sync processes — multiple syncs corrupt checkout state
  SYNC_PROCS=$(pgrep -fc "repo/main.py" 2>/dev/null || ps aux | grep "repo/main.py" | grep -vc grep || echo 0)
  if [ "$SYNC_PROCS" -gt 1 ]; then
    fail "repo sync: $SYNC_PROCS processes running simultaneously — kill all before building"
    fix "pkill -f 'repo/main.py'"
  elif [ "$SYNC_PROCS" -eq 1 ]; then
    warn "repo sync: 1 process still running — wait for it to finish before building"
  else
    pass "repo sync: no stale processes"
  fi

  # Work tree health — detect repos where dir exists but .git link is missing
  # This happens when ulimit -n is too low during checkout (fix: raise to 65536)
  MISSING_GIT=$(find "$OHOS_DIR" -maxdepth 3 -name ".git" -prune -o \
    -mindepth 2 -maxdepth 3 -type d -print 2>/dev/null | \
    while read d; do [ ! -e "$d/.git" ] && echo "$d"; done | wc -l 2>/dev/null || echo 0)
  if [ "${MISSING_GIT:-0}" -gt 50 ]; then
    fail "Work tree: ~$MISSING_GIT dirs missing .git link (ulimit -n was too low during checkout — re-sync with ulimit 65536)"
    fix "ulimit -n 65536 && cd $OHOS_DIR && /usr/local/bin/repo sync -c -j4 --no-clone-bundle --retry-fetches=5 --force-sync"
  elif [ "${MISSING_GIT:-0}" -gt 0 ]; then
    warn "Work tree: ~$MISSING_GIT dirs may be missing .git links — consider re-sync"
  else
    pass "Work tree: .git links present in sampled dirs"
  fi
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
