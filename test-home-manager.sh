#!/usr/bin/env bash

set -euo pipefail

cd /workspace

echo "======================================"
echo "Home Manager Configuration Test"
echo "======================================"

ARCH="$(nix eval --impure --raw --expr builtins.currentSystem)"

echo
echo "1. Current system: ${ARCH}"

echo
echo "2. Available home configurations:"
nix flake show --json 2>/dev/null | jq -r '.homeConfigurations | keys[]' 2>/dev/null || echo "No home configurations found"

echo
echo "3. Checking flake evaluation:"
nix flake check --no-build 2>&1 | head -20 || true

echo
echo "4. Testing Home Manager build:"
TARGET_ATTR="."
if nix flake show --json 2>/dev/null | jq -e '.homeConfigurations.myHomeConfig' >/dev/null 2>&1; then
  TARGET_ATTR='.#homeConfigurations.myHomeConfig.activationPackage'
fi

echo "Building configuration target: ${TARGET_ATTR}"
nix build "${TARGET_ATTR}" --no-link 2>&1 | head -20

echo
echo "======================================"
echo "Test complete!"
echo "======================================"
