#!/usr/bin/env bash

set -euo pipefail

cd /workspace

git config --global --add safe.directory /workspace 2>/dev/null || true

export USER="${USER:-tester}"
export HOME="/tmp/home-manager-test-home"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
mkdir -p "$HOME"

git config --global --add safe.directory /workspace 2>/dev/null || true

SYSTEM="$(nix eval --impure --raw --expr builtins.currentSystem)"
TARGET_PREFIX=".#packages.${SYSTEM}.homeConfigurations.myHomeConfig"

echo "======================================"
echo "Home Manager Configuration Test"
echo "======================================"

echo
echo "1. Current system:"
echo "${SYSTEM}"

echo
echo "2. Checking Home Manager target exists:"
if nix eval --option build-users-group '' "${TARGET_PREFIX}.activationPackage.drvPath" >/dev/null; then
  echo "myHomeConfig target found ✓"
else
  echo "myHomeConfig target not found ✗"
  exit 1
fi

echo
echo "3. Checking Home Manager target evaluation:"
nix eval --option build-users-group '' "${TARGET_PREFIX}.activationPackage.drvPath" >/dev/null
echo "Home Manager target evaluation ✓"

echo
echo "4. Testing Home Manager build:"
nix build --option build-users-group '' "${TARGET_PREFIX}.activationPackage" --no-link

echo
echo "======================================"
echo "Test complete!"
echo "======================================"
