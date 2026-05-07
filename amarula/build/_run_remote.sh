#!/usr/bin/env bash
# Local helper: ship setup script to geektrading2 + run it with sudo password.
# Reads password from /tmp/.gtpwd (created on the fly, deleted at end).
set -uo pipefail

REMOTE_USER=geektrading
REMOTE_HOST=197.97.200.200
REMOTE_PWD_FILE=/tmp/.gtpwd
LOCAL_SETUP=/mnt/c/Dev/Solutions/com.bhengubv/CircleOS/amarula/build/_remote_setup.sh
REMOTE_SETUP=/tmp/setup.sh

# Password is in env var GTPWD
echo -n "$GTPWD" > "$REMOTE_PWD_FILE"
chmod 600 "$REMOTE_PWD_FILE"

# Ship script
sshpass -f "$REMOTE_PWD_FILE" scp -o StrictHostKeyChecking=no \
  "$LOCAL_SETUP" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_SETUP"

# Run remotely, passing the password as SUDO_PWD env var
sshpass -f "$REMOTE_PWD_FILE" ssh -o StrictHostKeyChecking=no \
  "$REMOTE_USER@$REMOTE_HOST" \
  "SUDO_PWD=\$(cat /dev/stdin) bash $REMOTE_SETUP" < "$REMOTE_PWD_FILE"

# Clean up
rm -f "$REMOTE_PWD_FILE"
