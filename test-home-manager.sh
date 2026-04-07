#!/usr/bin/env bash

set -euo pipefail

cd /workspace

git config --global --add safe.directory /workspace 2>/dev/null || true

export USER="${USER:-tester}"
export HOME="/tmp/home-manager-test-home"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
mkdir -p "$HOME"

SYSTEM="$(nix eval --impure --raw --expr builtins.currentSystem)"
TARGET_FLAKE='.#myHomeConfig'

echo "======================================"
echo "Home Manager Configuration Test"
echo "======================================"

echo
echo "1. Current system:"
echo "${SYSTEM}"

echo
echo "2. Checking Home Manager command availability:"
nix run --option build-users-group '' nixpkgs#home-manager -- --version >/dev/null
echo "home-manager command available ✓"

echo
echo "3. Checking Home Manager target evaluation:"
nix run --option build-users-group '' nixpkgs#home-manager -- build \
  --extra-experimental-features nix-command \
  --extra-experimental-features flakes \
  --flake "${TARGET_FLAKE}" \
  --dry-run >/dev/null
echo "Home Manager target evaluation ✓"

echo
echo "4. Testing Home Manager build:"
nix run --option build-users-group '' nixpkgs#home-manager -- build \
  --extra-experimental-features nix-command \
  --extra-experimental-features flakes \
  --flake "${TARGET_FLAKE}"

echo
echo "======================================"
echo "Test complete!"
echo "======================================"
