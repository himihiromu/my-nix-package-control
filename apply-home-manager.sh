#!/usr/bin/env bash

set -euo pipefail

cd /workspace

export USER="${USER:-tester}"
export HOME="/tmp/home-manager-test-home"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
export GIT_CONFIG_COUNT=1
export GIT_CONFIG_KEY_0=safe.directory
export GIT_CONFIG_VALUE_0=/workspace
rm -rf /homeless-shelter 2>/dev/null || true
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
echo "Home Manager Application Script"
echo "======================================"

echo
echo "1. Building Home Manager configuration..."
nix "${NIX_FLAGS[@]}" build "${TARGET}"

echo
echo "2. Activating Home Manager configuration..."
./result/activate

echo
echo "======================================"
echo "Home Manager setup complete!"
echo "======================================"
