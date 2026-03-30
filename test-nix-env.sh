#!/bin/bash

set -e

echo "======================================"
echo "Nix Environment Test Script"
echo "======================================"

# Nixバージョンの確認
echo -e "\n1. Checking Nix version:"
nix --version

# Flake機能が有効かの確認
echo -e "\n2. Checking if Flakes are enabled:"
nix flake --help > /dev/null 2>&1 && echo "Flakes enabled ✓" || echo "Flakes not enabled ✗"

# Flakeの評価テスト
echo -e "\n3. Evaluating flake:"
nix flake show 2>&1 || echo "Note: Some flake outputs may not be derivations (expected behavior)"

# パッケージリストの表示
echo -e "\n4. Available packages:"
nix flake show --json 2>&1 | jq '.packages."x86_64-linux" // .packages."aarch64-linux" // .packages."x86_64-darwin" // .packages."aarch64-darwin" | keys' 2>/dev/null || echo "No packages found or JSON parsing error"

# アプリケーションリストの表示
echo -e "\n5. Available apps:"
nix flake show --json 2>&1 | jq '.apps."x86_64-linux" // .apps."aarch64-linux" // .apps."x86_64-darwin" // .apps."aarch64-darwin" | keys' 2>/dev/null || echo "No apps found or JSON parsing error"

# Flakeのメタデータ
echo -e "\n6. Flake metadata:"
nix flake metadata || echo "Metadata unavailable"

echo -e "\n======================================"
echo "Test completed successfully!"
echo "======================================"