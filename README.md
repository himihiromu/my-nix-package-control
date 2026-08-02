個人用Nixパッケージ管理リポジトリ

NixOS + Home Manager + nix-darwin + chezmoi で Linux/macOS 環境を管理する。

## 対象構成

| 構成名 | 対象 | flake attribute |
|--------|------|----------------|
| nixos | Bare metal（単一ホスト） | `.#nixos` |
| nixos-wsl | WSL2 on Windows | `.#nixos-wsl` |
| mac-config | macOS（nix-darwin） | `.#mac-config` |
| myHomeConfig | Home Manager 単体 | `.#myHomeConfig` |

## NixOS (Bare Metal)

```shell
# ホスト構成の適用（初回 / 設定変更時）
$ sudo nixos-rebuild switch --flake .#nixos

# テスト（rebootせずに試す）
$ sudo nixos-rebuild test --flake .#nixos

# ビルドのみ（適用しない）
$ nixos-rebuild build --flake .#nixos
```

`hardware-configuration.nix` はインストーラーが生成するファイルで置き換える。
`isDesktop` は `user-options/options.nix` でホストごとに bool 値を切り替える。

## NixOS (WSL2)

```shell
# WSL内で適用
$ sudo nixos-rebuild switch --flake .#nixos-wsl
```

## nix-darwin (macOS)

```shell
$ sudo nix run nix-darwin -- switch --flake .#mac-config
```

## Home Manager（単体）

```shell
$ nix run nixpkgs#home-manager -- switch --flake .#myHomeConfig --show-trace
```

## nixの容量削減

```shell
$ nix-store --gc
```
