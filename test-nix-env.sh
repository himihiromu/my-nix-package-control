#!/usr/bin/env bash

set -euo pipefail

cd /workspace

echo "======================================"
echo "Nix Environment Test Script"
echo "======================================"

echo
echo "1. Checking Nix version:"
nix --version

echo
echo "2. Checking if Flakes are enabled:"
if nix flake --help >/dev/null 2>&1; then
  echo "Flakes enabled ✓"
else
  echo "Flakes not enabled ✗"
  exit 1
fi

echo
echo "3. Evaluating flake outputs:"
nix flake show --all-systems 2>&1 || true

echo
echo "4. Flake metadata:"
nix flake metadata

echo
echo "======================================"
echo "Test completed successfully!"
echo "======================================"
