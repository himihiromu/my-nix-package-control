#!/usr/bin/env bash

set -euo pipefail

cd /workspace

git config --global --add safe.directory /workspace 2>/dev/null || true

echo "======================================"
echo "Nix Environment Test Script"
echo "======================================"

echo
printf '1. Current system: '
nix eval --impure --raw --expr builtins.currentSystem

echo
echo "2. Checking Nix version:"
nix --version

echo
echo "3. Checking if Flakes are enabled:"
if nix flake --help >/dev/null 2>&1; then
  echo "Flakes enabled ✓"
else
  echo "Flakes not enabled ✗"
  exit 1
fi

echo
echo "4. Evaluating flake outputs:"
nix flake show --all-systems 2>&1 || true

echo
echo "5. Flake metadata:"
nix flake metadata

echo
echo "======================================"
echo "Test completed successfully!"
echo "======================================"
