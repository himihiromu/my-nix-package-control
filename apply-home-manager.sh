#!/usr/bin/env bash

set -euo pipefail

cd /workspace

echo "======================================"
echo "Home Manager Application Script"
echo "======================================"

TARGET_ATTR='.#homeConfigurations.myHomeConfig.activationPackage'

echo
echo "1. Building Home Manager configuration..."
nix build "${TARGET_ATTR}"

echo
echo "2. Activating Home Manager configuration..."
./result/activate

echo
echo "======================================"
echo "Home Manager setup complete!"
echo "======================================"
