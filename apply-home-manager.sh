#!/usr/bin/env bash

set -euo pipefail

cd /workspace

export USER="${USER:-tester}"
export HOME="/tmp/home-manager-test-home"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
export GIT_CONFIG_COUNT=1
export GIT_CONFIG_KEY_0=safe.directory
export GIT_CONFIG_VALUE_0=/workspace
mkdir -p "$HOME"

SYSTEM="$(nix eval --impure --raw --expr builtins.currentSystem)"
TARGET=".#packages.${SYSTEM}.homeConfigurations.myHomeConfig.activationPackage"

echo "======================================"
echo "Home Manager Application Script"
echo "======================================"

echo
echo "1. Building Home Manager configuration..."
nix build --option build-users-group '' "${TARGET}"

echo
echo "2. Activating Home Manager configuration..."
./result/activate

echo
echo "======================================"
echo "Home Manager setup complete!"
echo "======================================"
