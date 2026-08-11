#!/usr/bin/env bash

set -euo pipefail

cd /workspace

git config --global --add safe.directory /workspace 2>/dev/null || true
rm -rf /homeless-shelter 2>/dev/null || true

export USER="${USER:-tester}"
export HOME="/tmp/home-manager-test-home"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
mkdir -p "$HOME"

NIX_FLAGS=(
  --extra-experimental-features nix-command
  --extra-experimental-features flakes
  --option build-users-group ''
)
SYSTEM="$(nix "${NIX_FLAGS[@]}" eval --impure --raw --expr builtins.currentSystem)"
FLAKE_ROOT="path:/workspace"
TARGET="${FLAKE_ROOT}#packages.${SYSTEM}.homeConfigurations.myHomeConfig.activationPackage"

echo "======================================"
echo "Home Manager Configuration Test"
echo "======================================"

echo
echo "1. Current system:"
echo "${SYSTEM}"

echo
echo "2. Checking Home Manager command availability:"
nix "${NIX_FLAGS[@]}" run nixpkgs#home-manager -- --version >/dev/null
echo "home-manager command available ✓"

echo
echo "3. Checking Home Manager target evaluation: ${TARGET}"
nix "${NIX_FLAGS[@]}" build --dry-run "${TARGET}" >/dev/null
echo "Home Manager target evaluation ✓"

echo
echo "======================================"
echo "Test complete!"
echo "======================================"
