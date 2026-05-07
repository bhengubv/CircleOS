#!/usr/bin/env bash
# Install the `repo` tool on geektrading2.
set -uo pipefail

mkdir -p ~/.local/bin
echo "=== download ==="
curl -sSL -o ~/.local/bin/repo https://storage.googleapis.com/git-repo-downloads/repo
chmod +x ~/.local/bin/repo
ls -la ~/.local/bin/repo
file ~/.local/bin/repo

echo "=== verify ==="
~/.local/bin/repo --version 2>&1 | head -5 || echo "(--version requires a synced tree)"

echo "=== PATH check ==="
grep "local/bin" ~/.bashrc 2>/dev/null || {
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
  echo "added to .bashrc"
}

# Configure git identity (needed by repo)
git config --global user.email "geektrading@circleos.local" 2>/dev/null
git config --global user.name "geektrading" 2>/dev/null
git config --global color.ui false 2>/dev/null

echo "=== git config ==="
git config --global --list | grep -E "user|color" | head -5

echo "=== DONE ==="
