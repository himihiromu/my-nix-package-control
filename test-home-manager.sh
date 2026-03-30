#!/bin/bash

set -e

echo "======================================"
echo "Home Manager Configuration Test"
echo "======================================"

# Gitの設定（必要な場合）
git config --global --add safe.directory /workspace 2>/dev/null || true

# 利用可能なアプリを表示
echo -e "\n1. Available apps:"
nix flake show --json 2>/dev/null | jq -r '.apps."x86_64-linux" // .apps."aarch64-linux" | keys[]' 2>/dev/null || echo "No apps found"

# HomeConfigurationsを表示
echo -e "\n2. Home configurations:"
nix flake show --json 2>/dev/null | jq -r '.homeConfigurations | keys[]' 2>/dev/null || echo "No home configurations found"

# flake.nixの評価テスト
echo -e "\n3. Checking flake evaluation:"
nix flake check --no-build 2>&1 | head -20 || echo "Flake check encountered issues (this may be normal)"

# Home Manager設定のビルドテスト
echo -e "\n4. Testing Home Manager build:"
echo "Building configuration for user: himihiromu"
nix build .#homeConfigurations.himihiromu.activationPackage --no-link 2>&1 | head -20 || echo "Build test failed (may need additional setup)"

echo -e "\n======================================"
echo "Test complete!"
echo "======================================"
echo ""
echo "To apply the Home Manager configuration, run:"
echo "  nix run .#home-switch"
echo ""
echo "To build without applying:"
echo "  nix run .#home-build"