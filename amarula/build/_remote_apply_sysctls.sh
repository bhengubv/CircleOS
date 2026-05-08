#!/usr/bin/env bash
# Apply build-host sysctls with sudo. Reads SUDO_PWD from stdin.
set -uo pipefail

SUDO_PWD=$(cat)

echo "=== applying sysctls ==="
echo "$SUDO_PWD" | sudo -S -p "" tee /etc/sysctl.d/99-build.conf > /dev/null <<'EOF'
# CircleOS Amarula build tuning — see amarula/build/preflight.sh for context
vm.swappiness = 10
vm.overcommit_memory = 1
vm.dirty_background_ratio = 5
vm.dirty_ratio = 15
vm.max_map_count = 1048576
EOF

echo "$SUDO_PWD" | sudo -S -p "" sysctl -p /etc/sysctl.d/99-build.conf 2>&1 | tail -10

echo
echo "=== verify ==="
sysctl vm.swappiness vm.overcommit_memory vm.max_map_count
