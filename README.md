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
# Machine selection

Bare-metal NixOS configurations are selected by the flake fragment:

| Configuration | Hardware | Boot layout |
| --- | --- | --- |
| `nixos` | Original AMD desktop | ESP at `/efi`, XBOOTLDR at `/boot` |
| `macbook-air` | Intel MacBookAir7,2 | ESP at `/boot`, no XBOOTLDR |

Shared system and Home Manager settings are in `nixos/configuration.nix`.
Host-specific imports, disk UUIDs, boot settings, and `system.stateVersion`
are selected by `nixos/hosts/<name>/default.nix`. The MacBook configuration
preserves the installed machine's Btrfs `@root`, `@home`, and `@nix` subvolumes,
JIS keyboard, hardware settings, and limited build concurrency.

On this MacBook, the Kana/Eisu keys arrive as XKB keycodes 130/131
(`Hangul`/`Hangul_Hanja` in Fcitx). The host module binds those codes to
explicit IME activation/deactivation, so pressing Kana repeatedly keeps
Japanese input enabled. Fcitx's default Hangul toggle and Hangul_Hanja
activation are overridden to match these keys. Ghostty uses native Wayland
input; its package wrapper clears `GTK_IM_MODULE` for terminal, desktop,
and D-Bus launches. Apply the host configuration to persist the key bindings;
temporary `hyprctl keyword bind` commands do not survive a session restart.

Evaluate before applying (from this repository):

```sh
nix eval "path:$PWD#nixosConfigurations.macbook-air.config.system.build.toplevel.drvPath" \
  --override-input local-options "path:$HOME/.config/nix/local-input/default.nix" --raw
```

Apply only on the matching machine:

```sh
sudo nixos-rebuild switch --flake "path:$PWD#macbook-air" \
  --override-input local-options "path:$HOME/.config/nix/local-input/default.nix"
```

To add another PC, add its hardware module and boot configuration under
`nixos/hosts/`, then register it with `mkNixos` in `flake.nix`. Do not reuse
another machine's disk UUIDs or change an existing host's `system.stateVersion`.
