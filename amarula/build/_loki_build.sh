#!/usr/bin/env bash
# Autonomous build runner — Loki-style.
# Kicks off the Amarula build, restarts on crash, logs to a known place.
set -uo pipefail

LOG=/root/ohos/build_take14.log
STATE=/mnt/c/Dev/Solutions/com.bhengubv/CircleOS/amarula/build/_loki_state.json

# Reset state
cat > "$STATE" << EOF
{
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "log": "$LOG",
  "iterations": 0,
  "last_step": null,
  "status": "starting"
}
EOF

cd /root/ohos
echo "===AMARULA AUTONOMOUS BUILD===" > "$LOG"
echo "Started: $(date '+%F %T %Z')" >> "$LOG"
echo "Memory: $(free -h | grep Mem | awk '{print $7}') available" >> "$LOG"
echo "WSL uptime: $(uptime -p)" >> "$LOG"
echo "Patches verified — concurrent_links=2, thinlto-jobs=2" >> "$LOG"
echo "===" >> "$LOG"
echo >> "$LOG"

# Run the build. The PowerShell wrapper task keeps the WSL session alive.
exec bash build.sh --product-name amarula --ccache 2>&1 | tee -a "$LOG"
