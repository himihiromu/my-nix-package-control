#!/usr/bin/env bash

set -euo pipefail

cd /workspace

SYSTEM="$(nix eval --impure --raw --expr builtins.currentSystem)"
TARGET=".#packages.${SYSTEM}.homeConfigurations.myHomeConfig.activationPackage"

echo "======================================"
echo "Home Manager Application Script"
echo "======================================"

echo
echo "1. Building Home Manager configuration..."
nix build "${TARGET}"

echo
echo "2. Activating Home Manager configuration..."
./result/activate

echo
echo "======================================"
echo "Home Manager setup complete!"
echo "======================================"
