#!/usr/bin/env bash

set -euo pipefail

cd /workspace

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
echo "2. Available home configurations:"
nix eval --json ".#packages.${SYSTEM}.homeConfigurations" 2>/dev/null | jq -r 'keys[]' 2>/dev/null || echo "No home configurations found"

echo
echo "3. Checking Home Manager target evaluation:"
nix eval "${TARGET_PREFIX}.activationPackage.drvPath" >/dev/null
echo "Home Manager target evaluation ✓"

echo
echo "4. Testing Home Manager build:"
nix build "${TARGET_PREFIX}.activationPackage" --no-link 2>&1 | head -20

echo
echo "======================================"
echo "Test complete!"
echo "======================================"
