#!/usr/bin/env bash

set -euo pipefail

cd /workspace

git config --global --add safe.directory /workspace 2>/dev/null || true

echo "======================================"
echo "Home Manager Configuration Test"
echo "======================================"

echo
echo "1. Current system:"
nix eval --impure --raw --expr builtins.currentSystem

echo
echo "2. Available home configurations:"
nix flake show --json 2>/dev/null | jq -r '.packages.homeConfigurations | keys[]' 2>/dev/null || echo "No home configurations found"

echo
echo "3. Checking flake evaluation:"
nix flake check --no-build 2>&1 | head -20 || true

echo
echo "4. Testing Home Manager build:"
nix build .#packages.$(nix eval --impure --raw --expr builtins.currentSystem).homeConfigurations.myHomeConfig.activationPackage --no-link 2>&1 | head -20

echo
echo "======================================"
echo "Test complete!"
echo "======================================"
